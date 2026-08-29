# to-do.md — Task List

## Completed
- [x] Backend: all modules implementing & compiling (`tsc --noEmit` clean) — auth, telemetry/WS, processing/scoring, simulator, domain API, seed, health
- [x] Backend seed: demo tenant + 50 drivers/vehicles, geofences, trip/event/alert history, demo users (incl. `driver@ghost.local` DRIVER account linked to Arun Kumar / GT 01), idempotent `ensureDemoUsers()` on boot
- [x] Admin Flutter Web app: complete — 9 screens, custom canvas map, socket.io live updates, simulator control, CRUD, theming
- [x] **Driver Flutter app (`driver/`, project `ghost_driver`)**: complete — Login, Home (on-duty, trip status, metrics, SOS), Trips, Safety (score + coaching + live feed), Profile. Telemetry loop streams schemaVersion-1.2 batches over socket.io from `core/gps_simulator.dart` (swap for geolocator on device)
- [x] **E2E verification on this device** (`backend/scripts/e2e-driver-check.js`): driver login → WS → batch ack ok → SOS → live:sos push → critical alert created. Backend running locally (mongo 27017, redis).
- [x] Driver release web build compiles (`driver/build/web`)
- [x] Runtime problems on this device fixed: stale backend process killed (was serving old dist), snap-node stdout-to-file quirk diagnosed & worked around (pipe stdout)
- [x] Video telemetry screen implemented with real camera feed and drowsiness detection
- [x] Markdown files updated: memory.md, handover.md, ai_context.md, to-do.md

## In Progress
- [ ] Polish: fix remaining flutter analyze warnings/deprecation lints in admin and driver
- [ ] Real GPS on Android: replace `driver/lib/core/gps_simulator.dart` with `geolocator` stream + foreground service; add AndroidManifest permissions
- [ ] HOS/ELD/DVIR: backend schemas + endpoints, driver screens
- [ ] Deployment: serve built web apps via backend static/nginx; compose profile for full stack
- [ ] Background node.js process management fix for long-running builds

## Next up (priority order)
1. **Polish**: fix ~34 info lints in admin (withOpacity→withValues, etc.), 3 in driver
2. **Real GPS on Android**: replace GPS simulator with geolocator; add permissions
3. **HOS/ELD/DVIR**: implement backend endpoints and driver screens
4. **Deployment**: configure full stack with docker-compose, nginx serving

## Environment constraints
- Shell commands hard-capped ~30s → long builds must run backgrounded (`setsid bash -c '… 2>&1 | cat >> ~/log' < /dev/null &`) and be polled
- ⚠️ snap-node exits (code 1, silent) when stdout is redirected to a regular file — always pipe through `cat`
- Ports: a mongod may already own 27017; a stale backend may own 3000 (`ss -ltnp | grep :3000`)
- PDFs/images in `docs/` are reference material (some staged-then-deleted in git; `.gitignore` present)

## Validation commands
```bash
cd backend && npx tsc --noEmit -p tsconfig.json && npm test   # trip-logic.spec.ts
cd admin && flutter analyze && flutter build web
cd driver && flutter analyze && flutter build web
node backend/scripts/e2e-driver-check.js                      # needs backend up
```