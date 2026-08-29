import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class Tenant {
  @Prop({ required: true, unique: true })
  name: string;

  @Prop({ required: true, unique: true })
  slug: string;

  @Prop({ default: 'starter' })
  plan: string;

  @Prop({ default: 'Asia/Kolkata' })
  timezone: string;

  @Prop({ default: 'active' })
  status: string;
}
export type TenantDoc = Tenant & Document;
export const TenantSchema = SchemaFactory.createForClass(Tenant);

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  passwordHash: string;

  @Prop({ required: true })
  salt: string;

  @Prop({ required: true })
  role: string;

  @Prop({ type: Types.ObjectId, ref: Tenant.name })
  tenantId: string;

  @Prop()
  displayName?: string;

  @Prop({ type: Types.ObjectId, ref: 'Driver' })
  driverId?: string;
}
export type UserDoc = User & Document;
export const UserSchema = SchemaFactory.createForClass(User);

@Schema({ timestamps: true })
export class Fleet {
  @Prop({ type: Types.ObjectId, ref: Tenant.name, required: true, index: true })
  tenantId: string;

  @Prop({ required: true })
  name: string;

  @Prop()
  city?: string;
}
export type FleetDoc = Fleet & Document;
export const FleetSchema = SchemaFactory.createForClass(Fleet);

@Schema({ timestamps: true })
export class Vehicle {
  @Prop({ type: Types.ObjectId, ref: Tenant.name, required: true, index: true })
  tenantId: string;

  @Prop({ type: Types.ObjectId, ref: Fleet.name, index: true })
  fleetId?: string;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  plate: string;

  @Prop({ required: true, enum: ['car', 'suv', 'truck', 'bus'] })
  vehicleClass: string;

  @Prop({ type: Types.ObjectId, ref: 'Driver', index: true })
  driverId?: string;

  @Prop({ default: 80 })
  speedLimitKmh?: number;

  @Prop({ type: Object })
  thresholds?: { brakeG: number; accelG: number; cornerG: number; speedLimitKmh: number };

  @Prop({ default: 'offline' })
  status: string;

  @Prop()
  lat?: number;
  @Prop()
  lon?: number;
  @Prop({ default: 0 })
  speedKmh?: number;
  @Prop({ default: 0 })
  heading?: number;
  @Prop()
  lastSeen?: Date;
}
export type VehicleDoc = Vehicle & Document;
export const VehicleSchema = SchemaFactory.createForClass(Vehicle);

@Schema({ timestamps: true })
export class Driver {
  @Prop({ type: Types.ObjectId, ref: Tenant.name, required: true, index: true })
  tenantId: string;

  @Prop({ type: Types.ObjectId, ref: Fleet.name, index: true })
  fleetId?: string;

  @Prop({ required: true })
  name: string;

  @Prop()
  phone?: string;

  @Prop()
  email?: string;

  @Prop({ default: 100 })
  safetyScore: number;

  @Prop({ default: 0 })
  positivePoints: number;

  @Prop({ default: 0 })
  tripsCount: number;

  @Prop({ default: '#3B82F6' })
  avatarColor: string;
}
export type DriverDoc = Driver & Document;
export const DriverSchema = SchemaFactory.createForClass(Driver);

@Schema({ timestamps: true })
export class Geofence {
  @Prop({ type: Types.ObjectId, ref: Tenant.name, required: true, index: true })
  tenantId: string;

  @Prop({ required: true })
  name: string;

  /** entry-warning: alert when vehicle enters the circle */
  @Prop({ default: 'entry-warning' })
  mode: string;

  @Prop({ required: true })
  centerLat: number;

  @Prop({ required: true })
  centerLon: number;

  @Prop({ required: true })
  radiusM: number;

  @Prop({ default: '#EF4444' })
  color: string;
}
export type GeofenceDoc = Geofence & Document;
export const GeofenceSchema = SchemaFactory.createForClass(Geofence);

@Schema()
export class Trip {
  @Prop({ type: Types.ObjectId, ref: Tenant.name, required: true, index: true })
  tenantId: string;

  @Prop({ type: Types.ObjectId, ref: Fleet.name, index: true })
  fleetId?: string;

  @Prop({ required: true, index: true })
  vehicleId: string;

  @Prop()
  vehicleName?: string;

  @Prop({ index: true })
  driverId?: string;

  @Prop()
  driverName?: string;

  @Prop({ required: true })
  startTime: Date;

  @Prop()
  endTime?: Date;

  @Prop({ default: 0 })
  durationSec: number;

  @Prop({ default: 0 })
  distanceKm: number;

  @Prop({ default: 0 })
  avgSpeedKmh: number;

  @Prop({ default: 0 })
  maxSpeedKmh: number;

  @Prop()
  startLat?: number;
  @Prop()
  startLon?: number;
  @Prop()
  endLat?: number;
  @Prop()
  endLon?: number;

  @Prop({ type: Object })
  subScores: { braking: number; acceleration: number; cornering: number; speeding: number };

  @Prop({ default: 100 })
  totalScore: number;

  @Prop({ default: 0 })
  positivePoints: number;

  @Prop({ default: 0 })
  eventCount: number;

  @Prop({ default: false })
  smoothTrip: boolean;
}
export type TripDoc = Trip & Document;
export const TripSchema = SchemaFactory.createForClass(Trip);
TripSchema.index({ tenantId: 1, startTime: -1 });

@Schema()
export class SafetyEvent {
  @Prop({ type: Types.ObjectId, ref: Tenant.name, required: true, index: true })
  tenantId: string;

