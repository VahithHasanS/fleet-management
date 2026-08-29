import {
  classifyEvent,
  TripStateMachine,
  haversineKm,
  distanceOf,
  scoreTrip,
} from './trip-logic';

describe('classifyEvent (India-tuned thresholds)', () => {
  it('rejects low-confidence samples', () => {
    expect(classifyEvent('car', undefined, { spd: 60, acc: -0.6, conf: 0.5 })).toBeNull();
  });

  it('detects harsh braking below car brakeG threshold', () => {
    const hit = classifyEvent('car', undefined, { spd: 62, acc: -0.5, conf: 0.92 });
    expect(hit).not.toBeNull();
    expect(hit?.type).toBe('harsh_brake');
  });

  it('allows normal braking under threshold', () => {
    expect(classifyEvent('car', undefined, { spd: 62, acc: -0.3, conf: 0.9 })).toBeNull();
  });

  it('detects harsh acceleration', () => {
    const hit = classifyEvent('car', undefined, { spd: 20, acc: 0.5, conf: 0.9 });
    expect(hit?.type).toBe('harsh_accel');
  });

  it('detects harsh cornering via lateral g', () => {
    const hit = classifyEvent('suv', undefined, { spd: 44, acc: 0.1, la: 0.36, conf: 0.88 });
    expect(hit?.type).toBe('harsh_corner');
  });

  it('detects speeding over class limit', () => {
    const hit = classifyEvent('truck', undefined, { spd: 78, acc: 0.2, conf: 0.95 });
    expect(hit?.type).toBe('speeding');
  });

  it('honours per-vehicle threshold overrides', () => {
    // Fleet manager lowered the truck brake threshold to 0.35g
    const hit = classifyEvent('truck', { brakeG: 0.35, accelG: 0.35, cornerG: 0.28, speedLimitKmh: 50 }, {
      spd: 30, acc: -0.38, conf: 0.9,
    });
    expect(hit?.type).toBe('harsh_brake');
  });

  it('falls back to car defaults for unknown classes', () => {
    const hit = classifyEvent('rickshaw', undefined, { spd: 40, acc: -0.47, conf: 0.9 });
    expect(hit?.type).toBe('harsh_brake');
  });
});

describe('TripStateMachine (60s start / 120s end)', () => {
  it('stays idle until speed sustained 60s', () => {
    const m = new TripStateMachine();
    for (let i = 1; i <= 30; i++) expect(m.accept(i, 40)).toBeNull();
    expect(m.accept(61, 40)).toBe('trip_started');
    expect(m.accept(62, 40)).toBeNull();
  });

  it('resets moving window if speed drops below threshold', () => {
    const m = new TripStateMachine();
    for (let i = 1; i <= 30; i++) m.accept(i, 40);
    m.accept(31, 0); // drop → moving window reset
    expect(m.accept(90, 40)).toBeNull(); // 59s of motion after reset → not yet
    expect(m.accept(91, 40)).toBe('trip_started'); // 60s → started
  });

  it('ends trip after 120s below threshold', () => {
    const m = new TripStateMachine();
    for (let i = 1; i <= 61; i++) m.accept(i, 40); // starts at t=61
    for (let i = 62; i <= 150; i++) m.accept(i, 40); // keep running
    expect(m.accept(271, 0)).toBe('trip_ended');
  });

  it('does not end on short stops', () => {
    const m = new TripStateMachine();
    for (let i = 1; i <= 61; i++) m.accept(i, 40);
    m.accept(70, 0);
    m.accept(71, 0);
    m.accept(72, 45);
    expect(m.accept(73, 45)).toBeNull();
  });
});

describe('scoreTrip (weighted penalty 0–100)', () => {
  it('baseline 100 for an empty event trip', () => {
    const s = scoreTrip({ events: [], smoothTrip: true });
    expect(s.totalScore).toBe(100);
    expect(s.positivePoints).toBe(2);
  });

  it('subtracts per-event penalties', () => {
    const s = scoreTrip({ events: [{ type: 'harsh_brake' }, { type: 'harsh_accel' }] });
    expect(s.totalScore).toBe(94);
    expect(s.positivePoints).toBe(0);
  });

  it('clamps at zero and does not reward scored trips', () => {
    const manyBrakes = [];
    for (let i = 0; i < 50; i++) manyBrakes.push({ type: 'harsh_brake' });
    const s = scoreTrip({ events: manyBrakes });
    expect(s.totalScore).toBe(0);
  });

  it('computes axis sub-scores', () => {
    const s = scoreTrip({ events: [{ type: 'harsh_corner' }, { type: 'speeding' }] });
    expect(s.subScores.cornering).toBe(98);
    expect(s.subScores.speeding).toBe(98);
  });
});

describe('haversine + distance', () => {
  it('returns ~0 for identical coordinates', () => {
    expect(haversineKm(11.01, 76.95, 11.01, 76.95)).toBeLessThan(0.001);
  });

  it('approximates 1 degree of latitude ≈ 111 km', () => {
    const d = haversineKm(11, 76, 12, 76);
    expect(d).toBeGreaterThan(105);
    expect(d).toBeLessThan(115);
  });

  it('sums multi-point distance', () => {
    const pts = [
      { lat: 11.01, lon: 76.95 },
      { lat: 11.012, lon: 76.95 },
      { lat: 11.014, lon: 76.95 },
    ];
    const d = distanceOf(pts);
    expect(d).toBeGreaterThan(0.42);
    expect(d).toBeLessThan(0.50); // 2 legs of ≈0.002° ≈ 0.222 km each
  });
});