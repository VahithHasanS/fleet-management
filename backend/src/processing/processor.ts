import { Inject, Injectable, Logger, OnApplicationBootstrap, OnApplicationShutdown } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import Redis from 'ioredis';
import { REDIS } from '../database/database.module';
import { Alert, AlertDoc, Driver, DriverDoc, Geofence, GeofenceDoc, SafetyEvent, SafetyEventDoc, Trip, TripDoc } from '../database/schemas';
import { PubSub } from '../common/pubsub';
import { Batch, TelegramBatchRecord } from '../common/types';
import { TELEMETRY_GROUP, TELEMETRY_STREAM } from '../telemetry/telemetry.service';
import { VehicleResolver } from '../telemetry/vehicle-resolver';
import { LiveService } from '../telemetry/live.service';
import { classifyEvent, haversineKm, TripStateMachine, distanceOf, scoreTrip } from './trip-logic';
import { EVENT_SEVERITY } from '../common/constants';

interface Accumulator {
  vehicleId: string;
  tenantId: string;
  fleetId?: string;
  vehicleName: string;
  vehicleClass: string;
  thresholds?: { brakeG: number; accelG: number; cornerG: number; speedLimitKmh: number };
  driverId?: string;
  driverName?: string;
  machine: TripStateMachine;
  tripId?: string;
  tripStart?: Date;
  startLat?: number;
  startLon?: number;
  endLat?: number;
  endLon?: number;
  points: Array<{ lat: number; lon: number; t: number }>;
  events: Array<{ type: string; magnitude: number; lat?: number; lon?: number; at: Date }>;
  maxSpeed: number;
  lastPoint?: { lat: number; lon: number; at: Date };
}

const GEOFENCE_COOLDOWN_MS = 60_000;

