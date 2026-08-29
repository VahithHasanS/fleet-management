import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CameraBreach, CameraBreachDoc, Vehicle, VehicleDoc } from '../database/schemas';
import { PubSub } from '../common/pubsub';

export interface CameraBreachInput {
  tenantId: string;
  vehicleId: string;
  tripId?: string;
  breachType: string;
  severity: string;
  durationMs?: number;
  confidence?: number;
  ear?: number;
  snapshot?: string;
  detail?: string;
}

@Injectable()
export class VideoTelematicsService {
  constructor(
    @InjectModel(CameraBreach.name) private readonly breaches: Model<CameraBreachDoc>,
    @InjectModel(Vehicle.name) private readonly vehicles: Model<VehicleDoc>,
    private readonly pubsub: PubSub,
  ) {}

  /** Persist a camera breach and fan it out to live subscribers + the alerts feed. */
  async recordBreach(input: CameraBreachInput) {
    const vehicle = await this.vehicles
      .findOne({ _id: this.oid(input.vehicleId), tenantId: input.tenantId })
      .exec();
    if (!vehicle) throw new NotFoundException('Vehicle not found in tenant');
    const driverId = vehicle.driverId ? String(vehicle.driverId) : undefined;

    const doc = await this.breaches.create({
      tenantId: input.tenantId,
      vehicleId: input.vehicleId,
      vehicleName: vehicle.name,
      driverId,
      tripId: input.tripId,
      breachType: input.breachType,
      severity: input.severity,
      timestamp: new Date(),
      durationMs: input.durationMs ?? 0,
      confidence: input.confidence ?? 0.5,
      ear: input.ear,
      snapshot: input.snapshot?.slice(0, 220_000),
      detail: input.detail,
    });
    const record = { id: String(doc._id), ...doc.toObject() };

    this.pubsub.emit('live.video_breach', { tenantId: input.tenantId, breach: record });
    // Surface as a persistent alert so it lands in the Alerts log and badge counts.
    await this.vehicles.db
      .collection('alerts')
      .insertOne({
        tenantId: input.tenantId,
        type: 'camera_breach',
        severity: input.severity,
        vehicleId: input.vehicleId,
        vehicleName: vehicle.name,
        driverId,
        message: `Camera AI: ${input.breachType.replace('_', ' ')} detected on ${vehicle.name}`,
        timestamp: new Date(),
        payload: {
          breachId: record.id,
          breachType: input.breachType,
          confidence: input.confidence ?? 0.5,
          durationMs: input.durationMs ?? 0,
          ear: input.ear,
        },
        read: false,
        createdAt: new Date(),
      } as never);

    return record;
  }

  async list(tenantId: string, opts: { vehicleId?: string; breachType?: string; from?: string; to?: string; limit?: number }) {
    const query: Record<string, unknown> = { tenantId };
    if (opts.vehicleId) query.vehicleId = opts.vehicleId;
    if (opts.breachType) query.breachType = opts.breachType;
    if (opts.from || opts.to) {
      query.timestamp = {
        ...(opts.from ? { $gte: new Date(opts.from) } : {}),
        ...(opts.to ? { $lte: new Date(opts.to) } : {}),
      };
    }
    const docs = await this.breaches
      .find(query)
      .sort({ timestamp: -1 })
      .limit(Math.min(opts.limit ?? 100, 300))
      .exec();
    // Snapshots can be large — only include them for the most recent 20 records.
    return docs.map((d, i) => {
      const obj = d.toObject() as unknown as Record<string, unknown>;
      obj.id = String(d._id);
      if (i >= 20) delete obj.snapshot;
      return obj;
    });
  }

  async stats(tenantId: string) {
    const since = new Date(Date.now() - 7 * 24 * 3600 * 1000);
    const rows = await this.breaches
      .aggregate([
        { $match: { tenantId, timestamp: { $gte: since } } },
        { $group: { _id: '$breachType', count: { $sum: 1 } } },
      ])
      .exec();
    const byType: Record<string, number> = {};
    let total = 0;
    for (const r of rows) {
      byType[r._id as string] = r.count;
      total += r.count;
    }
    return { total7d: total, byType };
  }

  private oid(id: string) {
    return id.match(/^[a-f\d]{24}$/i) ? id : id;
  }
}
