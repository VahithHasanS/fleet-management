import { Injectable, Logger, OnApplicationBootstrap, OnApplicationShutdown } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Vehicle, VehicleDoc } from '../database/schemas';
import { TelemetryService } from '../telemetry/telemetry.service';
import { RouteWaypoint, COIMBATORE_ROUTES } from './routes';
import { TELEMETRY_SCHEMA_VERSION } from '../common/constants';

type SimEventType = 'harsh_brake' | 'harsh_accel' | 'harsh_corner' | 'sos' | 'wellness_alert';

interface SimVehicle {
  vehicleId: string;
  vehicleClass: string;
  routeId: number;
  leg: number;
  progress: number;
  lat: number;
  lon: number;
  heading: number;
  speedKmh: number;
  acc: number;
  la: number;
  seq: number;
  nextSendAt: number;
  sendEveryMs: number;
  tripId: string | undefined;
  nextHarshAt: number;
  idlingUntil: number;
  lastSpeed: number;
  prevHeading: number;
  headingDelta: number;
  idleSec: number;
}

const NUM_SIM_VEHICLES = 50;

@Injectable()
export class SimulatorService implements OnApplicationBootstrap, OnApplicationShutdown {
  private readonly logger = new Logger(SimulatorService.name);
  private vehicles: SimVehicle[] = [];
  private running = false;
  private timer?: NodeJS.Timeout;

  constructor(
    private readonly telemetry: TelemetryService,
    private readonly config: ConfigService,
    @InjectModel(Vehicle.name) private readonly vehiclesModel: Model<VehicleDoc>,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    const autoStart = this.config.get<boolean>('SIMULATOR_AUTOSTART', false);
    if (!autoStart) return;
    // Seed runs in its own bootstrap hook; give it a beat to create vehicles.
    setTimeout(() => void this.start(), 2500);
  }

  onApplicationShutdown(): void {
    this.running = false;
    if (this.timer) clearTimeout(this.timer);
  }

  status() {
    return {
      running: this.running,
      vehicles: this.vehicles.length,
      tickMs: this.config.get<number>('SIMULATOR_TICK_MS', 2000),
      startedAt: this.running ? this.vehicles[0]?.nextSendAt : undefined,
    };
  }

  async start(): Promise<void> {
    if (this.running) return;
    const docs = await this.vehiclesModel.find({ status: { $ne: 'deleted' } }).sort({ name: 1 }).limit(500).select('_id name vehicleClass driverId').exec();
    if (docs.length === 0) {
      this.logger.warn('simulator: no vehicles found — run the seed first (AUTO_SEED=true)');
      return;
    }

    const tickMs = this.config.get<number>('SIMULATOR_TICK_MS', 2000);
    const session = Date.now();
    this.vehicles = docs
      .filter((_, i) => i < NUM_SIM_VEHICLES)
      .map((v, i) => {
        const routeId = i % COIMBATORE_ROUTES.length;
        const route = COIMBATORE_ROUTES[routeId];
        const start = route[0];
        return {
          vehicleId: String(v._id),
          vehicleClass: v.vehicleClass,
          routeId,
          leg: 0,
          progress: 0,
          lat: jitter(start.lat, 0.0008),
          lon: jitter(start.lon, 0.0008),
          heading: 0,
          speedKmh: 8,
          acc: 0,
          la: 0.02,
          seq: 1,
          nextSendAt: Date.now() + (i % 6) * tickMs * 0.3,
          sendEveryMs: tickMs,
          tripId: `sim:${String(v._id)}:${session}`,
          nextHarshAt: Date.now() + 20_000 + Math.random() * 60_000,
          idlingUntil: 0,
          lastSpeed: 8,
          prevHeading: 0,
          headingDelta: 0,
          idleSec: 0,
        };
      });

    this.running = true;
    this.timer = setInterval(() => void this.tick(), tickMs);
    this.logger.log(`simulator started: ${this.vehicles.length} vehicles, tick ${tickMs}ms`);
  }

  stop(): void {
    this.running = false;
    if (this.timer) clearTimeout(this.timer);
    this.timer = undefined;
    this.logger.log('simulator stopped');
  }

