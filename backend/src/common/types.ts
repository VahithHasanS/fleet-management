export interface TelemetryPoint {
  /** offset seconds from batchStart */
  t: number;
  lat: number;
  lon: number;
  spd: number;
  hdg: number;
  /** forward acceleration in g (positive = acceleration, negative = braking) */
  acc: number;
  /** lateral acceleration in g */
  la?: number;
  /** gyro yaw-rate deg/s */
  yaw?: number;
  conf: number;
}

export interface EventRecord {
  type: string;
  t: number;
  magnitude: number;
  conf: number;
  /** base64 raw sensor snippet (±2s) for audit/replay */
  raw?: string;
  /** optional custom payload (e.g. wellness detail) */
  detail?: string;
}

export interface Batch {
  schemaVersion: string;
  vehicleId: string;
  tripId?: string;
  seq: number;
  batchStart: string;
  points: TelemetryPoint[];
  events?: EventRecord[];
}

export interface AuthUser {
  userId: string;
  email: string;
  role: string;
  tenantId?: string;
  name?: string;
  driverId?: string;
}

export interface TelegramBatchRecord {
  id: string;
  batch: Batch;
}

export interface VehicleSnapshot {
  vehicleId: string;
  tenantId: string;
  fleetId?: string;
  name: string;
  plate: string;
  vehicleClass: string;
  driverId?: string;
  driverName?: string;
  lat: number;
  lon: number;
  speedKmh: number;
  heading: number;
  status: 'online' | 'idle' | 'in_transit' | 'offline';
  lastSeen: number;
  signal?: 'gps-locked' | 'dead-reckoning' | 'lost';
}

export interface TripSummary {
  tripId: string;
  tenantId: string;
  vehicleId: string;
  vehicleName: string;
  driverId?: string;
  driverName?: string;
  startTime: string;
  endTime: string;
  durationSec: number;
  distanceKm: number;
  avgSpeedKmh: number;
  maxSpeedKmh: number;
  subScores: { braking: number; acceleration: number; cornering: number; speeding: number };
  totalScore: number;
  positivePoints: number;
  events: { type: string; timestamp: string; magnitude: number; severity: string }[];
}