# Intelligent Fleet Management & Driver Safety Monitoring System
## Complete Project Blueprint — "Ghost Telemetry"

---

## 1. Ghost Telemetry: Core Technical Architecture

### 1.1 Sensor Fusion Algorithm

Ghost Telemetry infers vehicle-grade signals from phone-grade sensors. No single sensor is trustworthy alone — GPS drifts, accelerometers pick up phone handling noise, gyroscopes drift over time. The fusion layer treats this as a state estimation problem.

**Pipeline:**

1. **Raw ingestion** — GPS (lat/lon/alt/speed/bearing/accuracy, ~1Hz), accelerometer (x/y/z, 50–100Hz), gyroscope (rotation rate, 50–100Hz), magnetometer (heading, 10–25Hz), barometer where available (altitude change, useful for grade/multi-level parking).
2. **Coordinate frame transform** — Phone-frame acceleration must be rotated into vehicle-frame (forward/lateral/vertical) before it means anything. This is done via a rotation matrix derived from gravity vector (accelerometer at rest) and heading (magnetometer + GPS course-over-ground when moving above ~5 km/h). This is the single most failure-prone step because mounting orientation is unknown and can shift mid-trip.
3. **Kalman/complementary filter fusion** — An Extended Kalman Filter (EKF) or Unscented Kalman Filter (UKF) fuses GPS position/velocity with IMU-derived acceleration to produce a smoothed state vector: position, velocity, heading, acceleration. GPS corrects long-term drift; IMU fills in the high-frequency detail GPS's 1Hz rate misses (e.g., a hard brake happens faster than one GPS fix).
4. **Event derivation from the fused state:**
   - **Speed** — primarily GPS-derived (Doppler-based speed from GNSS chipsets is more accurate than differentiating position), IMU-augmented during GPS gaps.
   - **Acceleration/braking** — forward-axis acceleration from the rotated IMU vector, thresholded and duration-gated to distinguish a genuine harsh-brake event from a pothole jolt (single-sample spikes are rejected; events require sustained acceleration over ~300–500ms).
   - **Cornering force** — lateral-axis acceleration, cross-checked against gyroscope yaw rate and GPS bearing change, since lateral IMU noise from road camber is common.
   - **Engine idle vs. off** — inferred, not measured directly (no OBD-II access). Heuristic: near-zero GPS velocity + non-zero micro-vibration signature (engine running) + no significant device motion = idle. Sustained zero-vibration + zero-GPS-movement = engine off. This is the weakest inference in the system and should be labeled as "idle (inferred)" in the UI, not asserted as fact.

**Confidence scoring**: every derived event carries a confidence score (0–1) based on GPS HDOP, IMU calibration freshness, and how much interpolation was needed. Low-confidence events (<0.6) are flagged for coaching/analytics but excluded from anything with financial or regulatory consequence (insurance scoring, disciplinary action).

### 1.2 Calibration by Vehicle Type & Mounting Position

Calibration solves for two unknowns: mounting orientation and vehicle dynamics profile.

