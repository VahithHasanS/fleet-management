import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  Alert,
  AlertDoc,
  AppSetting,
  AppSettingDoc,
  CameraBreach,
  CameraBreachDoc,
  Driver,
  DriverDoc,
  Geofence,
  GeofenceDoc,
  SafetyEvent,
  SafetyEventDoc,
  Trip,
  TripDoc,
  Vehicle,
  VehicleDoc,
} from '../database/schemas';

const DAY_MS = 24 * 3600 * 1000;

@Injectable()
export class InsightsService {
  constructor(
    @InjectModel(Trip.name) private readonly trips: Model<TripDoc>,
    @InjectModel(SafetyEvent.name) private readonly events: Model<SafetyEventDoc>,
    @InjectModel(Alert.name) private readonly alerts: Model<AlertDoc>,
    @InjectModel(Driver.name) private readonly drivers: Model<DriverDoc>,
    @InjectModel(Vehicle.name) private readonly vehicles: Model<VehicleDoc>,
    @InjectModel(Geofence.name) private readonly geofences: Model<GeofenceDoc>,
    @InjectModel(CameraBreach.name) private readonly breaches: Model<CameraBreachDoc>,
    @InjectModel(AppSetting.name) private readonly settings: Model<AppSettingDoc>,
  ) {}

  // ---------- reports ----------

  async reportSummary(tenantId: string, days = 7) {
    const since = new Date(Date.now() - days * DAY_MS);
    const [tripAgg, eventAgg, alertCount, breachCount, driverCount, vehicleCount] = await Promise.all([
      this.trips.aggregate([
        { $match: { tenantId, startTime: { $gte: since } } },
        {
          $group: {
            _id: null,
            trips: { $sum: 1 },
            distanceKm: { $sum: '$distanceKm' },
            avgScore: { $avg: '$totalScore' },
            smooth: { $sum: { $cond: ['$smoothTrip', 1, 0] } },
            positivePoints: { $sum: '$positivePoints' },
            maxSpeed: { $max: '$maxSpeedKmh' },
          },
        },
      ]).exec(),
      this.events.aggregate([
        { $match: { tenantId, timestamp: { $gte: since } } },
        { $group: { _id: '$type', count: { $sum: 1 } } },
      ]).exec(),
      this.alerts.countDocuments({ tenantId, timestamp: { $gte: since } }).exec(),
      this.breaches.countDocuments({ tenantId, timestamp: { $gte: since } }).exec(),
      this.drivers.countDocuments({ tenantId }).exec(),
      this.vehicles.countDocuments({ tenantId }).exec(),
    ]);
    const t = tripAgg[0] ?? { trips: 0, distanceKm: 0, avgScore: 100, smooth: 0, positivePoints: 0, maxSpeed: 0 };
    const byType: Record<string, number> = {};
    for (const e of eventAgg) byType[e._id as string] = e.count;
    return {
      windowDays: days,
      trips: t.trips,
      distanceKm: Math.round((t.distanceKm ?? 0) * 10) / 10,
      avgSafetyScore: Math.round((t.avgScore ?? 100) * 10) / 10,
      smoothTripRate: t.trips ? Math.round(((t.smooth ?? 0) / t.trips) * 1000) / 10 : 0,
      positivePoints: t.positivePoints ?? 0,
      maxSpeedKmh: t.maxSpeed ?? 0,
      eventsByType: byType,
      alerts: alertCount,
      cameraBreaches: breachCount,
      drivers: driverCount,
      vehicles: vehicleCount,
    };
  }

