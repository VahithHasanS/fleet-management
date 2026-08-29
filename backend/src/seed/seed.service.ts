import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Tenant, TenantDoc, User, UserDoc, Fleet, FleetDoc, Driver, DriverDoc, Vehicle, VehicleDoc, Geofence, GeofenceDoc, Trip, TripDoc, SafetyEvent, SafetyEventDoc, Alert, AlertDoc } from '../database/schemas';
import { DEFAULT_THRESHOLDS, VehicleClass, EVENT_SEVERITY } from '../common/constants';
import { hashPassword } from '../auth/password';

const DEMO_TENANT = {
  name: 'Ghost Logistics',
  slug: 'ghost-logs',
  plan: 'fleet-pro',
};

const USERS: Array<{ email: string; role: string; displayName: string }> = [
  { email: 'superadmin@ghost.local', role: 'SUPER_ADMIN', displayName: 'Aarav Nair' },
  { email: 'manager@ghost.local', role: 'FLEET_MANAGER', displayName: 'Meera Krishnan' },
  { email: 'dispatch@ghost.local', role: 'DISPATCHER', displayName: 'Karthik Subramanian' },
];

// Demo driver login for the mobile/web driver app. Linked to the first seeded
// driver ("Arun Kumar") and its assigned vehicle ("GT 01").
const DRIVER_DEMO_EMAIL = 'driver@ghost.local';
const DRIVER_DEMO_PASSWORD = 'ghost123';

const DRIVER_NAMES = [
  'Arun Kumar', 'Divya Prasanth', 'Mohan Raj', 'Priya Venkatesh', 'Suresh Babu',
  'Keerthana Ravi', 'Ganesh Pillai', 'Lakshmi Narayanan', 'Vijay Anand', 'Sneha Menon',
  'Ramesh Chandran', 'Anitha Suresh', 'Selvam Mariappan', 'Deepika Raman', 'Navin Prakash',
  'Rekha Iyer', 'Thiru Murugan', 'Sathya Devi', 'Prakash Jothi', 'Kathir Velu',
  'Muthu Kumar', 'Tamil Selvi', 'Saravanan Ravi', 'Uma Maheswari', 'Jayant Sharma',
  'Fathima Beevi', 'Rahul Dev', 'Navaneethan', 'Blessy Thomas', 'Ashwin Jose',
  'Vinoth Kumar', 'Swathi Srinivasan', 'Harish Raghavan', 'Meenakshi Anand', 'Dinesh Kumar',
  'Gayathri Mohan', 'Sabari Krishnan', 'Pooja Verma', 'Ilango Raman', 'Sandhya Sharma',
  'Kavya Menon', 'Sundar Raj', 'Jeeva Nandhan', 'Roshni Pillai', 'Abishek Nathan',
  'Deepa Balan', 'Vignesh Murthy', 'Swarna Lakshmi', 'Boopathi Raj', 'Chandrika Rao',
];

const BLUE_COLORS = ['#0EA5E9', '#6366F1', '#8B5CF6', '#EC4899', '#F59E0B', '#10B981', '#14B8A6', '#F43F5E'];

@Injectable()
export class SeedService implements OnApplicationBootstrap {
  private readonly logger = new Logger(SeedService.name);

  constructor(
    private readonly config: ConfigService,
    @InjectModel(Tenant.name) private readonly tenants: Model<TenantDoc>,
    @InjectModel(User.name) private readonly users: Model<UserDoc>,
    @InjectModel(Fleet.name) private readonly fleets: Model<FleetDoc>,
    @InjectModel(Driver.name) private readonly drivers: Model<DriverDoc>,
    @InjectModel(Vehicle.name) private readonly vehiclesModel: Model<VehicleDoc>,
    @InjectModel(Geofence.name) private readonly geofences: Model<GeofenceDoc>,
    @InjectModel(Trip.name) private readonly trips: Model<TripDoc>,
    @InjectModel(SafetyEvent.name) private readonly events: Model<SafetyEventDoc>,
    @InjectModel(Alert.name) private readonly alerts: Model<AlertDoc>,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    if (!this.config.get<boolean>('AUTO_SEED', true)) return;
    await this.seed();
    // Idempotent so existing deployments pick up newly added demo users on reboot.
    await this.ensureDemoUsers();
  }

