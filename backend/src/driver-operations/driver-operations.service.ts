import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Driver, DriverDoc, Vehicle, VehicleDoc } from '../database/schemas';

type LogStatus = 'off_duty' | 'on_duty' | 'driving' | 'sleeper';

@Injectable()
export class DriverOperationsService {
  constructor(
    @InjectModel(Driver.name) private readonly drivers: Model<DriverDoc>,
    @InjectModel(Vehicle.name) private readonly vehicles: Model<VehicleDoc>,
  ) {}

  private async assertDriver(tenantId: string, driverId: string, vehicleId?: string) {
    const driverObjectId = Types.ObjectId.isValid(driverId)
      ? new Types.ObjectId(driverId)
      : undefined;
    const tenantObjectId = Types.ObjectId.isValid(tenantId)
      ? new Types.ObjectId(tenantId)
      : undefined;
    const driver = await this.drivers.db.collection('drivers').findOne({
      ...(driverObjectId ? { _id: driverObjectId } : { _id: driverId }),
      tenantId: { $in: [tenantId, ...(tenantObjectId ? [tenantObjectId] : [])] },
    } as never);
    if (!driver) throw new NotFoundException('Driver not found in tenant');
    if (vehicleId) {
      const vehicleObjectId = Types.ObjectId.isValid(vehicleId)
        ? new Types.ObjectId(vehicleId)
        : undefined;
      const vehicle = await this.vehicles.db.collection('vehicles').findOne({
        ...(vehicleObjectId ? { _id: vehicleObjectId } : { _id: vehicleId }),
        tenantId: { $in: [tenantId, ...(tenantObjectId ? [tenantObjectId] : [])] },
        driverId: { $in: [driverId, ...(driverObjectId ? [driverObjectId] : [])] },
      } as never);
      if (!vehicle) throw new NotFoundException('Vehicle is not assigned to driver');
    }
    return driver;
  }

  async listLogs(tenantId: string, driverId: string, from?: string, to?: string) {
    await this.assertDriver(tenantId, driverId);
    const query: Record<string, unknown> = { tenantId, driverId };
    if (from || to) {
      query.startedAt = {
        ...(from ? { $gte: new Date(from) } : {}),
        ...(to ? { $lte: new Date(to) } : {}),
      };
    }
    return this.drivers.db.collection('hoslogs').find(query).sort({ startedAt: -1 }).limit(200).toArray();
  }

  async createLog(tenantId: string, driverId: string, body: {
    vehicleId?: string;
    status: LogStatus;
    startedAt?: string;
    endedAt?: string;
    note?: string;
  }) {
    await this.assertDriver(tenantId, driverId, body.vehicleId);
    const record = {
      tenantId,
      driverId,
      vehicleId: body.vehicleId,
      status: body.status,
      startedAt: body.startedAt ? new Date(body.startedAt) : new Date(),
      endedAt: body.endedAt ? new Date(body.endedAt) : undefined,
      note: body.note,
      createdAt: new Date(),
    };
    const result = await this.drivers.db.collection('hoslogs').insertOne(record);
    return { id: String(result.insertedId), ...record };
  }

  async listDvir(tenantId: string, driverId: string) {
    await this.assertDriver(tenantId, driverId);
    return this.drivers.db.collection('dvirinspections').find({ tenantId, driverId }).sort({ submittedAt: -1 }).limit(100).toArray();
  }

  async submitDvir(tenantId: string, driverId: string, body: {
    vehicleId: string;
    inspectionType: 'pre_trip' | 'post_trip';
    safeToOperate: boolean;
    items: Array<{ name: string; status: 'ok' | 'defect' | 'na'; note?: string }>;
    signature?: string;
  }) {
    await this.assertDriver(tenantId, driverId, body.vehicleId);
    const record = { ...body, tenantId, driverId, submittedAt: new Date() };
    const result = await this.drivers.db.collection('dvirinspections').insertOne(record);
    return { id: String(result.insertedId), ...record };
  }

  async getWellness(tenantId: string, driverId: string) {
    await this.assertDriver(tenantId, driverId);
    return this.drivers.db.collection('wellnesscheckins').find({ tenantId, driverId }).sort({ createdAt: -1 }).limit(30).toArray();
  }

  async createWellness(tenantId: string, driverId: string, body: { fatigue: number; stress: number; hydration: number; note?: string }) {
    await this.assertDriver(tenantId, driverId);
    const record = { ...body, tenantId, driverId, createdAt: new Date() };
    const result = await this.drivers.db.collection('wellnesscheckins').insertOne(record);
    return { id: String(result.insertedId), ...record };
  }
}