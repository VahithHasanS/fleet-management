import { Inject, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import Redis from 'ioredis';
import { REDIS, TelemetrySeries } from '../database/database.module';
import { Vehicle, VehicleDoc } from '../database/schemas';
import { PubSub } from '../common/pubsub';
import { Batch } from '../common/types';
import { TELEMETRY_SCHEMA_VERSION } from '../common/constants';
import { LiveService } from './live.service';
import { VehicleResolver } from './vehicle-resolver';

export const TELEMETRY_STREAM = 'telemetry';
export const TELEMETRY_GROUP = 'trip-processor';

export interface IngestResult {
  status: 'ok' | 'duplicate' | 'rejected';
  vehicleId: string;
  points: number;
  events: number;
  reason?: string;
}

@Injectable()
export class TelemetryService {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    private readonly series: TelemetrySeries,
    private readonly live: LiveService,
    private readonly resolver: VehicleResolver,
    private readonly pubsub: PubSub,
    @InjectModel(Vehicle.name) private readonly vehicles: Model<VehicleDoc>,
  ) {}

  async handleBatch(batch: Batch, callerTenantId?: string, callerDriverId?: string): Promise<IngestResult> {
    const rejection = this.validate(batch);
    if (rejection) return rejection;

    const vehicle = await this.resolver.resolve(batch.vehicleId);
    if (!vehicle) {
      return { status: 'rejected', vehicleId: batch.vehicleId, points: 0, events: 0, reason: 'unknown_vehicle' };
    }
    if (callerTenantId && vehicle.tenantId !== callerTenantId) {
      return { status: 'rejected', vehicleId: batch.vehicleId, points: 0, events: 0, reason: 'tenant_mismatch' };
    }
    if (callerDriverId && vehicle.driverId !== callerDriverId) {
      return { status: 'rejected', vehicleId: batch.vehicleId, points: 0, events: 0, reason: 'vehicle_not_assigned' };
    }

    // Idempotency key: vehicleId + tripId + monotonic seq (blueprint §3.1).
    const dedupeKey = `dedupe:${batch.vehicleId}:${batch.tripId ?? 'x'}:${batch.seq}`;
    const first = await this.redis.set(dedupeKey, '1', 'EX', 300, 'NX');
    if (!first) {
      return { status: 'duplicate', vehicleId: batch.vehicleId, points: batch.points.length, events: batch.events?.length ?? 0 };
    }

    const batchStart = new Date(batch.batchStart);
    const nowMs = batchStart.getTime();
    const rows = batch.points.map((p) => ({
      ts: new Date(nowMs + p.t * 1000),
      meta: { vehicleId: batch.vehicleId, tenantId: vehicle.tenantId, tripId: batch.tripId },
      lat: p.lat,
      lon: p.lon,
      spd: p.spd,
      hdg: p.hdg,
      acc: p.acc,
      la: p.la,
      yaw: p.yaw,
      conf: p.conf,
    }));

    try {
      await this.series.insertPoints(rows);
    } catch (err) {
      return { status: 'rejected', vehicleId: batch.vehicleId, points: batch.points.length, events: batch.events?.length ?? 0, reason: 'write_failed' };
    }

    // Live snapshot for the admin map.
    const last = batch.points[batch.points.length - 1];
    this.live.upsert(vehicle, {
      point: { lat: last.lat, lon: last.lon, spd: last.spd, hdg: last.hdg },
      ts: nowMs + last.t * 1000,
    });

    // Vehicle collection: keep current position/status fresh (throttle-friendly at scale).
    await this.vehicles
      .updateOne(
        { _id: vehicle.vehicleId as never },
        {
          $set: {
            lat: last.lat,
            lon: last.lon,
            speedKmh: last.spd,
            heading: last.hdg,
            status: last.spd > 5 ? 'in_transit' : 'online',
            lastSeen: new Date(nowMs + last.t * 1000),
          },
        },
      )
      .exec();

    // Enqueue for downstream trip/event processing (Redis Streams / Kafka seam).
    await this.redis.xadd(
      TELEMETRY_STREAM,
      '*',
      'batch',
      JSON.stringify({ ...batch, seq: batch.seq, ingestedAt: new Date().toISOString() }),
      'tenantId',
      vehicle.tenantId,
    );

    // Push a single live position per batch to the admin room (1 msg per v/tick).
    this.pubsub.emit('live.position', {
      tenantId: vehicle.tenantId,
      snapshot: this.live.get(vehicle.vehicleId),
    });

    return {
      status: 'ok',
      vehicleId: batch.vehicleId,
      points: batch.points.length,
      events: batch.events?.length ?? 0,
    };
  }

  private validate(batch: Batch): IngestResult | null {
    if (!batch || typeof batch !== 'object') {
      return { status: 'rejected', vehicleId: '', points: 0, events: 0, reason: 'malformed' };
    }
    if (batch.schemaVersion !== TELEMETRY_SCHEMA_VERSION) {
      return { status: 'rejected', vehicleId: batch.vehicleId || '', points: 0, events: 0, reason: 'unsupported_schema' };
    }
    if (!batch.vehicleId || !Array.isArray(batch.points) || batch.points.length === 0 || !Number.isFinite(batch.seq)) {
      return { status: 'rejected', vehicleId: batch.vehicleId || '', points: 0, events: 0, reason: 'invalid_packet' };
    }
    return null;
  }
}