  async seed(): Promise<void> {
    const existing = await this.tenants.findOne({ slug: DEMO_TENANT.slug });
    if (existing) {
      this.logger.log('seed: demo tenant already present, skipping');
      return;
    }

    const tenant = await this.tenants.create(DEMO_TENANT);
    const tenantId = String(tenant._id);
    const pass = this.config.get<string>('DEMO_PASSWORD', 'ghost123');
    const { salt, hash } = hashPassword(pass);

    for (const u of USERS) {
      await this.users.create({ email: u.email, role: u.role, displayName: u.displayName, tenantId, salt, passwordHash: hash });
    }

    const f1 = await this.fleets.create({ tenantId, name: 'City Delivery — Coimbatore', city: 'Coimbatore' });
    const f2 = await this.fleets.create({ tenantId, name: 'Intercity Logistics', city: 'Coimbatore' });

    const drivers = await Promise.all(
      DRIVER_NAMES.map((name, i) =>
        this.drivers.create({
          tenantId,
          fleetId: i % 3 === 0 ? String(f2._id) : String(f1._id),
          name,
          phone: `+91 9${String(7000000000 + i * 1379).slice(1)}`,
          email: `${name.toLowerCase().replace(/[^a-z0-9]+/g, '.').replace(/\.+/g, '.')}@ghost.local`,
          safetyScore: 100,
          avatarColor: BLUE_COLORS[i % BLUE_COLORS.length],
        }),
      ),
    );

    const vehicles = await Promise.all(
      DRIVER_NAMES.map((name, i) => {
        const cls: VehicleClass = i % 5 === 0 ? 'truck' : i % 7 === 0 ? 'bus' : i % 4 === 0 ? 'suv' : 'car';
        return this.vehiclesModel.create({
          tenantId,
          fleetId: i % 3 === 0 ? String(f2._id) : String(f1._id),
          name: `${CityTags[i % CityTags.length]} ${String(i + 1).padStart(2, '0')}`,
          plate: `TN 37 ${['AB', 'CD', 'EF', 'GH', 'JK', 'LM', 'NP', 'QR'][i % 8]} ${String(1000 + i * 73).slice(-4)}`,
          vehicleClass: cls,
          driverId: String(drivers[i]._id),
          speedLimitKmh: DEFAULT_THRESHOLDS[cls].speedLimitKmh,
          thresholds: DEFAULT_THRESHOLDS[cls],
          status: 'offline',
        });
      }),
    );

    await this.geofences.insertMany([
      { tenantId, name: 'Ukkadam Freight Hub', mode: 'entry-warning', centerLat: 10.9989, centerLon: 76.9563, radiusM: 900, color: '#F59E0B' },
      { tenantId, name: 'Peelamedu Airport Drop', mode: 'entry-warning', centerLat: 11.0292, centerLon: 77.0431, radiusM: 1100, color: '#8B5CF6' },
      { tenantId, name: 'Gandhipuram City Centre', mode: 'entry-warning', centerLat: 11.0186, centerLon: 76.9733, radiusM: 1300, color: '#EF4444' },
    ]);

    // Demo driver login linked to the first seeded driver + its vehicle (GT 01).
    const { salt: dSalt, hash: dHash } = hashPassword(DRIVER_DEMO_PASSWORD);
    await this.users.create({
      email: DRIVER_DEMO_EMAIL,
      role: 'DRIVER',
      displayName: drivers[0].name,
      tenantId,
      salt: dSalt,
      passwordHash: dHash,
      driverId: String(drivers[0]._id),
    });

    // Historical trips/events/alerts so dashboards look alive at first load.
    await this.seedHistory(tenantId, drivers, vehicles);

    this.logger.log(`seed: tenant "${DEMO_TENANT.name}" — ${drivers.length} drivers, ${vehicles.length} vehicles`);
  }

  /**
   * Upserts the demo sign-in users (admins + driver) so that existing databases
   * gain any newly added demo accounts without a full reseed.
   */
  private async ensureDemoUsers(): Promise<void> {
    const tenant = await this.tenants.findOne({ slug: DEMO_TENANT.slug });
    if (!tenant) return;
    const tenantId = String(tenant._id);
    const pass = this.config.get<string>('DEMO_PASSWORD', 'ghost123');
    const { salt, hash } = hashPassword(pass);

    for (const u of USERS) {
      await this.users.updateOne(
        { email: u.email },
        {
          $setOnInsert: {
            email: u.email, role: u.role, displayName: u.displayName,
            tenantId, salt, passwordHash: hash,
          },
        },
        { upsert: true },
      );
    }

    const demoDriver = await this.drivers.findOne({ tenantId, name: DRIVER_NAMES[0] });
    const driverHash = hashPassword(DRIVER_DEMO_PASSWORD);
    await this.users.updateOne(
      { email: DRIVER_DEMO_EMAIL },
      {
        $setOnInsert: {
          email: DRIVER_DEMO_EMAIL, role: 'DRIVER', displayName: DRIVER_NAMES[0],
          tenantId, salt: driverHash.salt, passwordHash: driverHash.hash,
          driverId: demoDriver ? String(demoDriver._id) : undefined,
        },
      },
      { upsert: true },
    );
  }

