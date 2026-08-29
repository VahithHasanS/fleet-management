# memory.md — Decisions, Gotchas & Conventions

Last updated: 2026-08-28 (session 4 — project running & E2E-verified)

## Key decisions
- **No Google Maps in admin** — map is a self-drawn Flutter canvas (`admin/lib/widgets/custom_map.dart`): equirectangular projection around Coimbatore (~11.01N, 76.97E), geofence circles, status-colored heading-rotated markers, clustering at low zoom, `InteractiveViewer` pan/zoom. Avoids API keys entirely.
- **Single ChangeNotifier state** (`admin/lib/state/app_state.dart`) instead of redux/bloc — matches small app size; WS events fan directly into it.
- **Seed is idempotent twice over**: `seed()` early-returns if tenant slug exists; `ensureDemoUsers()` (added session 3) upserts demo users with `$setOnInsert` on every boot so existing DBs gain new accounts without reseed and without clobbering changed passwords.
- **Driver demo user** (`driver@ghost.local`, role DRIVER) linked via `User.driverId` → first driver "Arun Kumar" → vehicle "GT 01". Schema/auth already supported `driverId`, so only `seed.service.ts` changed.
- **Roles**: SUPER_ADMIN, FLEET_MANAGER, DISPATCHER, DRIVER. `DRIVER` users get `driverId` in login payload (auth.service.ts:35) — the driver app builds on this.
- **socket.io transport** for live data (path `/ws`, token in handshake auth, room join via `live:subscribe` event). `admin/lib/core/live_socket.dart` is the client reference implementation.
- **Video telemetry with drowsiness detection** (session 5): real-time AI camera feed integrated into admin dashboard driver monitoring. Driver closed-eye detection triggers breaches stored in MongoDB, visible in admin alerts. Camera feed accessible via Flutter `camera` package; drowsiness state synced with backend safety event processing.
- **Driver app telemetry path** (session 4): batches stream over the same socket.io `telemetry` message the simulator uses (schemaVersion `1.2`, ack returns `{status, reason?}` via `emitWithAck`). SOS is just a batch with an `sos` event → backend processor turns it into a critical alert + `live:sos` push. No new backend endpoints were needed.
- **Driver GPS is synthetic** (`driver/lib/core/gps_simulator.dart`): 1 Hz fixes, wandering speed 15–70 km/h, ~4% of ticks inject harsh brake/accel/corner so scoring has signal. On a real device swap this class for a `geolocator` stream — the batch shape stays identical.
- **Driver app batching**: 1 Hz fix accumulates 5 points, then flushes one batch (`batchStart` = now − lastT − 5s so point offsets line up).

## Gotchas / lessons learned
- ⚠️ Shell tool has a ~30s command cap → long builds (flutter release web: dart2js ~31s) get SIGTERMed (exit -15). Workaround: `setsid bash -c 'cmd > /tmp/log 2>&1 &'` then poll the log. Dart kernel stage compiles fine — the -15 is the timeout, not a compile error.
- ⚠️ When inserting code blocks mid-file, re-read the surrounding region afterward — an earlier insert left a duplicated orphan block (seedHistory call outside the method) that `tsc` then caught. Fixed.
- `hashPassword()` returns `{ salt, hash }` (not `{salt, passwordHash}`).
- Mongo unique index on `User.email`; upserts key on email.
- Admin config: `--dart-define=API_URL=...` build-time, or `window.ghostApiUrl` runtime override injected in `admin/web/index.html`.
- Backend defaults: port 3000, `AUTO_SEED=true`, `DEMO_PASSWORD=ghost123`, WS path `/ws`.
- Some `docs/` images/PDFs are staged-then-deleted in git (`AD` status) — don't resurrect them; they're reference material only.
- ⚠️ **snap-node stdout quirk (this device)**: `node app.js > file.log` exits instantly with code 1 and ZERO output when stdout is a regular file; backgrounded jobs also die without a pipe. Always run `node … 2>&1 | cat >> log` (even detached). Debugging this cost significant time in session 4.
- ⚠️ Check who owns ports before starting services: a mongod may already hold 27017 (test: `mongosh --port 27017 --eval 'db.runCommand({ping:1})'`); a stale backend can hold 3000 (`ss -ltnp | grep :3000`). A stale `dist/main.js` served old code and confused health checks.
- Domain API serializes vehicles with `id` (not `_id`) — client models accept both.
- `socket.io-client` is not a backend dependency (only server-side `socket.io`) — the e2e script needed `npm i --no-save socket.io-client`.
- `trip-logic.spec.ts` exists — keep `npm test` green when touching `processing/trip-logic.ts`.
- Driver operations endpoints: `/api/v1/tenants/:tenantId/driver-operations/{hos,dvir,wellness}`. Driver tokens are forced to their own `driverId`; manager reads require an explicit `driverId` query.
- Driver operations accept legacy string and current ObjectId references because existing seeded data contains both formats.

## Code conventions
- Backend: NestJS modules per folder, `@InjectModel` DI, `String(doc._id)` when handing ObjectIds to clients, tenant scoping via guards/decorators in `common/`.
- Admin: dark navy theme (`theme/app_theme.dart`), KPI cards + gauges widgets in `widgets/`, screens self-contained, models mirror backend DTOs exactly in `core/models.dart`.
- Frontend: camera initialization must handle platform differences (Android/iOS/Web); `availableCameras()` returns different types depending on platform version.

## Validation checklist (run after backend changes)
```bash
cd backend && npx tsc --noEmit -p tsconfig.json && npm test
cd admin && flutter analyze
```