  async reportDaily(tenantId: string, days = 7) {
    const since = new Date(Date.now() - days * DAY_MS);
    const [tripRows, eventRows] = await Promise.all([
      this.trips.aggregate([
        { $match: { tenantId, startTime: { $gte: since } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$startTime' } },
            trips: { $sum: 1 },
            distanceKm: { $sum: '$distanceKm' },
            avgScore: { $avg: '$totalScore' },
          },
        },
        { $sort: { _id: 1 } },
      ]).exec(),
      this.events.aggregate([
        { $match: { tenantId, timestamp: { $gte: since } } },
        {
          $group: {
            _id: { day: { $dateToString: { format: '%Y-%m-%d', date: '$timestamp' } }, type: '$type' },
            count: { $sum: 1 },
          },
        },
      ]).exec(),
    ]);
    const byDay = new Map<string, { day: string; trips: number; distanceKm: number; avgScore: number; events: Record<string, number> }>();
    for (const r of tripRows) {
      byDay.set(r._id as string, {
        day: r._id as string,
        trips: r.trips,
        distanceKm: Math.round(r.distanceKm * 10) / 10,
        avgScore: Math.round(r.avgScore * 10) / 10,
        events: {},
      });
    }
    for (const r of eventRows) {
      const day = (r._id as { day: string }).day;
      const row = byDay.get(day) ?? { day, trips: 0, distanceKm: 0, avgScore: 100, events: {} };
      row.events[(r._id as { type: string }).type] = r.count;
      byDay.set(day, row);
    }
    return [...byDay.values()].sort((a, b) => a.day.localeCompare(b.day));
  }

  // ---------- predictive analytics (computed from real history) ----------

  async predictiveRisks(tenantId: string) {
    const since = new Date(Date.now() - 30 * DAY_MS);
    const [eventRows, tripRows, breachRows, drivers] = await Promise.all([
      this.events.aggregate([
        { $match: { tenantId, timestamp: { $gte: since }, driverId: { $exists: true } } },
        { $group: { _id: { driverId: '$driverId', type: '$type' }, count: { $sum: 1 } } },
      ]).exec(),
      this.trips.aggregate([
        { $match: { tenantId, startTime: { $gte: since }, driverId: { $exists: true } } },
        { $group: { _id: '$driverId', trips: { $sum: 1 }, km: { $sum: '$distanceKm' }, avgScore: { $avg: '$totalScore' } } },
      ]).exec(),
      this.breaches.aggregate([
        { $match: { tenantId, timestamp: { $gte: since }, driverId: { $exists: true } } },
        { $group: { _id: '$driverId', breaches: { $sum: 1 } } },
      ]).exec(),
      this.drivers.find({ tenantId }).limit(300).exec(),
    ]);

    const weight: Record<string, number> = {
      harsh_brake: 2, harsh_accel: 2, harsh_corner: 1.5, speeding: 1.5,
      geofence_breach: 3, sos: 4, wellness_alert: 2.5, camera_breach: 3.5, smooth_driving: 0,
    };
    const perDriver = new Map<string, { events: Record<string, number>; weighted: number }>();
    for (const r of eventRows) {
      const key = String((r._id as { driverId: string }).driverId);
      const row = perDriver.get(key) ?? { events: {}, weighted: 0 };
      const type = (r._id as { type: string }).type;
      row.events[type] = r.count;
      row.weighted += r.count * (weight[type] ?? 1);
      perDriver.set(key, row);
    }
    const tripsBy = new Map(tripRows.map((r) => [String(r._id), r]));
    const breachBy = new Map(breachRows.map((r) => [String(r._id), r.breaches]));

    const risks = drivers.map((d) => {
      const id = String(d._id);
      const row = perDriver.get(id);
      const tripsRow = tripsBy.get(id);
      const breaches = breachBy.get(id) ?? 0;
      const eventsTotal = row ? Object.values(row.events).reduce((a, b) => a + b, 0) : 0;
      const km = tripsRow?.km ?? 0;
      // Events per 100 km — exposure-corrected risk signal.
      const eventRate = km > 0 ? (eventsTotal / km) * 100 : eventsTotal > 0 ? 5 : 0;
      const cameraRate = km > 0 ? (breaches / km) * 100 : breaches > 0 ? 5 : 0;
      const score = Math.min(
        100,
        Math.round(
          eventRate * 12 + cameraRate * 15 +
          Math.max(0, 90 - (tripsRow?.avgScore ?? 90)) * 1.2 + breaches * 4,
        ),
      );
      const level = score >= 60 ? 'critical' : score >= 35 ? 'high' : score >= 15 ? 'medium' : 'low';
      const topEvent = row
        ? Object.entries(row.events).sort((a, b) => b[1] - a[1])[0]?.[0]
        : undefined;
      // 7-day projection from the observed 30-day rate.
      const projectedEvents7d = Math.round((eventsTotal / 30) * 7);
      return {
        driverId: id,
        driverName: d.name,
        riskScore: score,
        riskLevel: level,
        events30d: eventsTotal,
        topEventType: topEvent ?? 'none',
        cameraBreaches30d: breaches,
        distanceKm30d: Math.round(km * 10) / 10,
        trips30d: tripsRow?.trips ?? 0,
        avgScore30d: Math.round((tripsRow?.avgScore ?? 100) * 10) / 10,
        projectedEvents7d,
        recommendation:
          level === 'critical' ? 'Assign coaching program and restrict long-haul duty'
          : level === 'high' ? 'Schedule defensive-driving refresher within 7 days'
          : level === 'medium' ? 'Monitor weekly; share event feedback'
          : 'Healthy — eligible for positive-driving incentive',
      };
    });
    return risks.sort((a, b) => b.riskScore - a.riskScore);
  }