  async reset(): Promise<void> {
    this.stop();
    await this.vehiclesModel.updateMany({}, { $set: { status: 'offline', speedKmh: 0, lastSeen: new Date(0) } });
    this.start();
  }

  async triggerEvent(vehicleId: string, type: SimEventType): Promise<boolean> {
    const sv = this.vehicles.find((v) => v.vehicleId === vehicleId);
    if (!sv) return false;
    // Force the next tick of this vehicle to emit the event immediately.
    sv.nextSendAt = Date.now();
    this.pendingEvent.set(vehicleId, type);
    return true;
  }

  private pendingEvent = new Map<string, SimEventType>();

  private async tick(): Promise<void> {
    const now = Date.now();
    const candidates = this.vehicles.filter((v) => this.running && v.nextSendAt <= now);
    for (const sv of candidates) {
      await this.advance(sv, now);
      sv.nextSendAt += sv.sendEveryMs;
    }
  }

  private async advance(sv: SimVehicle, now: number): Promise<void> {
    const forced = this.pendingEvent.get(sv.vehicleId) ?? 'none';
    this.pendingEvent.delete(sv.vehicleId);

    this.move(sv, sv.sendEveryMs / 1000);

    // Simulate an occasional red-light / traffic stop.
    if (now < sv.idlingUntil) sv.speedKmh = 0;

    const dt = sv.sendEveryMs / 1000;
    let acc = (sv.speedKmh - sv.lastSpeed) / 3.6 / Math.max(dt, 0.1);
    acc = clamp(acc, -6, 6);
    sv.lastSpeed = sv.speedKmh;

    // Cornering lateral g: speed-appropriate with noise; raised on tight legs.
    const turnBias = Math.abs(sv.headingDelta);
    let la = Math.abs(turnBias) * 0.04 + noise(0.015, 0.10);
    sv.headingDelta = 0;

    let conf = 0.7 + Math.random() * 0.28;
    const point = {
      t: 0,
      lat: sv.lat,
      lon: sv.lon,
      spd: round1(sv.speedKmh),
      hdg: Math.round(sv.heading),
      acc: round3(acc),
      la: round3(la),
      yaw: Math.round(turnBias * 60),
      conf: round2(conf),
    };

    const events: Array<{ t: number; type: string; magnitude: number; conf: number; detail?: string }> = [];
    const doEvent = (type: SimEventType) => {
      const magnitude = type === 'harsh_brake' || type === 'harsh_accel'
        ? round3(0.5 + Math.random() * 0.25)
        : round3(0.4 + Math.random() * 0.2);
      const e: { t: number; type: string; magnitude: number; conf: number; detail?: string } = {
        t: 0,
        type,
        magnitude,
        conf: 0.9 + Math.random() * 0.09,
        ...(type === 'sos'
          ? { detail: 'simulated SOS — driver pressed panic' }
          : type === 'wellness_alert'
            ? { detail: 'simulated fatigue/stress signal' }
            : {}),
      };
      events.push(e);
      if (type === 'harsh_brake') point.acc = -magnitude;
      if (type === 'harsh_accel') point.acc = magnitude;
      if (type === 'harsh_corner') { point.la = magnitude; la = magnitude; }
      sv.nextHarshAt = now + 25_000 + Math.random() * 55_000;
    };

    if (forced !== 'none') {
      doEvent(forced);
    } else if (now >= sv.nextHarshAt && sv.speedKmh > 20) {
      const roll = Math.random();
      const t: SimEventType = roll < 0.42 ? 'harsh_brake' : roll < 0.78 ? 'harsh_accel' : 'harsh_corner';
      doEvent(t);
    }

    // Rare spontaneous device events for drama during a long demo.
    if (events.length === 0 && Math.random() < 0.0008) {
      doEvent(Math.random() < 0.5 ? 'sos' : 'wellness_alert');
    }

    const batch = {
      schemaVersion: TELEMETRY_SCHEMA_VERSION,
      vehicleId: sv.vehicleId,
      tripId: sv.tripId,
      deviceId: `sim-device-${sv.vehicleId}`,
      seq: sv.seq++,
      batchStart: new Date(now - sv.sendEveryMs).toISOString(),
      points: [point],
      ...(events.length ? { events } : {}),
    };

    await this.telemetry.handleBatch(batch as never);
  }

