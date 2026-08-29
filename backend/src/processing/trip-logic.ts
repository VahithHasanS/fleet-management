import {
  DEFAULT_THRESHOLDS,
  SCORE_PENALTIES,
  SMOOTH_DRIVING_BONUS,
  ClassThresholds,
} from '../common/constants';

export const EARTH_RADIUS_KM = 6371;

export function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(a));
}

export function bearingDeg(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const toDeg = (r: number) => (r * 180) / Math.PI;
  const y = Math.sin(toRad(lon2 - lon1)) * Math.cos(toRad(lat2));
  const x =
    Math.cos(toRad(lat1)) * Math.sin(toRad(lat2)) -
    Math.sin(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.cos(toRad(lon2 - lon1));
  return (toDeg(Math.atan2(y, x)) + 360) % 360;
}

export type DetectedEventType =
  | 'harsh_brake'
  | 'harsh_accel'
  | 'harsh_corner'
  | 'speeding'
  | null;

export interface PointForDetection {
  spd: number;
  acc: number;
  la?: number;
  conf: number;
}

export interface DetectResult {
  type: Exclude<DetectedEventType, null>;
  magnitude: number;
}

/**
 * Classify a single telemetry point against per-vehicle-class thresholds.
 * Thresholds are India-tuned (raised vs US defaults) to keep false positives on
 * rough road texture low. All values are in g for acceleration and km/h for speed.
 */
export function classifyEvent(
  vehicleClass: string,
  thresholds: Partial<ClassThresholds> | undefined,
  point: PointForDetection,
): DetectResult | null {
  const t: ClassThresholds = {
    ...DEFAULT_THRESHOLDS[convertClass(vehicleClass)],
    ...(thresholds ?? {}),
  };

  // Low-confidence samples never produce authoritative events (blueprint §1.1).
  if (point.conf < 0.6) return null;

  if (point.acc <= -t.brakeG) {
    return { type: 'harsh_brake', magnitude: round2(Math.abs(point.acc)) };
  }
  if (point.acc >= t.accelG) {
    return { type: 'harsh_accel', magnitude: round2(point.acc) };
  }
  if (point.la !== undefined && Math.abs(point.la) >= t.cornerG) {
    return { type: 'harsh_corner', magnitude: round2(Math.abs(point.la)) };
  }
  if (point.spd > t.speedLimitKmh) {
    return { type: 'speeding', magnitude: round2(point.spd - t.speedLimitKmh) };
  }
  return null;
}

function convertClass(vehicleClass: string): keyof typeof DEFAULT_THRESHOLDS {
  return (['car', 'suv', 'truck', 'bus'] as const).includes(vehicleClass as never)
    ? (vehicleClass as keyof typeof DEFAULT_THRESHOLDS)
    : 'car';
}

export interface TripScoringInput {
  events: Array<{ type: string }>;
  smoothTrip?: boolean;
}

export interface TripScores {
  subScores: { braking: number; acceleration: number; cornering: number; speeding: number };
  totalScore: number;
  positivePoints: number;
}

const AXIS_WEIGHTS: Record<string, number> = {
  harsh_brake: 3,
  harsh_accel: 3,
  harsh_corner: 2,
  speeding: 2,
};

export function scoreTrip(input: TripScoringInput): TripScores {
  const counts: Record<string, number> = {};
  let flatPenalty = 0;
  for (const e of input.events) {
    counts[e.type] = (counts[e.type] ?? 0) + 1;
    flatPenalty += SCORE_PENALTIES[e.type as keyof typeof SCORE_PENALTIES] ?? 0;
  }
  const axis = {
    braking: clampScore(counts.harsh_brake ?? 0, AXIS_WEIGHTS.harsh_brake),
    acceleration: clampScore(counts.harsh_accel ?? 0, AXIS_WEIGHTS.harsh_accel),
    cornering: clampScore(counts.harsh_corner ?? 0, AXIS_WEIGHTS.harsh_corner),
    speeding: clampScore(counts.speeding ?? 0, AXIS_WEIGHTS.speeding),
  };
  const smoothTrip = input.smoothTrip ?? (input.events.length === 0);
  let totalScore = clampInt(100 - flatPenalty);
  let positivePoints = 0;
  if (smoothTrip && flatPenalty === 0) {
    totalScore = clampInt(totalScore + SMOOTH_DRIVING_BONUS);
    positivePoints = SMOOTH_DRIVING_BONUS;
  }
  return { subScores: axis, totalScore, positivePoints };
}

function clampScore(count: number, weight: number): number {
  return clampInt(100 - count * weight);
}
function clampInt(v: number): number {
  return Math.max(0, Math.min(100, Math.round(v)));
}
function round2(v: number): number {
  return Math.round(v * 100) / 100;
}

export type TripTransition = 'trip_started' | 'trip_ended' | null;

/**
 * Speed-threshold trip segmentation state machine (pure, deterministic):
 *  - start when speed >= startSpeed maintained for startSustain seconds
 *  - end when speed < startSpeed for endSustain seconds
 */
export class TripStateMachine {
  mode: 'idle' | 'running' = 'idle';
  movingFor = 0;
  stoppedFor = 0;
  lastAtSec?: number;
  tripId?: string;

  constructor(
    private readonly startSpeed = 5,
    private readonly startSustain = 60,
    private readonly endSustain = 120,
    private readonly genId: () => string = () => `t_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
  ) {}

  accept(nowSec: number, speedKmh: number): TripTransition {
    const dt = this.lastAtSec !== undefined ? Math.max(0, nowSec - this.lastAtSec) : 0;
    this.lastAtSec = nowSec;
    if (dt <= 0) return null;

    if (this.mode === 'idle') {
      if (speedKmh >= this.startSpeed) {
        this.movingFor += dt;
        if (this.movingFor >= this.startSustain) {
          this.mode = 'running';
          this.movingFor = 0;
          this.stoppedFor = 0;
          this.tripId = this.genId();
          return 'trip_started';
        }
      } else {
        this.movingFor = 0;
      }
      return null;
    }

    // running
    if (speedKmh >= this.startSpeed) {
      this.stoppedFor = 0;
    } else {
      this.stoppedFor += dt;
      if (this.stoppedFor >= this.endSustain) {
        const id = this.tripId;
        this.tripId = undefined;
        this.stoppedFor = 0;
        this.mode = 'idle';
        return 'trip_ended';
      }
    }
    return null;
  }

  get active(): boolean {
    return this.mode === 'running';
  }
}

export function distanceOf(points: Array<{ lat: number; lon: number }>): number {
  let d = 0;
  for (let i = 1; i < points.length; i++) {
    d += haversineKm(points[i - 1].lat, points[i - 1].lon, points[i].lat, points[i].lon);
  }
  return d;
}