@Injectable()
export class TripProcessor implements OnApplicationBootstrap, OnApplicationShutdown {
  private readonly logger = new Logger(TripProcessor.name);
  private accumulators = new Map<string, Accumulator>();
  private geofences = new Map<string, GeofenceDoc[]>();
  private breachCooldown = new Map<string, number>();
  private running = true;

  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    private readonly resolver: VehicleResolver,
    private readonly live: LiveService,
    private readonly pubsub: PubSub,
    @InjectModel(Trip.name) private readonly trips: Model<TripDoc>,
    @InjectModel(SafetyEvent.name) private readonly eventsModel: Model<SafetyEventDoc>,
    @InjectModel(Alert.name) private readonly alerts: Model<AlertDoc>,
    @InjectModel(Driver.name) private readonly drivers: Model<DriverDoc>,
    @InjectModel(Geofence.name) private readonly geofenceModel: Model<GeofenceDoc>,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    try {
      await this.redis.xgroup('CREATE', TELEMETRY_STREAM, TELEMETRY_GROUP, '0', 'MKSTREAM');
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      if (!msg.includes('BUSYGROUP')) this.logger.warn(`consumer group: ${msg}`);
    }
    void this.poll();
  }

  onApplicationShutdown(): void {
    this.running = false;
  }

  private chunked<T>(arr: T[], size: number): T[][] {
    const out: T[][] = [];
    for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
    return out;
  }

  async poll(): Promise<void> {
    while (this.running) {
      try {
        const resp = await (this.redis.xreadgroup as unknown as (
          ...args: unknown[]
        ) => Promise<unknown>)(
          'GROUP',
          TELEMETRY_GROUP,
          'processor-1',
          'COUNT',
          200,
          'BLOCK',
          2000,
          'STREAMS',
          TELEMETRY_STREAM,
          '>',
        );
        if (!resp) continue;
        const entriesList = resp as Array<[string, Array<[string, string[]]>]>;
        for (const [, entries] of entriesList) {
          for (const entry of entries) {
            const [id, fields] = entry;
            const record = this.parseEntry(id, fields);
            if (record) await this.process(record);
          }
        }
      } catch (err) {
        this.logger.warn(`poll error: ${err instanceof Error ? err.message : err}`);
        await new Promise((r) => setTimeout(r, 1000));
      }
    }
  }

  private parseEntry(id: string, fields: string[]): TelegramBatchRecord | undefined {
    if (fields.length % 2 !== 0) return undefined;
    const map: Record<string, string> = {};
    for (let i = 0; i < fields.length; i += 2) map[fields[i]] = fields[i + 1];
    try {
      return { id, batch: JSON.parse(map.batch ?? 'null') };
    } catch {
      return undefined;
    }
  }

  private async process(record: TelegramBatchRecord): Promise<void> {
    if (!record.batch || typeof record.batch !== 'object') {
      await this.redis.xack(TELEMETRY_STREAM, TELEMETRY_GROUP, record.id);
      return;
    }
    const { batch } = record;
    const vehicle = await this.resolver.resolve(batch.vehicleId);
    let acc = this.accumulators.get(batch.vehicleId);
    if (vehicle && !acc) {
      acc = {
        vehicleId: batch.vehicleId,
        tenantId: vehicle.tenantId,
        fleetId: vehicle.fleetId,
        vehicleName: vehicle.name,
        vehicleClass: vehicle.vehicleClass,
        thresholds: vehicle.thresholds,
        driverId: vehicle.driverId,
        driverName: vehicle.driverName,
        machine: new TripStateMachine(),
        points: [],
        events: [],
        maxSpeed: 0,
      };
      this.accumulators.set(acc.vehicleId, acc);
    }
    if (!acc) {
      await this.redis.xack(TELEMETRY_STREAM, TELEMETRY_GROUP, record.id);
      return;
    }

    const batchStartMs = new Date(batch.batchStart).getTime();
    for (const p of batch.points) {
      await this.handlePoint(acc, p, batchStartMs + p.t * 1000);
    }
    await this.handleDeviceEvents(acc, batch, batchStartMs);

    await this.redis.xack(TELEMETRY_STREAM, TELEMETRY_GROUP, record.id);
  }

  private async handlePoint(acc: Accumulator, p: TelegramBatchRecord['batch']['points'][number], atMs: number): Promise<void> {
    const nowSec = Date.now() / 1000;
    const transition = acc.machine.accept(nowSec, p.spd);

    if (transition === 'trip_started') {
      acc.tripId = acc.machine.tripId;
      acc.tripStart = new Date(atMs);
      acc.startLat = p.lat;
      acc.startLon = p.lon;
      acc.points = [];
      acc.events = [];
      acc.maxSpeed = p.spd;
      acc.endLat = undefined;
      acc.endLon = undefined;
    }

    if (!acc.tripId) return;

    acc.points.push({ lat: p.lat, lon: p.lon, t: atMs });
    acc.maxSpeed = Math.max(acc.maxSpeed, p.spd);
    acc.endLat = p.lat;
    acc.endLon = p.lon;

    const detection = classifyEvent(acc.vehicleClass, acc.thresholds, {
      spd: p.spd,
      acc: p.acc,
      la: p.la,
      conf: p.conf,
    });
    if (detection) {
      await this.onDetectedEvent(acc, detection.type, detection.magnitude, p, atMs);
    }

    await this.checkGeofences(acc, p.lat, p.lon, atMs);

    if (transition === 'trip_ended') {
      await this.finalizeTrip(acc, atMs);
    }
  }

  private async handleDeviceEvents(acc: Accumulator, batch: TelegramBatchRecord['batch'], batchStartMs: number): Promise<void> {
    for (const e of batch.events ?? []) {
      if (e.type === 'sos') {
        await this.onSos(acc, e, batchStartMs + e.t * 1000);
      } else if (e.type === 'wellness_alert') {
        await this.onWellness(acc, e, batchStartMs + e.t * 1000);
      }
    }
  }

  private async onDetectedEvent(acc: Accumulator, type: string, magnitude: number, p: TelegramBatchRecord['batch']['points'][number], atMs: number): Promise<void> {
    const at = new Date(atMs);
    acc.events.push({ type, magnitude, lat: p.lat, lon: p.lon, at });
    const severity = EVENT_SEVERITY[type as keyof typeof EVENT_SEVERITY] ?? 'low';

    await this.eventsModel.create({
      tenantId: acc.tenantId,
      vehicleId: acc.vehicleId,
      vehicleName: acc.vehicleName,
      driverId: acc.driverId,
      tripId: acc.tripId,
      type,
      severity,
      magnitude,
      confidence: p.conf,
      timestamp: at,
      lat: p.lat,
      lon: p.lon,
    });

    this.pubsub.emit('live.event', {
      tenantId: acc.tenantId,
      event: {
        type, severity, magnitude, vehicleId: acc.vehicleId, vehicleName: acc.vehicleName,
        driverName: acc.driverName, lat: p.lat, lon: p.lon, timestamp: at.toISOString(),
      },
    });

    if (severity === 'high' || severity === 'critical') {
      const message = `${acc.vehicleName} — ${type.replace(/_/g, ' ')} (${magnitude.toFixed(2)}g)`;
      await this.emitAlert(acc, { type, severity, message, lat: p.lat, lon: p.lon, at: atMs });
    }
  }

  private async onSos(acc: Accumulator, e: NonNullable<TelegramBatchRecord['batch']['events']>[number], atMs: number): Promise<void> {
    const at = new Date(atMs);
    const event = await this.eventsModel.create({
      tenantId: acc.tenantId, vehicleId: acc.vehicleId, vehicleName: acc.vehicleName,
      driverId: acc.driverId, tripId: acc.tripId, type: 'sos', severity: 'critical',
      magnitude: e.magnitude, confidence: e.conf, timestamp: at, lat: acc.endLat, lon: acc.endLon,
      detail: e.detail,
    });
    const panic = {
      panicId: String(event._id), vehicleId: acc.vehicleId, vehicleName: acc.vehicleName,
      driverName: acc.driverName, lat: acc.endLat, lon: acc.endLon, timestamp: at.toISOString(),
    };
    this.pubsub.emit('live.sos', { tenantId: acc.tenantId, panic });
    await this.emitAlert(acc, { type: 'sos', severity: 'critical', message: `SOS — ${acc.vehicleName} requesting help`, lat: acc.endLat, lon: acc.endLon, at: atMs });
  }

  private async onWellness(acc: Accumulator, e: NonNullable<TelegramBatchRecord['batch']['events']>[number], atMs: number): Promise<void> {
    const at = new Date(atMs);
    await this.eventsModel.create({
      tenantId: acc.tenantId, vehicleId: acc.vehicleId, vehicleName: acc.vehicleName,
      driverId: acc.driverId, tripId: acc.tripId, type: 'wellness_alert', severity: 'medium',
      magnitude: e.magnitude, confidence: e.conf, timestamp: at, lat: acc.endLat, lon: acc.endLon,
      detail: e.detail ?? 'simulated fatigue/stress signal',
    });
    this.pubsub.emit('live.event', {
      tenantId: acc.tenantId,
      event: {
        type: 'wellness_alert', severity: 'medium', magnitude: e.magnitude,
        vehicleId: acc.vehicleId, vehicleName: acc.vehicleName, driverName: acc.driverName,
        lat: acc.endLat, lon: acc.endLon, timestamp: at.toISOString(), simulated: true,
      },
    });
    await this.emitAlert(acc, {
      type: 'wellness_alert', severity: 'medium',
      message: `${acc.driverName ?? acc.driverId} fatigue/stress signal detected (simulated)`,
      lat: acc.endLat, lon: acc.endLon, at: atMs,
    });
  }

  private async checkGeofences(acc: Accumulator, lat: number, lon: number, atMs: number): Promise<void> {
    let fences = this.geofences.get(acc.tenantId);
    if (!fences) {
      fences = await this.geofenceModel.find({ tenantId: acc.tenantId }).exec();
      this.geofences.set(acc.tenantId, fences);
      setTimeout(() => this.geofences.delete(acc.tenantId), 30_000);
    }
    for (const f of fences) {
      const d = haversineKm(lat, lon, f.centerLat, f.centerLon);
      if (f.mode === 'entry-warning' && d * 1000 <= f.radiusM) {
        const key = `${acc.vehicleId}:${String(f._id)}`;
        const last = this.breachCooldown.get(key) ?? 0;
        if (atMs - last < GEOFENCE_COOLDOWN_MS) continue;
        this.breachCooldown.set(key, atMs);
        await this.eventsModel.create({
          tenantId: acc.tenantId, vehicleId: acc.vehicleId, vehicleName: acc.vehicleName,
          driverId: acc.driverId, tripId: acc.tripId, type: 'geofence_breach', severity: 'high',
          magnitude: Math.round(d * 1000), confidence: 0.95, timestamp: new Date(atMs), lat, lon,
        });
        this.pubsub.emit('live.event', {
          tenantId: acc.tenantId,
          event: {
            type: 'geofence_breach', severity: 'high', magnitude: Math.round(d * 1000),
            vehicleId: acc.vehicleId, vehicleName: acc.vehicleName, driverName: acc.driverName,
            lat, lon, timestamp: new Date(atMs).toISOString(), geofence: f.name,
          },
        });
        await this.emitAlert(acc, {
          type: 'geofence_breach', severity: 'high',
          message: `${acc.vehicleName} entered restricted zone "${f.name}"`,
          lat, lon, at: atMs,
        });
      }
    }
  }

  private async emitAlert(acc: Accumulator, input: { type: string; severity: string; message: string; lat?: number; lon?: number; at: number }): Promise<void> {
    const alertDoc = await this.alerts.create({
      tenantId: acc.tenantId, type: input.type, severity: input.severity,
      vehicleId: acc.vehicleId, vehicleName: acc.vehicleName, driverId: acc.driverId,
      driverName: acc.driverName, message: input.message, timestamp: new Date(input.at),
      payload: { lat: input.lat, lon: input.lon },
    });
    this.pubsub.emit('live.alert', {
      tenantId: acc.tenantId,
      alert: {
        alertId: String(alertDoc._id), type: input.type, severity: input.severity,
        message: input.message, vehicleId: acc.vehicleId, vehicleName: acc.vehicleName,
        driverName: acc.driverName, lat: input.lat, lon: input.lon, timestamp: new Date(input.at).toISOString(),
      },
    });
  }

  private async finalizeTrip(acc: Accumulator, atMs: number): Promise<void> {
    const tripId = acc.tripId;
    if (!tripId) return;
    const start = acc.tripStart ?? new Date(atMs);
    const end = new Date(atMs);
    const durationSec = Math.max(1, (end.getTime() - start.getTime()) / 1000);
    const distanceKm = distanceOf(acc.points);
    const smoothTrip = acc.events.length === 0;
    const scores = scoreTrip({ events: acc.events.map((e) => ({ type: e.type })), smoothTrip });

    const tripDoc = await this.trips.create({
      tenantId: acc.tenantId, fleetId: acc.fleetId, vehicleId: acc.vehicleId,
      vehicleName: acc.vehicleName, driverId: acc.driverId, driverName: acc.driverName,
      startTime: start, endTime: end, durationSec: Math.round(durationSec),
      distanceKm: Math.round(distanceKm * 100) / 100,
      avgSpeedKmh: Math.round((distanceKm / durationSec) * 3600),
      maxSpeedKmh: Math.round(acc.maxSpeed),
      startLat: acc.startLat, startLon: acc.startLon, endLat: acc.endLat, endLon: acc.endLon,
      subScores: scores.subScores, totalScore: scores.totalScore,
      positivePoints: scores.positivePoints, eventCount: acc.events.length, smoothTrip,
    });

    if (acc.driverId) {
      const driver = await this.drivers.findById(acc.driverId);
      if (driver) {
        const ema = Math.round(0.7 * (driver.safetyScore ?? 100) + 0.3 * scores.totalScore);
        await this.drivers.updateOne(
          { _id: driver._id as never },
          { $set: { safetyScore: ema }, $inc: { positivePoints: scores.positivePoints, tripsCount: 1 } },
        ).exec();
      }
    }

    const summary = {
      tripId: String(tripDoc._id), tenantId: acc.tenantId, vehicleId: acc.vehicleId,
      vehicleName: acc.vehicleName, driverId: acc.driverId, driverName: acc.driverName,
      startTime: start.toISOString(), endTime: end.toISOString(),
      durationSec: Math.round(durationSec), distanceKm, avgSpeedKmh: Math.round((distanceKm / durationSec) * 3600),
      maxSpeedKmh: Math.round(acc.maxSpeed), subScores: scores.subScores,
      totalScore: scores.totalScore, positivePoints: scores.positivePoints,
      events: acc.events.map((e) => ({ type: e.type, magnitude: e.magnitude, timestamp: e.at.toISOString(), severity: EVENT_SEVERITY[e.type as keyof typeof EVENT_SEVERITY] ?? 'low' })),
    };
    this.pubsub.emit('live.trip', { tenantId: acc.tenantId, trip: summary });

    await this.broadcastLeaderboard(acc.tenantId);
    acc.tripId = undefined;
    acc.points = [];
    acc.events = [];
    acc.maxSpeed = 0;
  }

  private async broadcastLeaderboard(tenantId: string): Promise<void> {
    const top = await this.drivers
      .find({ tenantId })
      .sort({ safetyScore: -1, positivePoints: -1 })
      .limit(20)
      .select('name safetyScore positivePoints tripsCount avatarColor')
      .exec();
    this.pubsub.emit('live.leaderboard', {
      tenantId,
      leaderboard: top.map((d) => ({
        driverId: String(d._id), name: d.name, scores: d.safetyScore,
        positivePoints: d.positivePoints, tripsCount: d.tripsCount, avatarColor: d.avatarColor,
      })),
    });
  }
}