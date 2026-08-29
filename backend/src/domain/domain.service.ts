import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Driver, DriverDoc, Fleet, FleetDoc, Geofence, GeofenceDoc, SafetyEvent, SafetyEventDoc, Trip, TripDoc, Vehicle, VehicleDoc, Alert, AlertDoc } from '../database/schemas';
import { LiveService } from '../telemetry/live.service';

@Injectable()
export class DomainService {
  constructor(
    @InjectModel(Vehicle.name) private readonly vehicles: Model<VehicleDoc>,
    @InjectModel(Driver.name) private readonly drivers: Model<DriverDoc>,
    @InjectModel(Fleet.name) private readonly fleets: Model<FleetDoc>,
    @InjectModel(Geofence.name) private readonly geofences: Model<GeofenceDoc>,
    @InjectModel(Trip.name) private readonly trips: Model<TripDoc>,
    @InjectModel(SafetyEvent.name) private readonly events: Model<SafetyEventDoc>,
    @InjectModel(Alert.name) private readonly alerts: Model<AlertDoc>,
    private readonly live: LiveService,
  ) {}

  // ---------- vehicles ----------
  async listVehicles(tenantId: string, fleetId?: string) {
    const query: Record<string, unknown> = { tenantId };
    if (fleetId) query.fleetId = fleetId;
    const docs = await this.vehicles.find(query).sort({ name: 1 }).exec();
    const drivers = await this.completeDrivers(tenantId);
    const driverById = new Map(drivers.map((d) => [String(d._id), d]));
    return docs.map((v) => {
      const live = this.live.get(String(v._id));
      const driver = v.driverId ? driverById.get(String(v.driverId)) : undefined;
      return {
        id: String(v._id),
        tenantId,
        fleetId: v.fleetId ? String(v.fleetId) : undefined,
        name: v.name,
        plate: v.plate,
        vehicleClass: v.vehicleClass,
        speedLimitKmh: v.speedLimitKmh,
        driverId: v.driverId ? String(v.driverId) : undefined,
        driver: driver ? { id: String(driver._id), name: driver.name } : undefined,
        status: live?.status ?? v.status ?? 'offline',
        lat: live?.lat ?? v.lat,
        lon: live?.lon ?? v.lon,
        speedKmh: live?.speedKmh ?? v.speedKmh ?? 0,
        heading: live?.heading ?? v.heading ?? 0,
        lastSeen: (live?.lastSeen ?? v.lastSeen?.getTime() ?? 0) as number,
      };
    });
  }

  async createVehicle(tenantId: string, body: { name: string; plate: string; vehicleClass: string; fleetId?: string; driverId?: string; speedLimitKmh?: number }) {
    const doc = await this.vehicles.create({
      tenantId, name: body.name, plate: body.plate, vehicleClass: body.vehicleClass,
      fleetId: body.fleetId, driverId: body.driverId, speedLimitKmh: body.speedLimitKmh,
    });
    return { id: String(doc._id) };
  }

  async updateVehicle(tenantId: string, vehicleId: string, body: Partial<{ driverId: string; speedLimitKmh: number; vehicleClass: string; name: string; plate: string; fleetId: string }>) {
    const doc = await this.vehicles.findOneAndUpdate({ _id: vehicleId, tenantId }, { $set: body }, { new: true });
    if (!doc) throw new NotFoundException('Vehicle not found');
    return { id: String(doc._id) };
  }

  async deleteVehicle(tenantId: string, vehicleId: string) {
    const doc = await this.vehicles.findOneAndDelete({ _id: vehicleId, tenantId });
    if (!doc) throw new NotFoundException('Vehicle not found');
    this.live.setMarkOffline(vehicleId);
    return { deleted: true };
  }

  // ---------- drivers ----------
  private async completeDrivers(tenantId: string) {
    return this.drivers.find({ tenantId }).exec();
  }

