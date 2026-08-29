export type Role =
  | 'SUPER_ADMIN'
  | 'FLEET_MANAGER'
  | 'DISPATCHER'
  | 'DRIVER'
  | 'MAINTENANCE'
  | 'ANALYST';

export const ROLES: Role[] = [
  'SUPER_ADMIN',
  'FLEET_MANAGER',
  'DISPATCHER',
  'DRIVER',
  'MAINTENANCE',
  'ANALYST',
];

export type Permission =
  | 'vehicles.read'
  | 'vehicles.write'
  | 'drivers.read'
  | 'drivers.write'
  | 'geofences.read'
  | 'geofences.write'
  | 'trips.read'
  | 'events.read'
  | 'alerts.read'
  | 'leaderboard.read'
  | 'simulator.control'
  | 'reports.read'
  | 'driver.operations.read'
  | 'driver.operations.write'
  | 'maintenance.read'
  | 'maintenance.write'
  | 'compliance.read'
  | 'wellness.read'
  | 'predictive.read'
  | 'video.read'
  | 'video.breach.write'
  | 'route.optimize'
  | 'settings.read'
  | 'settings.write';

export const ROLE_PERMISSIONS: Record<Role, Permission[]> = {
  SUPER_ADMIN: [
    'vehicles.read',
    'vehicles.write',
    'drivers.read',
    'drivers.write',
    'geofences.read',
    'geofences.write',
    'trips.read',
    'events.read',
    'alerts.read',
    'leaderboard.read',
    'simulator.control',
    'reports.read',
    'driver.operations.read',
    'driver.operations.write',
    'maintenance.read',
    'maintenance.write',
    'compliance.read',
    'wellness.read',
    'predictive.read',
    'video.read',
    'video.breach.write',
    'route.optimize',
    'settings.read',
    'settings.write',
  ],
  FLEET_MANAGER: [
    'vehicles.read',
    'vehicles.write',
    'drivers.read',
    'drivers.write',
    'geofences.read',
    'geofences.write',
    'trips.read',
    'events.read',
    'alerts.read',
    'leaderboard.read',
    'simulator.control',
    'driver.operations.read',
    'driver.operations.write',
    'reports.read',
    'maintenance.read',
    'maintenance.write',
    'compliance.read',
    'wellness.read',
    'predictive.read',
    'video.read',
    'video.breach.write',
    'route.optimize',
    'settings.read',
    'settings.write',
  ],
  DISPATCHER: [
    'vehicles.read',
    'drivers.read',
    'geofences.read',
    'trips.read',
    'events.read',
    'alerts.read',
    'leaderboard.read',
    'simulator.control',
    'route.optimize',
    'video.read',
  ],
  DRIVER: [
    'vehicles.read',
    'trips.read',
    'events.read',
    'driver.operations.read',
    'driver.operations.write',
    'video.breach.write',
    'settings.read',
    'settings.write',
  ],
  MAINTENANCE: ['vehicles.read', 'vehicles.write', 'reports.read', 'maintenance.read', 'maintenance.write'],
  ANALYST: [
    'vehicles.read',
    'drivers.read',
    'trips.read',
    'events.read',
    'reports.read',
    'driver.operations.read',
    'compliance.read',
    'wellness.read',
    'predictive.read',
    'video.read',
  ],
};

export type VehicleClass = 'car' | 'suv' | 'truck' | 'bus';

export const VEHICLE_CLASSES: VehicleClass[] = ['car', 'suv', 'truck', 'bus'];

export interface ClassThresholds {
  brakeG: number;
  accelG: number;
  cornerG: number;
  speedLimitKmh: number;
}

/**
 * India-tuned thresholds (adapted from NHTSA/insurer ranges) — road texture in
 * Indian cities produces high short-duration g spikes, so values are raised vs
 * the US defaults to keep the false-positive rate low. Per-vehicle-class and
 * overridable per fleet via the vehicle document.
 */
export const DEFAULT_THRESHOLDS: Record<VehicleClass, ClassThresholds> = {
  car: { brakeG: 0.45, accelG: 0.45, cornerG: 0.35, speedLimitKmh: 80 },
  suv: { brakeG: 0.42, accelG: 0.42, cornerG: 0.33, speedLimitKmh: 80 },
  truck: { brakeG: 0.4, accelG: 0.38, cornerG: 0.3, speedLimitKmh: 60 },
  bus: { brakeG: 0.4, accelG: 0.38, cornerG: 0.3, speedLimitKmh: 60 },
};

export type EventType =
  | 'harsh_brake'
  | 'harsh_accel'
  | 'harsh_corner'
  | 'speeding'
  | 'geofence_breach'
  | 'sos'
  | 'wellness_alert'
  | 'camera_breach'
  | 'smooth_driving';

export type EventSeverity = 'low' | 'medium' | 'high' | 'critical';

export const EVENT_SEVERITY: Record<EventType, EventSeverity> = {
  harsh_brake: 'high',
  harsh_accel: 'high',
  harsh_corner: 'medium',
  speeding: 'medium',
  geofence_breach: 'high',
  sos: 'critical',
  wellness_alert: 'medium',
  camera_breach: 'high',
  smooth_driving: 'low',
};

/** Penalty points subtracted from the 100 baseline per event. */
export const SCORE_PENALTIES: Record<EventType, number> = {
  harsh_brake: 3,
  harsh_accel: 3,
  harsh_corner: 2,
  speeding: 2,
  geofence_breach: 5,
  sos: 0,
  wellness_alert: 0,
  camera_breach: 0,
  smooth_driving: 0,
};

/** Bonus applied when a whole trip is event-free (Positive Driving Recognition). */
export const SMOOTH_DRIVING_BONUS = 2;

export const SIGNAL_STATES = ['gps-locked', 'dead-reckoning', 'lost'] as const;

export const TELEMETRY_SCHEMA_VERSION = '1.2';