- **Orientation calibration** runs automatically at trip start using a short "stationary + first acceleration" window: gravity vector at rest gives roll/pitch; the first sustained forward acceleration (pulling away from a stop) gives the forward axis. No manual calibration step is required from the driver in the common case (dashboard/windshield mounts). Cup-holder and pocket mounts are flagged as "low-confidence mount" — the system still runs but suppresses cornering/braking coaching alerts (too noisy) and relies more heavily on GPS-only metrics.
- **Vehicle profile calibration** — a per-vehicle-class threshold table (sedan, SUV, light truck, bus) scales what counts as "harsh." A bus's normal deceleration profile would register as harsh braking on a sedan's thresholds. Initial values come from published NHTSA/insurer harsh-event thresshold ranges (roughly: harsh brake >0.35–0.4g sedans, >0.3g for taller/heavier vehicles which roll and pitch more at lower g). These are then auto-tuned per vehicle over the first ~50 trips using percentile-based normalization (e.g., "harsh" = 95th percentile of that vehicle's own observed deceleration distribution), so the system adapts to actual fleet vehicles rather than relying purely on generic tables.
- Recalibration triggers: vehicle reassignment to a different driver/vehicle-class, a run of consecutive low-confidence trips, or manual "recalibrate" from the fleet admin panel after a mount change.

### 1.3 Edge (On-Device) Preprocessing

Running raw 50–100Hz IMU data through the network is neither necessary nor affordable at fleet scale. The Flutter app does:

- **Noise filtering** — low-pass filter on accelerometer/gyroscope to remove high-frequency vibration (engine, road texture) before event detection; a moving-average or Butterworth filter is standard here.
- **Outlier rejection** — single-sample spikes beyond physically plausible bounds (e.g., >2g sustained, GPS speed jump >50 km/h between consecutive 1Hz fixes) are discarded rather than transmitted as events.
- **Event-based compression** — instead of streaming raw IMU continuously, the device runs the fusion/event-detection logic locally and transmits: (a) a downsampled position/speed trace (1 point per 3–5 seconds during steady-state driving, upsampled around events), and (b) discrete event records (type, timestamp, magnitude, confidence, short raw-sample snippet ±2s around the event for audit/replay). This cuts payload size by roughly 90%+ versus raw streaming and is what makes 100K-vehicle scale tractable on both bandwidth and server ingestion cost.
- **Batching & delta encoding** — position points are delta-encoded against the previous fix; batches are gzip/deflate-compressed client-side before transmission over WebSocket, flushed every 5–15 seconds or immediately for high-priority events (harsh event, SOS, geofence breach).

### 1.4 ML Pipeline

- **Model architecture** — a two-stage design works best here rather than one large model: Stage 1 is a lightweight on-device classifier (small gradient-boosted tree or tiny 1D-CNN, quantized, running via TFLite) that does event detection in real time for immediate driver coaching (audio/haptic feedback needs <200ms latency, which rules out a server round-trip). Stage 2 is a heavier server-side model (gradient-boosted trees or a sequence model such as an LSTM/temporal-CNN over trip-level features) that re-scores events with full trip context, cross-driver/cross-fleet baselines, and weather/road data the phone doesn't have — this is what feeds the authoritative safety score, not the on-device classifier.
- **Training data** — bootstrapped from labeled public driving-behavior datasets (e.g., UAH-DriveSet-style labeled harsh-event datasets) for cold start, then continuously improved using fleet-specific data: driver/dispatcher event confirmations or dismissals in the app become labels ("was this really harsh braking?"), and confirmed accidents (from insurance claims or manual incident reports) become strong positive labels for the accident-detection model specifically.
- **Retraining cadence** — Stage 2 server model: monthly retraining on a rolling 6-month window, with a shadow-mode evaluation period (new model scores computed but not surfaced) for 1–2 weeks before promotion, gated on precision/recall not regressing versus the current production model. Stage 1 on-device model: retrained quarterly and pushed via app update or a model-only OTA update mechanism (bundled model file fetched at app start, versioned, cached) to avoid full app releases just for model updates.
- **Evaluation** — precision/recall against the confirmed-event label set, with particular attention to false-positive rate for harsh-event alerts (too many false coaching alerts destroys driver trust in the system faster than almost anything else).

### 1.5 GPS Degradation Fallback

- **Detection** — GPS confidence drops when HDOP exceeds a threshold, satellite count falls below ~4, or fix age exceeds ~3 seconds without update.
- **Dead reckoning** — during degradation, position is propagated using last-known velocity + heading, integrated with IMU-derived acceleration and gyroscope-derived heading change. Error grows roughly with time-squared, so dead-reckoned position confidence decays on a timer (e.g., halving confidence every 15–20 seconds of pure DR) and is capped at a maximum trusted duration (~2 minutes) before the position is marked "unknown, tracking last road segment" rather than continuing to project a specific point.
- **Map-matching** — the DR-estimated trace is snapped to the most probable road segment using a map-matching algorithm (Hidden Markov Model over a road graph, à la the classic Newson & Krumm approach) rather than trusting raw DR coordinates, which meaningfully improves usability in tunnels/urban canyons where the vehicle is very likely still on the road it entered on.
- **Confidence scoring** surfaces to the UI as a simple three-state indicator (GPS-locked / dead-reckoning / lost) rather than presenting DR positions with false precision.

---

## 2. Backend Architecture (Node.js + Express + MongoDB)

### 2.1 Service Decomposition

| Service | Responsibility | Key scaling lever |
|---|---|---|
| Telemetry Ingestion | WebSocket/MQTT intake, schema validation, write to queue | Horizontal, stateless behind LB; sticky sessions for WS |
| Trip Processing | Trip start/stop detection, route reconstruction, idle/fuel estimation | Consumer group off the queue, scales with backlog |
| Safety Analytics | Real-time scoring, batch re-scoring (Stage 2 ML) | Split real-time (low-latency workers) vs. batch (scheduled jobs) |
| Notification | Push/SMS/email fan-out, escalation | Queue-driven, rate-limited per provider |
| Gamification | Points, badges, leaderboards | Read-heavy, cache-first (Redis) |
| Reporting/Analytics | Scheduled + ad hoc reports, exports | Separate read-replica-backed, isolated from OLTP path |

Ingestion is deliberately decoupled from processing via a message queue (Kafka or Redis Streams) so a spike in inbound telemetry never backpressures the WebSocket layer — ingestion's only job is "validate, ack, enqueue."

### 2.2 Telemetry Packet Schema (versioned)

```json
{
  "schemaVersion": "1.2",
  "vehicleId": "v_...",
  "tripId": "t_...",
  "seq": 10432,
  "batchStart": "2026-08-28T09:14:00Z",
  "points": [
    { "t": 0, "lat": 11.0168, "lon": 76.9558, "spd": 42.3, "hdg": 187, "acc": 4.2, "conf": 0.92 }
  ],
  "events": [
    { "type": "harsh_brake", "t": 3, "magnitude": 0.41, "conf": 0.87, "raw": "base64-snippet" }
  ]
}
```

Versioning strategy: `schemaVersion` is a required top-level field; ingestion routes packets to a version-specific parser, and N-1 backward compatibility is guaranteed for at least 2 major mobile app release cycles so fleets with slow device-update rollout aren't broken by a backend deploy.

### 2.3 Database Schema & Indexing

Collections: `vehicles`, `drivers`, `trips`, `telemetryPoints`, `safetyEvents`, `geofences`, `maintenanceRecords`, `auditLogs`.

- `telemetryPoints` is the volume driver — index on compound `{ vehicleId: 1, timestamp: -1 }`, and consider MongoDB's time-series collections (native since 5.0) rather than a plain collection, which handles bucketing/compression automatically and is purpose-built for this access pattern.
- `trips` indexed on `{ driverId: 1, startTime: -1 }` and `{ vehicleId: 1, startTime: -1 }`.
- `safetyEvents` indexed on `{ tripId: 1 }` and `{ driverId: 1, timestamp: -1 }` for coaching/leaderboard queries.
- `geofences` uses a `2dsphere` index for containment queries.

**Retention tiers**: hot (7 days, full-resolution points, primary MongoDB), warm (90 days, downsampled/aggregated trip summaries, still queryable), cold (>90 days, exported to S3-compatible storage as Parquet, queryable via Athena/Presto-style engine rather than MongoDB — this is the standard hot/warm/cold pattern for time-series-heavy IoT-style workloads and keeps primary DB size, and therefore cost and query latency, bounded).

**Sharding**: shard `telemetryPoints` on a compound key of `{ fleetId, timestamp }` (or `vehicleId` hashed within fleet) so a given fleet's data — and therefore its dashboard queries — stays co-located on a small number of shards rather than fanning out across the whole cluster.

### 2.4 API Layer

- REST for CRUD, documented with OpenAPI 3.0 (also used to generate the Flutter API client — see §5.1).
- GraphQL for dashboard queries where the admin UI needs flexible, deeply nested, client-shaped data (e.g., "fleet overview with nested vehicle → latest trip → last 5 safety events") that would otherwise require multiple REST round-trips or brittle over-fetching endpoints.
- Auth: JWT access tokens (short-lived, ~15 min) + rotating refresh tokens (stored hashed, single-use, rotated on each refresh to detect token theft/replay).
- RBAC roles as specified: Super Admin, Fleet Manager, Dispatcher, Driver, Maintenance Staff, Read-Only Analyst — enforced at the middleware layer with a permission matrix, not scattered `if (role === ...)` checks, so adding a role or resource doesn't require touching every route handler.
- Webhooks: HMAC-SHA256 signed payloads, exponential backoff retry (e.g., 1m/5m/30m/2h/12h) with a dead-letter queue after max attempts, and a replay-protection nonce/timestamp window on the receiving contract.

---

## 3. Flutter Mobile Applications

### 3.1 Driver App

- **Background tracking**: `flutter_background_geolocation` (or an equivalent) configured with motion-activity-triggered start/stop (don't burn battery tracking a parked car) and adaptive accuracy — full GPS accuracy while driving, degraded/geofence-triggered mode while stationary. This is the single biggest battery-life lever in the whole system; get it wrong and driver adoption fails regardless of how good the analytics are.
- **Coaching UI**: short audio cues (not full sentences — a 150ms tone plus a one-word haptic-paired alert reads faster than TTS) for harsh events, with a cooldown period per alert type to avoid alert fatigue on a rough road.
- **Trip summary**: map-based replay overlaying safety events at their actual location, with a score breakdown (braking/acceleration/cornering/speeding/phone-use sub-scores) rather than one opaque number, since drivers who can't see *why* they scored low can't act on it.
- **Offline queueing**: trips/events are written to a local store (SQLite via sqflite/drift, or a Riverpod-backed repository pattern as used elsewhere in your stack) and synced on reconnect with a monotonic sequence number per trip so the server can detect and drop duplicate/out-of-order batches — last-write-wins is fine for position points, but events need idempotency keys since a duplicate "harsh brake" event would double-count against a driver's score.
- **SOS**: one-tap SOS shares live location to fleet dispatch and pre-configured emergency contacts; true integration with local emergency services (e.g., automatic 112/911 dialing) varies by jurisdiction and should be scoped as "assist," not "replace" — the reliable, universally-available piece is instant location sharing to human dispatchers.

### 3.2 Fleet Operator App

Live map with marker clustering at low zoom (raw per-vehicle markers become unreadable past a few hundred vehicles), status color-coding, and breadcrumb trails capped to a rolling window (e.g., last 2 hours) to keep the map performant rather than accumulating unbounded polylines client-side.

### 3.3 Admin Web Dashboard (PWA)

Standard responsive dashboard patterns apply; the one fleet-specific piece worth calling out is geofence drawing tools needing corridor/route-buffer geometry (not just circle/polygon) since a lot of real fleet geofencing is "alert if the vehicle leaves this route by more than 500m," which is a buffered-line, not a simple polygon.

---

## 4. Advanced Intelligence Layer (Summary)

- **Predictive maintenance**: rule-based v1 (mileage/time thresholds + harsh-event frequency as a wear multiplier) before attempting survival-analysis/Bayesian models — you need months of labeled maintenance outcomes before a statistical model beats simple rules, so sequencing matters more than the modeling technique itself.
- **Route optimization**: OSRM/Valhalla for self-hosted routing if avoiding per-request API costs at scale matters; Mapbox/Google if time-to-market and traffic-data quality matter more than infra ownership. VRP solving (e.g., Google OR-Tools) for multi-stop optimization with time windows and driver shift-duration constraints.
- **Insurance/UBI**: keep the UBI score computation and the coaching score as related-but-separate scores — insurers want a stable, auditable, infrequently-changed formula; internal coaching benefits from a more responsive, frequently-tuned score. Conflating them means every internal tuning tweak becomes an insurance-contract question.
- **Compliance (ELD/GDPR/ISO 39001)**: ELD hours-of-service tracking needs an immutable edit-history log (edits allowed, but every edit requires a reason code and preserves the prior value — this is a DOT audit requirement, not a nice-to-have). GDPR/CCPA erasure requests need cascade-delete logic mapped out in the schema design phase, not retrofitted later, since telemetry/trip/event data is heavily cross-referenced.

---

## 5. Real-Time Infrastructure, Security, and Reliability

### 5.1 Real-Time
Topic-based pub/sub per fleet/driver, presence via heartbeat + last-seen timestamp, reconnection with exponential backoff **and jitter** (jitter matters at scale — without it, a network blip causes thousands of devices to reconnect in the same instant and thundering-herd the ingestion layer).

### 5.2 Security
Certificate pinning, field-level encryption for PII in MongoDB, JWT + refresh rotation as above. Root/jailbreak detection should degrade gracefully (warn + limit sensitive features) rather than hard-block, since false positives on legitimate devices are common enough to cause support burden if treated as a hard failure.

### 5.3 Reliability
99.99% availability and <200ms p99 are aggressive targets — worth stating plainly that they imply real multi-region infrastructure spend and chaos-engineering discipline, not just "we wrote good code." Circuit breakers between Trip Processing and Safety Analytics specifically matter, since a slow ML scoring path should never block trip ingestion.

---

## 6. Roadmap, KPIs, and — most importantly — Open Design Decisions

### 6.1 Roadmap
Phases 1–4 as scoped (Foundation → Intelligence → Scale & Integration → Ecosystem) are reasonable; the main risk is sequencing Predictive Maintenance and full ELD compliance too early — both need real accumulated data/regulatory review lead time that a young product won't have in month 4–6.

### 6.2 Open Question — Sensor Fusion vs. Cloud Processing (trade-off analysis)

| Factor | On-device | Server-side |
|---|---|---|
| **Latency** | Real-time coaching needs <200ms; only on-device meets this | Too slow for in-the-moment alerts |
| **Battery** | Continuous ML inference costs battery | No device battery cost |
| **Data cost** | Cheap — only compressed events transmitted | Expensive if raw streams sent |
| **Privacy** | Raw sensor data never leaves device | Raw data must be transmitted, larger attack surface |
| **Model updates** | Requires OTA model push, versioning complexity | Instant — deploy once, affects all vehicles |
| **Model sophistication** | Constrained by device compute (quantized, small) | Can run large sequence models, cross-fleet baselines |

**Recommendation**: hybrid, as designed in §1.4 — lightweight on-device model for real-time coaching and event pre-detection (latency- and battery-critical), heavier server-side model for authoritative scoring, cross-driver baselining, and anything with financial/legal consequence (insurance, disciplinary action). This isn't a compromise so much as the two stages solving genuinely different problems — one needs to be fast and cheap, the other needs to be accurate and auditable.

### 6.3 Other open questions worth resolving early (not fully specified in the request, flagged for your team)

- **Idle/engine-state accuracy expectations** — since this is inferred, not measured, what's the acceptable error rate before it undermines fuel/idle-time billing or driver disputes? This should be decided before idle time is tied to any pay or penalty calculation.
- **Data ownership on driver-owned devices (BYOD)** — for gig-economy driver models, whose data is it, and what happens to historical scores if a driver leaves the platform? This affects the GDPR/CCPA erasure design directly.
- **Model liability boundary** — if a false-negative accident-detection event delays emergency response, what's the documented limitation of the SOS/accident-detection feature communicated to drivers and fleets? Worth a legal review pass before Phase 1 ships SOS, not after.

---

*This document is a technical planning reference, not an implementation. Recommended next step: pick one vertical slice (e.g., Driver App background tracking → Ingestion → Trip Processing → basic Admin map) and build it end-to-end before expanding breadth, rather than building all services in parallel.*

3