  // ---------- compliance (ELD rollups from real HOS/DVIR logs) ----------

  async complianceSummary(tenantId: string) {
    const since = new Date(Date.now() - 7 * DAY_MS);
    const db = this.drivers.db;
    const [hosLogs, dvirs] = await Promise.all([
      db.collection('hoslogs').find({ tenantId, startedAt: { $gte: since } }).toArray(),
      db.collection('dvirinspections').find({ tenantId, submittedAt: { $gte: since } }).toArray(),
    ]);
    const drivers = await this.drivers.find({ tenantId }).limit(300).exec();
    const nameOf = new Map(drivers.map((d) => [String(d._id), d.name]));

    interface DriverHos {
      driverId: string; driverName: string;
      drivingMs: number; onDutyMs: number; offDutyMs: number; sleeperMs: number;
      shifts: number; violations: string[];
    }
    const perDriver = new Map<string, DriverHos>();
    for (const log of hosLogs) {
      const key = String(log.driverId);
      const row = perDriver.get(key) ?? {
        driverId: key, driverName: nameOf.get(key) ?? key,
        drivingMs: 0, onDutyMs: 0, offDutyMs: 0, sleeperMs: 0, shifts: 0, violations: [] as string[],
      };
      const start = new Date(log.startedAt).getTime();
      const end = log.endedAt ? new Date(log.endedAt).getTime() : Date.now();
      const ms = Math.max(0, end - start);
      if (log.status === 'driving') row.drivingMs += ms;
      else if (log.status === 'on_duty') row.onDutyMs += ms;
      else if (log.status === 'sleeper') row.sleeperMs += ms;
      else row.offDutyMs += ms;
      row.shifts += 1;
      // FMCSA-style rules (demo thresholds): 11h driving / 14h duty per log.
      if (log.status === 'driving' && ms > 11 * 3600_000) row.violations.push('driving_limit_11h');
      if ((log.status === 'driving' || log.status === 'on_duty') && ms > 14 * 3600_000) row.violations.push('duty_limit_14h');
      perDriver.set(key, row);
    }
    const dvirByDriver = new Map<string, { preTrip: number; postTrip: number; defects: number }>();
    for (const ins of dvirs) {
      const key = String(ins.driverId);
      const row = dvirByDriver.get(key) ?? { preTrip: 0, postTrip: 0, defects: 0 };
      if (ins.inspectionType === 'pre_trip') row.preTrip += 1;
      else row.postTrip += 1;
      if (Array.isArray(ins.items)) {
        row.defects += (ins.items as Array<{ status: string }>).filter((i) => i.status === 'defect').length;
      }
      dvirByDriver.set(key, row);
    }
    const rows = [...perDriver.values()].map((r) => {
      const dvir = dvirByDriver.get(r.driverId) ?? { preTrip: 0, postTrip: 0, defects: 0 };
      const drivingH = Math.round((r.drivingMs / 3600_000) * 10) / 10;
      const onDutyH = Math.round(((r.onDutyMs + r.drivingMs) / 3600_000) * 10) / 10;
      if (drivingH > 0 && !dvir.preTrip) r.violations.push('missing_pre_trip');
      return {
        ...r,
        drivingHours7d: drivingH,
        onDutyHours7d: onDutyH,
        offDutyHours7d: Math.round((r.offDutyMs / 3600_000) * 10) / 10,
        preTrips7d: dvir.preTrip,
        postTrips7d: dvir.postTrip,
        defects7d: dvir.defects,
      };
    });
    const violations = rows.reduce((a, r) => a + r.violations.length, 0);
    return {
      windowDays: 7,
      driversMonitored: rows.length,
      hosLogs: hosLogs.length,
      dvirInspections: dvirs.length,
      openViolations: violations,
      violationRate: rows.length ? Math.round((violations / rows.length) * 100) / 100 : 0,
      drivers: rows,
    };
  }