  async listDrivers(tenantId: string, fleetId?: string) {
    const query: Record<string, unknown> = { tenantId };
    if (fleetId) query.fleetId = fleetId;
    const docs = await this.drivers.find(query).sort({ safetyScore: -1 }).exec();
    return docs.map((d) => ({
      id: String(d._id), tenantId, fleetId: d.fleetId ? String(d.fleetId) : undefined,
      name: d.name, phone: d.phone, email: d.email,
      safetyScore: d.safetyScore, positivePoints: d.positivePoints,
      tripsCount: d.tripsCount, avatarColor: d.avatarColor,
    }));
  }

  async createDriver(tenantId: string, body: { name: string; phone?: string; email?: string; fleetId?: string; avatarColor?: string }) {
    const doc = await this.drivers.create({ tenantId, name: body.name, phone: body.phone, email: body.email, fleetId: body.fleetId, avatarColor: body.avatarColor });
    return { id: String(doc._id) };
  }

  async leaderboard(tenantId: string) {
    const docs = await this.drivers.find({ tenantId }).sort({ safetyScore: -1, positivePoints: -1 }).limit(20).exec();
    return docs.map((d, i) => ({
      rank: i + 1, id: String(d._id), name: d.name, fleetId: d.fleetId,
      safetyScore: d.safetyScore, positivePoints: d.positivePoints,
      tripsCount: d.tripsCount, avatarColor: d.avatarColor,
    }));
  }

  // ---------- fleets ----------
  async listFleets(tenantId: string) {
    const docs = await this.fleets.find({ tenantId }).sort({ name: 1 }).exec();
    const vehicles = await this.vehicles.find({ tenantId }).exec();
    const counts = new Map<string, number>();
    for (const v of vehicles) {
      const fid = v.fleetId ? String(v.fleetId) : 'none';
      counts.set(fid, (counts.get(fid) ?? 0) + 1);
    }
    return docs.map((f) => ({ id: String(f._id), name: f.name, city: f.city, vehicleCount: counts.get(String(f._id)) ?? 0 }));
  }

  async createFleet(tenantId: string, body: { name: string; city?: string }) {
    const doc = await this.fleets.create({ tenantId, name: body.name, city: body.city });
    return { id: String(doc._id) };
  }

  // ---------- geofences ----------
  async listGeofences(tenantId: string) {
    const docs = await this.geofences.find({ tenantId }).exec();
    return docs.map((g) => ({ id: String(g._id), name: g.name, mode: g.mode, centerLat: g.centerLat, centerLon: g.centerLon, radiusM: g.radiusM, color: g.color }));
  }

  async createGeofence(tenantId: string, body: { name: string; centerLat: number; centerLon: number; radiusM: number; color?: string }) {
    const doc = await this.geofences.create({ tenantId, name: body.name, mode: 'entry-warning', centerLat: body.centerLat, centerLon: body.centerLon, radiusM: body.radiusM, color: body.color });
    return { id: String(doc._id) };
  }

  async deleteGeofence(tenantId: string, id: string) {
    await this.geofences.findOneAndDelete({ _id: id, tenantId });
    return { deleted: true };
  }

  // ---------- trips ----------
  async listTrips(tenantId: string, q: { driverId?: string; vehicleId?: string; from?: number; to?: number; limit?: number }) {
    const query: Record<string, unknown> = { tenantId };
    if (q.driverId) query.driverId = q.driverId;
    if (q.vehicleId) query.vehicleId = q.vehicleId;
    if (q.from || q.to) query.startTime = { ...(q.from ? { $gte: new Date(q.from) } : {}), ...(q.to ? { $lte: new Date(q.to) } : {}) };
    const docs = await this.trips.find(query).sort({ startTime: -1 }).limit(Math.min(q.limit ?? 100, 200)).exec();
    return docs.map((t) => ({
      id: String(t._id), vehicleId: t.vehicleId, vehicleName: t.vehicleName,
      driverId: t.driverId, driverName: t.driverName,
      startTime: t.startTime.toISOString(), endTime: t.endTime?.toISOString(),
      durationSec: t.durationSec, distanceKm: t.distanceKm, avgSpeedKmh: t.avgSpeedKmh, maxSpeedKmh: t.maxSpeedKmh,
      totalScore: t.totalScore, positivePoints: t.positivePoints, eventCount: t.eventCount, smoothTrip: t.smoothTrip,
    }));
  }