  private move(sv: SimVehicle, dtSec: number): void {
    const route = COIMBATORE_ROUTES[sv.routeId];
    if (!route) return;

    const wp = route[sv.leg];
    const next = route[(sv.leg + 1) % route.length];
    const segKm = haversineKm(wp.lat, wp.lon, next.lat, next.lon);

    // Cruise between 0 and wp.speedKmh with noise; drop to ~25% at tight corners.
    const cruise = wp.speedKmh * (0.55 + Math.random() * 0.45);
    sv.speedKmh = clamp(cruise, 0, next.speedKmh * 1.25);

    const dKm = (sv.speedKmh / 3600) * dtSec;
    const consumed = segKm > 0 ? dKm / segKm : 1;
    sv.progress += consumed;

    if (sv.progress >= 1) {
      sv.progress = 0;
      sv.leg = (sv.leg + 1) % route.length;
    }

    // Interpolate position along leg.
    const f = clamp(sv.progress, 0, 1);
    sv.lat = wp.lat + (next.lat - wp.lat) * f;
    sv.lon = wp.lon + (next.lon - wp.lon) * f;
    sv.heading = bearingDeg(wp.lat, wp.lon, next.lat, next.lon);
    sv.headingDelta = (sv.heading - sv.prevHeading + 540) % 360 - 180;
    sv.prevHeading = sv.heading;

    // Trip start/stop: > 5 km/h for 60s starts; < 5 km/h for 120s ends (mirrors
    // TripStateMachine). Model an idle ~ every 3-7 min.
    if (Math.random() < 0.004 && sv.speedKmh < 5) {
      sv.idlingUntil = Date.now() + 8_000 + Math.random() * 12_000;
    }
    if (sv.speedKmh > 5 && !sv.tripId) sv.tripId = `sim:${sv.vehicleId}:${Date.now()}`;
    if (sv.speedKmh <= 5 && sv.tripId) {
      this.idleSince.set(sv.vehicleId, (this.idleSince.get(sv.vehicleId) ?? 0) + dtSec);
      sv.idleSec += dtSec;
      if ((this.idleSince.get(sv.vehicleId) ?? 0) >= 120) {
        sv.tripId = undefined;
        this.idleSince.set(sv.vehicleId, 0);
        sv.idleSec = 0;
      }
    } else {
      this.idleSince.set(sv.vehicleId, 0);
      sv.idleSec = 0;
    }
  }

  private idleSince = new Map<string, number>();
}

function jitter(n: number, d: number): number {
  return n + (Math.random() - 0.5) * 2 * d;
}
function noise(d: number, r: number): number {
  return d + Math.abs(Math.random() * r);
}
function clamp(n: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, n));
}
function round1(n: number): number {
  return Math.round(n * 10) / 10;
}
function round2(n: number): number {
  return Math.round(n * 100) / 100;
}
function round3(n: number): number {
  return Math.round(n * 1000) / 1000;
}
function haversineKm(aLat: number, aLon: number, bLat: number, bLon: number): number {
  const R = 6371;
  const dLat = ((bLat - aLat) * Math.PI) / 180;
  const dLon = ((bLon - aLon) * Math.PI) / 180;
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((aLat * Math.PI) / 180) * Math.cos((bLat * Math.PI) / 180) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}
function bearingDeg(aLat: number, aLon: number, bLat: number, bLon: number): number {
  const dLon = ((bLon - aLon) * Math.PI) / 180;
  const y = Math.sin(dLon) * Math.cos((bLat * Math.PI) / 180);
  const x =
    Math.cos((aLat * Math.PI) / 180) * Math.sin((bLat * Math.PI) / 180) -
    Math.sin((aLat * Math.PI) / 180) * Math.cos((bLat * Math.PI) / 180) * Math.cos(dLon);
  return (Math.atan2(y, x) * 180) / Math.PI;
}