  private async seedHistory(tenantId: string, drivers: DriverDoc[], vehicles: VehicleDoc[]): Promise<void> {
    const now = Date.now();
    const day = 24 * 3600_000;
    const tripTypes = [
      { type: 'harsh_brake', magnitude: 0.52, conf: 0.93 },
      { type: 'harsh_accel', magnitude: 0.55, conf: 0.9 },
      { type: 'harsh_corner', magnitude: 0.42, conf: 0.87 },
      { type: 'wellness_alert', magnitude: 0.9, conf: 0.91 },
      { type: 'none', magnitude: 0, conf: 0 },
    ];

    const a = this.alerts.create.bind(this.alerts);

    for (let i = 0; i < 14; i++) {
      const v = vehicles[i % vehicles.length];
      const d = drivers[i % drivers.length];
      const start = now - (i + 1) * (day / 3) - Math.floor((Math.random() * day) / 12);
      const durationSec = 900 + Math.floor(Math.random() * 5400);
      const distanceKm = Math.round(((durationSec / 3600) * (28 + Math.random() * 22)) * 10) / 10;
      const maxSpeed = 34 + Math.floor(Math.random() * 30);
      const eventRoll = tripTypes[Math.floor(Math.random() * tripTypes.length)];
      const eventCount = eventRoll.type === 'none' ? 0 : 1;

      const trip = await this.trips.create({
        tenantId,
        fleetId: v.fleetId,
        vehicleId: String(v._id),
        vehicleName: v.name,
        driverId: String(d._id),
        driverName: d.name,
        startTime: new Date(start),
        endTime: new Date(start + durationSec * 1000),
        durationSec,
        distanceKm,
        avgSpeedKmh: Math.round((distanceKm / (durationSec / 3600)) * 10) / 10,
        maxSpeedKmh: maxSpeed,
        startLat: 11.008 + (Math.random() - 0.5) * 0.06,
        startLon: 76.96 + (Math.random() - 0.5) * 0.08,
        endLat: 11.02 + (Math.random() - 0.5) * 0.06,
        endLon: 76.99 + (Math.random() - 0.5) * 0.08,
        subScores: { braking: 0, acceleration: 0, cornering: 0, speeding: 0 },
        totalScore: 100 - this.penalty(eventRoll.type),
        positivePoints: eventRoll.type === 'none' ? 2 : 0,
        eventCount,
        smoothTrip: eventRoll.type === 'none',
      });

      if (eventRoll.type !== 'none') {
        await this.events.create({
          tenantId,
          tripId: String(trip._id),
          vehicleId: String(v._id),
          vehicleName: v.name,
          driverId: String(d._id),
          type: eventRoll.type,
          severity: EVENT_SEVERITY[eventRoll.type as keyof typeof EVENT_SEVERITY],
          magnitude: eventRoll.magnitude,
          confidence: eventRoll.conf,
          timestamp: new Date(start + Math.floor(durationSec * 1000 * 0.3)),
          lat: v.lat ?? 11.01,
          lon: v.lon ?? 76.97,
          detail: eventRoll.type === 'wellness_alert' ? 'simulated fatigue/stress signal' : undefined,
        });
        if (eventRoll.type === 'wellness_alert') {
          await a({
            tenantId,
            type: 'wellness_alert',
            severity: 'medium',
            vehicleId: String(v._id),
            vehicleName: v.name,
            driverId: String(d._id),
            driverName: d.name,
            message: `${d.name} fatigue/stress signal detected (simulated)`,
            timestamp: new Date(start + Math.floor(durationSec * 1000 * 0.3)),
            payload: { lat: v.lat ?? 11.01, lon: v.lon ?? 76.97, simulated: true },
          });
        }
      }
    }
  }

  private penalty(type: string): number {
    if (type === 'harsh_brake' || type === 'harsh_accel') return 3;
    if (type === 'harsh_corner') return 2;
    if (type === 'none') return 0;
    return 0;
  }
}

const CityTags = ['GT', 'AV', 'RD', 'ST', 'UK', 'CB', 'PM', 'KT']; // Ghost Telemetry prefix tags