  // ---------- wellness (aggregate real check-ins + camera breaches + fatigue events) ----------

  async wellnessFleet(tenantId: string) {
    const since = new Date(Date.now() - 7 * DAY_MS);
    const db = this.drivers.db;
    const [checkins, breachRows, fatigueEvents, drivers] = await Promise.all([
      db.collection('wellnesscheckins').find({ tenantId, createdAt: { $gte: since } }).toArray(),
      this.breaches.find({ tenantId, timestamp: { $gte: since } }).limit(500).exec(),
      this.events.find({ tenantId, type: 'wellness_alert', timestamp: { $gte: since } }).limit(500).exec(),
      this.drivers.find({ tenantId }).limit(300).exec(),
    ]);
    const nameOf = new Map(drivers.map((d) => [String(d._id), d.name]));
    interface WellnessRow {
      driverId: string; driverName: string; checkins: number;
      avgFatigue: number; avgStress: number; avgHydration: number;
      cameraBreaches: number; fatigueEvents: number; wellnessScore: number;
    }
    const blank = (key: string): WellnessRow => ({
      driverId: key, driverName: nameOf.get(key) ?? key, checkins: 0,
      avgFatigue: 0, avgStress: 0, avgHydration: 0, cameraBreaches: 0, fatigueEvents: 0, wellnessScore: 100,
    });
    const per = new Map<string, WellnessRow>();
    for (const c of checkins) {
      const key = String(c.driverId);
      const row = per.get(key) ?? blank(key);
      const n = row.checkins;
      row.avgFatigue = (row.avgFatigue * n + (c.fatigue ?? 0)) / (n + 1);
      row.avgStress = (row.avgStress * n + (c.stress ?? 0)) / (n + 1);
      row.avgHydration = (row.avgHydration * n + (c.hydration ?? 0)) / (n + 1);
      row.checkins += 1;
      per.set(key, row);
    }
    for (const b of breachRows) {
      const key = b.driverId ?? '';
      if (!key) continue;
      const row = per.get(key) ?? blank(key);
      row.cameraBreaches += 1;
      per.set(key, row);
    }
    for (const e of fatigueEvents) {
      const key = e.driverId ?? '';
      if (!key) continue;
      const row = per.get(key) ?? blank(key);
      row.fatigueEvents += 1;
      per.set(key, row);
    }
    const rows = [...per.values()].map((r) => {
      // 0-10-ish scales → wellness score: fatigue/stress subtract, hydration adds back.
      const penalty = (r.avgFatigue - 1) * 4 + (r.avgStress - 1) * 3 + r.cameraBreaches * 5 + r.fatigueEvents * 3;
      const bonus = (r.avgHydration - 1) * 1.5;
      return {
        ...r,
        avgFatigue: Math.round(r.avgFatigue * 10) / 10,
        avgStress: Math.round(r.avgStress * 10) / 10,
        avgHydration: Math.round(r.avgHydration * 10) / 10,
        wellnessScore: Math.max(0, Math.min(100, Math.round(100 - penalty + bonus))),
      };
    });
    return rows.sort((a, b) => a.wellnessScore - b.wellnessScore);
  }