  async getTrip(tenantId: string, id: string) {
    const t = await this.trips.findOne({ _id: id, tenantId });
    if (!t) throw new NotFoundException('Trip not found');
    const evs = await this.events.find({ tenantId, tripId: id }).sort({ timestamp: 1 }).exec();
    return { trip: t.toObject(), events: evs };
  }

  // ---------- events ----------
  async listEvents(tenantId: string, q: { type?: string; vehicleId?: string; limit?: number; from?: number; to?: number }) {
    const query: Record<string, unknown> = { tenantId };
    if (q.type) query.type = q.type;
    if (q.vehicleId) query.vehicleId = q.vehicleId;
    if (q.from || q.to) query.timestamp = { ...(q.from ? { $gte: new Date(q.from) } : {}), ...(q.to ? { $lte: new Date(q.to) } : {}) };
    const docs = await this.events.find(query).sort({ timestamp: -1 }).limit(Math.min(q.limit ?? 100, 200)).exec();
    return docs.map((e) => ({
      id: String(e._id), type: e.type, severity: e.severity, magnitude: e.magnitude,
      confidence: e.confidence, timestamp: e.timestamp.toISOString(),
      vehicleId: e.vehicleId, vehicleName: e.vehicleName, driverId: e.driverId,
      lat: e.lat, lon: e.lon, detail: e.detail, acknowledged: e.acknowledged,
    }));
  }

  // ---------- alerts ----------
  async listAlerts(tenantId: string, limit = 50) {
    const docs = await this.alerts.find({ tenantId }).sort({ timestamp: -1 }).limit(limit).exec();
    return docs.map((a) => ({
      id: String(a._id), type: a.type, severity: a.severity, message: a.message,
      timestamp: a.timestamp.toISOString(), vehicleId: a.vehicleId, vehicleName: a.vehicleName,
      driverName: a.driverName, read: a.read, lat: a.payload?.lat ?? undefined, lon: a.payload?.lon ?? undefined,
    }));
  }

  async acknowledgeAlert(tenantId: string, id: string) {
    await this.alerts.findOneAndUpdate({ _id: id, tenantId }, { $set: { read: true } });
    return { ok: true };
  }

  // ---------- stats ----------
  async stats(tenantId: string) {
    const vehicles = await this.vehicles.countDocuments({ tenantId });
    const liveList = this.live.list(tenantId);
    const online = liveList.filter((v) => v.lastSeen > Date.now() - 120_000).length;
    const inTransit = liveList.filter((v) => v.status === 'in_transit').length;
    const alertsToday = await this.alerts.countDocuments({ tenantId, timestamp: { $gte: new Date(Date.now() - 24 * 3600_000) } });
    const eventsToday = await this.events.countDocuments({ tenantId, timestamp: { $gte: new Date(Date.now() - 24 * 3600_000) } });
    const tripsToday = await this.trips.countDocuments({ tenantId, startTime: { $gte: new Date(Date.now() - 24 * 3600_000) } });
    const avgScore = await this.drivers.aggregate([
      { $match: { tenantId } },
      { $group: { _id: null, avg: { $avg: '$safetyScore' } } },
    ]);
    return {
      totalVehicles: vehicles, onlineVehicles: online,
      inTransit, offlineVehicles: Math.max(0, vehicles - online),
      alertsToday, eventsToday, tripsToday,
      avgDriverScore: Math.round((avgScore[0]?.avg ?? 100) * 10) / 10,
    };
  }
}