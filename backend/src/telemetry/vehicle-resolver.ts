import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Driver, DriverDoc, Vehicle, VehicleDoc } from '../database/schemas';

export interface ResolvedVehicle {
  vehicleId: string;
  tenantId: string;
  fleetId?: string;
  name: string;
  plate: string;
  vehicleClass: string;
  driverId?: string;
  driverName?: string;
  speedLimitKmh: number;
  thresholds?: { brakeG: number; accelG: number; cornerG: number; speedLimitKmh: number };
}

const TTL_MS = 60_000;

@Injectable()
export class VehicleResolver {
  private cache = new Map<string, { v: ResolvedVehicle; at: number }>();

  constructor(
    @InjectModel(Vehicle.name) private readonly vehicles: Model<VehicleDoc>,
    @InjectModel(Driver.name) private readonly drivers: Model<DriverDoc>,
  ) {}

  async resolve(vehicleId: string): Promise<ResolvedVehicle | undefined> {
    const hit = this.cache.get(vehicleId);
    if (hit && Date.now() - hit.at < TTL_MS) return hit.v;

    const vehicle = await this.vehicles.findById(vehicleId);
    if (!vehicle) return undefined;
    let driverName: string | undefined;
    if (vehicle.driverId) {
      const d = await this.drivers.findById(vehicle.driverId);
      driverName = d?.name;
    }
    const v: ResolvedVehicle = {
      vehicleId: String(vehicle._id),
      tenantId: String(vehicle.tenantId),
      fleetId: vehicle.fleetId ? String(vehicle.fleetId) : undefined,
      name: vehicle.name,
      plate: vehicle.plate,
      vehicleClass: vehicle.vehicleClass,
      driverId: vehicle.driverId ? String(vehicle.driverId) : undefined,
      driverName,
      speedLimitKmh: vehicle.speedLimitKmh ?? 80,
      thresholds: vehicle.thresholds,
    };
    this.cache.set(vehicleId, { v, at: Date.now() });
    return v;
  }

  invalidate(vehicleId: string): void {
    this.cache.delete(vehicleId);
  }
}