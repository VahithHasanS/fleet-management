# plan.md — Work Plan

## Completed
- [x] Backend: all modules implemented & compiling (`tsc --noEmit` clean) — auth, telemetry/WS, processing/scoring, simulator, domain API, seed, health
- [x] Backend seed: demo tenant + 50 drivers/vehicles, geofences, trip/event/alert history, demo users (incl. `driver@ghost.local` DRIVER account linked to Arun Kumar / GT 01), idempotent `ensureDemoUsers()` on boot
- [x] Admin Flutter Web app: complete — 9 screens, custom canvas map, socket.io live updates, simulator control, CRUD, theming
- [x] **Driver Flutter app (`driver/`, project `ghost_driver`)**: complete — Login, Home (on-duty, trip status, metrics, SOS), Trips, Safety (score + coaching + live feed), Profile. Telemetry loop streams schemaVersion-1.2 batches over socket.io from `core/gps_simulator.dart` (swap for geolocator on device)
- [x] **E2E verification on this device** (`backend/scripts/e2e-driver-check.js`): driver login → WS → batch ack ok → SOS → live:sos push → critical alert created. Backend running locally (mongo 27017, redis).
- [x] Driver release web build compiles (`driver/build/web`)
- [x] Runtime problems on this device fixed: stale backend process killed (was serving old dist), snap-node stdout-to-file quirk diagnosed & worked around (pipe stdout)

## In progress
- (none)

## Session 5 update
- Driver operations are implemented: persisted HOS duty logs, DVIR inspections, and wellness check-ins.
- Driver mobile now exposes Trip, HOS, DVIR, Safety, Trips, and Profile workflows.
- Admin now exposes Driver Operations review for HOS and DVIR records.
- Live verification passed for health, login, telemetry/SOS, HOS, DVIR, and wellness create/read flows.
- Remaining HOS work is ELD certification, jurisdiction-specific limits, edits, signatures, and audit history.

## Next up (priority order)
1. **Polish** (optional): ~34 info lints in admin, 3 in driver (`withOpacity`→`withValues`, etc.)
2. **Real GPS on Android**: replace `driver/lib/core/gps_simulator.dart` with `geolocator`; foreground-service + permissions in AndroidManifest
3. **HOS/ELD/DVIR**: backend schemas + endpoints, driver screens
4. **Deployment**: serve built web apps via backend static or nginx; compose profile for full stack

## Known environment constraints
- Shell commands hard-capped ~30s → long builds must run backgrounded (`setsid bash -c '… 2>&1 | cat >> ~/log' < /dev/null &`) and be polled. Flutter release web build ≈ 60s.
- ⚠️ snap-node exits (code 1, silent) when stdout is redirected to a regular file — always pipe through `cat`.
- Ports: a mongod may already own 27017; a stale backend may own 3000 (`ss -ltnp | grep :3000`).
- PDFs/images in `docs/` are reference material (some staged-then-deleted in git; `.gitignore` present).

## Validation commands
```bash
cd backend && npx tsc --noEmit -p tsconfig.json && npm test   # trip-logic.spec.ts
cd admin && flutter analyze && flutter build web
cd driver && flutter analyze && flutter build web
node backend/scripts/e2e-driver-check.js                      # needs backend up
```