  // ---------- route optimization (real nearest-neighbor over geofences) ----------

  async optimizeRoute(tenantId: string, vehicleId: string, geofenceIds: string[]) {
    const vehicle = await this.vehicles
      .findOne({ _id: vehicleId, tenantId })
      .exec();
    if (!vehicle) throw new NotFoundException('Vehicle not found');
    const fences = await this.geofences
      .find({ tenantId, _id: { $in: geofenceIds.filter((g) => g.match(/^[a-f\d]{24}$/i)) } })
      .exec();
    if (fences.length === 0) throw new NotFoundException('No matching geofence stops');

    // Start from the vehicle's live position (falls back to its last known fix).
    let cur = { lat: vehicle.lat ?? 11.008, lon: vehicle.lon ?? 76.962 };
    const remaining = [...fences];
    const ordered: Array<{ geofenceId: string; name: string; lat: number; lon: number; radiusM: number; legKm: number; etaMin: number }> = [];
    let totalKm = 0;
    while (remaining.length > 0) {
      let bestIdx = 0;
      let bestDist = Number.POSITIVE_INFINITY;
      for (let i = 0; i < remaining.length; i++) {
        const d = this.haversineKm(cur.lat, cur.lon, remaining[i].centerLat, remaining[i].centerLon);
        if (d < bestDist) { bestDist = d; bestIdx = i; }
      }
      const stop = remaining.splice(bestIdx, 1)[0];
      // ETA assumes the vehicle's average speed, floored at 25 km/h city traffic.
      const speed = Math.max(25, vehicle.speedKmh ?? 35);
      ordered.push({
        geofenceId: String(stop._id),
        name: stop.name,
        lat: stop.centerLat,
        lon: stop.centerLon,
        radiusM: stop.radiusM,
        legKm: Math.round(bestDist * 100) / 100,
        etaMin: Math.max(1, Math.round((bestDist / speed) * 60)),
      });
      totalKm += bestDist;
      cur = { lat: stop.centerLat, lon: stop.centerLon };
    }
    const skipped = geofenceIds.length - ordered.length;
    return {
      vehicleId: String(vehicle._id),
      vehicleName: vehicle.name,
      start: { lat: vehicle.lat ?? 11.008, lon: vehicle.lon ?? 76.962 },
      stops: ordered,
      totalKm: Math.round(totalKm * 100) / 100,
      totalEtaMin: ordered.reduce((a, s) => a + s.etaMin, 0),
      notes: [
        'Nearest-neighbor ordering computed from the vehicle live position.',
        skipped > 0 ? `${skipped} stop id(s) were invalid and skipped.` : 'All stops resolved.',
      ],
    };
  }

  // ---------- settings (persisted per tenant) ----------

  async getSettings(tenantId: string) {
    const doc = await this.settings.findOne({ tenantId }).exec();
    return {
      tenantId,
      data: doc?.data ?? {
        alerts: { soundEnabled: true, pushEnabled: true, severityThreshold: 'medium' },
        map: { showGeofences: true, clusterMarkers: true, defaultZoom: 12 },
        video: { drowsinessEnabled: true, frameRateFps: 2, snapshotOnBreach: true },
        scoring: { smoothDrivingBonus: 2, autoAcknowledgeLow: false },
      },
    };
  }

  async putSettings(tenantId: string, data: Record<string, unknown>) {
    const doc = await this.settings.findOneAndUpdate(
      { tenantId },
      { $set: { data } },
      { upsert: true, new: true },
    ).exec();
    return { tenantId, data: doc.data };
  }

  private haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLon / 2) ** 2;
    return 2 * R * Math.asin(Math.sqrt(a));
  }
}
