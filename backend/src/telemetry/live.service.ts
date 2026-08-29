import { Injectable } from '@nestjs/common';
import { VehicleSnapshot } from '../common/types';
import { ResolvedVehicle } from './vehicle-resolver';

/**
 * In-memory latest-position store. At real scale this lives in Redis with sorting
 * and TTL per vehicle; the in-memory Map is the demo-sized equivalent.
 */
@Injectable()
export class LiveService {
  private snapshots = new Map<string, VehicleSnapshot>();

  upsert(v: ResolvedVehicle, input: { point: { lat: number; lon: number; spd: number; hdg: number }; ts: number }): VehicleSnapshot {
    const prev = this.snapshots.get(v.vehicleId);
    let status: VehicleSnapshot['status'];
    if (input.point.spd > 5) status = 'in_transit';
    else if (prev && prev.status === 'in_transit') status = 'idle';
    else status = 'online';
    const snap: VehicleSnapshot = {
      vehicleId: v.vehicleId,
      tenantId: v.tenantId,
      fleetId: v.fleetId,
      name: v.name,
      plate: v.plate,
      vehicleClass: v.vehicleClass,
      driverId: v.driverId,
      driverName: v.driverName,
      lat: round5(input.point.lat),
      lon: round5(input.point.lon),
      speedKmh: round1(input.point.spd),
      heading: input.point.hdg,
      status,
      lastSeen: input.ts,
      signal: 'gps-locked',
    };
    this.snapshots.set(v.vehicleId, snap);
    return snap;
  }

  setMarkOffline(vehicleId: string): void {
    const s = this.snapshots.get(vehicleId);
    if (s) s.status = 'offline';
  }

  list(tenantId?: string): VehicleSnapshot[] {
    const all = [...this.snapshots.values()];
    return tenantId ? all.filter((s) => s.tenantId === tenantId) : all;
  }

  get(vehicleId: string): VehicleSnapshot | undefined {
    return this.snapshots.get(vehicleId);
  }

  reset(tenantId: string): void {
    for (const [k, s] of this.snapshots) {
      if (s.tenantId === tenantId) this.snapshots.delete(k);
    }
  }
}

function round5(n: number): number {
  return Math.round(n * 1e5) / 1e5;
}
function round1(n: number): number {
  return Math.round(n * 10) / 10;
}