  @Prop()
  tripId?: string;

  @Prop({ required: true, index: true })
  vehicleId: string;

  @Prop()
  vehicleName?: string;

  @Prop({ index: true })
  driverId?: string;

  @Prop({ required: true })
  type: string;

  @Prop({ required: true })
  severity: string;

  @Prop({ default: 0 })
  magnitude: number;

  @Prop({ default: 0.5 })
  confidence: number;

  @Prop({ required: true, index: true })
  timestamp: Date;

  @Prop()
  lat?: number;
  @Prop()
  lon?: number;

  @Prop()
  detail?: string;

  @Prop({ default: false })
  acknowledged: boolean;
}
export type SafetyEventDoc = SafetyEvent & Document;
export const SafetyEventSchema = SchemaFactory.createForClass(SafetyEvent);
SafetyEventSchema.index({ tenantId: 1, timestamp: -1 });

@Schema()
export class Alert {
  @Prop({ type: Types.ObjectId, ref: Tenant.name, required: true, index: true })
  tenantId: string;

  @Prop({ required: true })
  type: string;

  @Prop({ required: true })
  severity: string;

  @Prop()
  vehicleId?: string;

  @Prop()
  vehicleName?: string;

  @Prop()
  driverId?: string;

  @Prop()
  driverName?: string;

  @Prop({ required: true })
  message: string;

  @Prop({ required: true })
  timestamp: Date;

  @Prop({ type: Object })
  payload?: Record<string, unknown>;

  @Prop({ default: false })
  read: boolean;
}
export type AlertDoc = Alert & Document;
export const AlertSchema = SchemaFactory.createForClass(Alert);
AlertSchema.index({ tenantId: 1, timestamp: -1 });

@Schema({ timestamps: true })
export class MaintenanceRecord {
  @Prop({ type: Types.ObjectId, ref: Tenant.name, required: true, index: true })
  tenantId: string;

  @Prop({ type: Types.ObjectId, ref: Vehicle.name, required: true, index: true })
  vehicleId: string;

  @Prop()
  vehicleName?: string;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true, enum: ['scheduled', 'repair', 'inspection', 'tire', 'oil', 'other'] })
  category: string;

  @Prop({ required: true, enum: ['open', 'in_progress', 'completed'] })
  status: string;

  @Prop({ required: true, enum: ['low', 'medium', 'high', 'critical'] })
  priority: string;

  @Prop({ required: true })
  dueDate: Date;

  @Prop()
  completedAt?: Date;

  @Prop()
  odometerKm?: number;

  @Prop()
  costInr?: number;

  @Prop()
  garage?: string;

  @Prop()
  notes?: string;
}
export type MaintenanceDoc = MaintenanceRecord & Document;
export const MaintenanceSchema = SchemaFactory.createForClass(MaintenanceRecord);
MaintenanceSchema.index({ tenantId: 1, dueDate: 1 });

@Schema({ timestamps: true })
export class CameraBreach {
  @Prop({ type: Types.ObjectId, ref: Tenant.name, required: true, index: true })
  tenantId: string;

  @Prop({ required: true, index: true })
  vehicleId: string;

  @Prop()
  vehicleName?: string;

  @Prop({ index: true })
  driverId?: string;

  @Prop()
  driverName?: string;

  @Prop({ required: true, index: true })
  tripId?: string;

  @Prop({ required: true, enum: ['drowsiness', 'eye_closure', 'distraction', 'yawning', 'camera_obstructed'] })
  breachType: string;

  @Prop({ required: true, enum: ['low', 'medium', 'high', 'critical'] })
  severity: string;

  @Prop({ required: true })
  timestamp: Date;

  /** How long the state persisted before the breach fired (ms). */
  @Prop({ default: 0 })
  durationMs: number;

  /** Detection confidence 0..1 from the on-device face-mesh model. */
  @Prop({ default: 0.5 })
  confidence: number;

  /** Thumbnail snapshot (base64 JPEG) captured at breach time. */
  @Prop()
  snapshot?: string;

  @Prop({ default: 0 })
  ear?: number;

  @Prop()
  detail?: string;
}
export type CameraBreachDoc = CameraBreach & Document;
export const CameraBreachSchema = SchemaFactory.createForClass(CameraBreach);
CameraBreachSchema.index({ tenantId: 1, timestamp: -1 });

@Schema({ timestamps: true })
export class AppSetting {
  @Prop({ type: Types.ObjectId, ref: Tenant.name, required: true, unique: true, index: true })
  tenantId: string;

  @Prop({ type: Object, default: {} })
  data: Record<string, unknown>;
}
export type AppSettingDoc = AppSetting & Document;
export const AppSettingSchema = SchemaFactory.createForClass(AppSetting);

export const MODELS = [
  { name: Tenant.name, schema: TenantSchema },
  { name: User.name, schema: UserSchema },
  { name: Fleet.name, schema: FleetSchema },
  { name: Vehicle.name, schema: VehicleSchema },
  { name: Driver.name, schema: DriverSchema },
  { name: Geofence.name, schema: GeofenceSchema },
  { name: Trip.name, schema: TripSchema },
  { name: SafetyEvent.name, schema: SafetyEventSchema },
  { name: Alert.name, schema: AlertSchema },
  { name: MaintenanceRecord.name, schema: MaintenanceSchema },
  { name: CameraBreach.name, schema: CameraBreachSchema },
  { name: AppSetting.name, schema: AppSettingSchema },
];
