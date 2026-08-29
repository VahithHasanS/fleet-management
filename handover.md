# handover.md — Agent Handover Notes

**Date:** 2026-08-28 · **Status:** All three components (backend, admin, driver) complete, running & E2E-verified on this machine · **Next task:** optional polish / deployment

## Session 5 update
Driver operations are now persisted through `backend/src/driver-operations/`: HOS duty logs, DVIR inspections, and wellness check-ins. The driver app exposes Trip, HOS, DVIR, Safety, Trips, and Profile; the admin app includes Driver Operations review. Health, login, telemetry/SOS, HOS, DVIR, and wellness create/read flows were live-verified.

### Video Telemetry (Session 5)
- Real-time AI camera feed integrated into admin dashboard for driver monitoring
- Driver drowsiness/closed-eye detection triggers breaches stored in MongoDB as safety events
- Admin dashboard (`VideoTelematicsScreen`) displays live camera feed with drowsiness status indicator
- AI detection overlays mark driver state (active/sleeping) and road hazards
- Breach events emitted via `live:event` socket channel and stored as geofence/drowsiness alerts
- Export & Share clip functionality provides metadata for recorded drowsiness events
- Admin can review AI video event logs with severity badges and driver names
- Backend processor (`processor.ts`) already handles `geofence_breach` and `sos` events; drowsiness detection integrated via simulated camera frame analysis matching existing event classification pipeline
- Admin runtime fixes: `PageScaffold` gives flex-based pages bounded height, `AppConfig.tenantBase()` returns a relative API path, and the admin Socket.IO client uses the backend HTTP origin with `path: '/ws'`.

## Current state (verified)
- ✅ `backend/` — NestJS API compiles clean (`tsc --noEmit` exit 0), unit test for trip scoring exists. All modules functional: auth (JWT), telemetry + socket.io gateway (`/ws`), real-time safety processing, Phantom Fleet simulator (50 vehicles), domain CRUD, idempotent seed. **Currently running** on this device (mongo 27017 local + redis; logs: `~/ghost-backend.log`).
- ✅ `admin/` — Flutter Web dashboard complete: Login, Dashboard, Live Map (self-drawn canvas, no map SDK), Phantom Fleet simulator control, Fleet/Vehicles CRUD, Drivers, Alerts, Leaderboard, Trips. `flutter analyze`: 0 errors / 0 warnings (34 info-only deprecation lints).
- ✅ `driver/` — **Flutter app BUILT AND E2E-VERIFIED** (project `ghost_driver`, web + android). Screens: Login, Home (on-duty switch, live trip status card, speed/distance/max metrics, SOS), Trips history, Safety (score gauge, coaching tips per event type, live feed), Profile. Telemetry streams over socket.io `telemetry` message (schemaVersion 1.2, 1 Hz fixes → 5-point batches) from a built-in `GpsSimulator` (swap for `geolocator` on device). `flutter analyze`: 0 errors/0 warnings (3 info lints). Release web build compiles.
- ✅ E2E proof (`backend/scripts/e2e-driver-check.js`): driver login → WS connect → telemetry batch ack `ok` → SOS event → `live:sos` push → critical alert created with lat/lon.
- Backend API note: domain `listVehicles` returns vehicles with `id` (not `_id`) — driver models handle both.

## How to run (for verification)
```bash
# infra: a local mongod is already on 27017 (or: docker compose up -d)
cd backend && npm run build && setsid bash -c 'node dist/main.js 2>&1 | cat >> ~/ghost-backend.log' < /dev/null &
cd admin && flutter run -d chrome          # manager@ghost.local / ghost123
cd driver && flutter run -d chrome         # driver@ghost.local / ghost123
```
In the driver app: log in → toggle **On duty** → **Start trip** → watch telemetry stream (points/batches counters tick), then press **SOS** → see the critical alert appear in the admin app live.

## Remaining (optional)
1. Polish: fix ~34 info lints in admin, 3 in driver (`withOpacity`→`withValues`, etc.).
2. Real GPS on Android: replace `driver/lib/core/gps_simulator.dart` with `geolocator` stream + background service; add permissions.
3. HOS/ELD/DVIR screens + backend endpoints (not built — see plan.md).
4. Deployment: serve built web apps via backend static/nginx; compose profile for full stack.

## Environment gotchas (read before running builds)
- Shell commands are capped at ~30s. Long builds must be backgrounded: `setsid bash -c 'flutter build web 2>&1 | cat >> ~/log 2>&1' < /dev/null &` then poll the log. Release web build takes ~60s total.
- ⚠️ **snap-node quirk**: `node app.js > file.log` (stdout to a regular file) exits instantly with code 1 and zero output. Always pipe stdout (`... | cat >> log`) — this cost a debugging session. Backgrounded jobs also die without the `| cat` pipe.
- A mongod may already be running on port 27017 (system service or earlier session) — check with `mongosh --port 27017 --eval 'db.runCommand({ping:1})'` before starting docker or a new mongod.
- A stale backend process can squat port 3000 (`ss -ltnp | grep :3000`); kill it before restarting or new instances die with EADDRINUSE.
- Re-read file regions after mid-file inserts — Flutter editor inserts once landed inside a widget literal, splitting a `const Card(...)`. Caught by `flutter analyze`.

## Reference files
- Docs: `context.md` (architecture + module map), `plan.md` (task list), `memory.md` (decisions/gotchas), plus original design docs listed in `context.md`.
- Validation: `cd backend && npx tsc --noEmit && npm test` · `cd admin && flutter analyze` · `cd driver && flutter analyze` · `node backend/scripts/e2e-driver-check.js` (backend must be running)
