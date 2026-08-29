import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { MaintenanceRecord, MaintenanceDoc, Vehicle, VehicleDoc } from '../database/schemas';

@Injectable()
export class MaintenanceService {
  constructor(
    @InjectModel(MaintenanceRecord.name) private readonly records: Model<MaintenanceDoc>,
    @InjectModel(Vehicle.name) private readonly vehicles: Model<VehicleDoc>,
  ) {}

  async list(tenantId: string, opts: { status?: string; vehicleId?: string; from?: string; to?: string }) {
    const query: Record<string, unknown> = { tenantId };
    if (opts.status) query.status = opts.status;
    if (opts.vehicleId) query.vehicleId = opts.vehicleId;
    if (opts.from || opts.to) {
      query.dueDate = {
        ...(opts.from ? { $gte: new Date(opts.from) } : {}),
        ...(opts.to ? { $lte: new Date(opts.to) } : {}),
      };
    }
    const docs = await this.records.find(query).sort({ dueDate: 1 }).limit(300).exec();
    return docs.map((d) => ({ id: String(d._id), ...d.toObject() }));
  }

  async create(tenantId: string, body: {
    vehicleId: string; title: string; category: string; priority: string;
    dueDate: string; odometerKm?: number; costInr?: number; garage?: string; notes?: string;
  }) {
    const vehicle = await this.vehicles.findOne({ _id: this.oid(body.vehicleId), tenantId }).exec();
    if (!vehicle) throw new NotFoundException('Vehicle not found in tenant');
    const doc = await this.records.create({
      tenantId,
      vehicleId: body.vehicleId,
      vehicleName: vehicle.name,
      title: body.title,
      category: body.category,
      status: 'open',
      priority: body.priority,
      dueDate: new Date(body.dueDate),
      odometerKm: body.odometerKm,
      costInr: body.costInr,
      garage: body.garage,
      notes: body.notes,
    });
    return { id: String(doc._id), ...doc.toObject() };
  }

  async update(tenantId: string, id: string, body: Record<string, unknown>) {
    const patch: Record<string, unknown> = {};
    const allowed = ['status', 'priority', 'dueDate', 'costInr', 'garage', 'notes', 'odometerKm'];
    for (const k of allowed) if (body[k] !== undefined) patch[k] = body[k];
    if (body.status === 'completed') patch.completedAt = new Date();
    const doc = await this.records.findOneAndUpdate(
      { _id: this.oid(id), tenantId },
      { $set: patch },
      { new: true },
    ).exec();
    if (!doc) throw new NotFoundException('Maintenance record not found');
    return { id: String(doc._id), ...doc.toObject() };
  }

  async remove(tenantId: string, id: string) {
    const res = await this.records.deleteOne({ _id: this.oid(id), tenantId }).exec();
    if (res.deletedCount === 0) throw new NotFoundException('Maintenance record not found');
    return { deleted: true };
  }

  private oid(id: string) {
    return Types.ObjectId.isValid(id) ? new Types.ObjectId(id) : id;
  }
}
