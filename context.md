# context.md — Project Context

## What this project is
**SNS — "Ghost Telemetry" Fleet Safety Platform**: an intelligent fleet management & driver-safety system (IoV / telematics domain), built for the Coimbatore, India market. It ingests simulated vehicle telemetry, scores driver safety in real time, surfaces alerts/geofence events, and visualizes a live fleet map for fleet managers — plus a companion driver app.

Authoritative design docs (read these first):
- `ghost-telemetry-fleet-blueprint.md` — product/architecture blueprint
- `APPLICATION_MODULES_UI_DESIGN.md` — module list + UI design language (dark navy + blue/violet accents)
- `INTELLIGENT_FLEET_MANAGEMENT_DRIVER_SAFETY_DOCUMENT.md` — full PRD
- `DEVELOPMENT_GUIDE.md` — setup/dev guide
- `COMPETITOR_ANALYSIS.md` — market positioning

## Architecture
```
┌─────────────┐   HTTP/WS    ┌──────────────────────────────────────┐
│ admin/      │ ───────────► │ backend/ (NestJS, port 3000)         │
│ Flutter Web │ ◄─socket.io─ │  auth (JWT+refresh)                  │
└─────────────┘   /ws        │  telemetry (ingest + WS gateway)     │
                             │  processing (safety scoring engine)  │
┌─────────────┐              │  simulator ("Phantom Fleet")         │
│ driver/     │ ───────────► │  domain (CRUD API)                   │
│ Flutter app │ ◄─socket.io─ │  seed (demo tenant bootstrap)        │
│ (ghost_     │  /ws         └──────┬────────────┬──────────────────┘
│  driver)    │                     ▼            ▼
└─────────────┘               MongoDB (fleet)  Redis (pub/sub, live)
```
- `docker-compose.yml` runs Mongo + Redis.
- All entities are multi-tenant (`tenantId` scoping everywhere).

## Backend modules (backend/src)
| Module | Purpose |
|---|---|
| `auth/` | email/password login, JWT access+refresh, `hashPassword` (scrypt-ish), roles: SUPER_ADMIN, FLEET_MANAGER, DISPATCHER, DRIVER |
| `telemetry/` | telemetry ingestion, `live.service` in-memory live state, socket.io gateway (`/ws`, auth token, `live:subscribe`), vehicle-resolver |
| `processing/` | real-time safety scoring: harsh brake/accel/corner, speeding, wellness/fatigue; `trip-logic.ts` trip aggregation + scoring; unit-tested (`trip-logic.spec.ts`) |
| `simulator/` | "Phantom Fleet" — generates 50 simulated vehicles with realistic Coimbatore routes (`routes.ts`), start/stop/reset/inject-event endpoints |
| `domain/` | CRUD REST API for fleets, vehicles, drivers, geofences, trips, events, alerts, leaderboard, stats |
| `seed/` | idempotent demo-tenant bootstrap on boot (`AUTO_SEED=true`), incl. 50 drivers/vehicles, geofences, historical trips/events/alerts, and all demo users |
| `common/` | types, constants (thresholds per vehicle class), guards, decorators, pubsub, id helpers |

## Frontend: admin/ (IMPLEMENTED)
Flutter Web (project name `ghost_admin`), interactive OpenStreetMap tiles through `flutter_map` with geofence circles, status markers, attribution, and pan/zoom.
- `core/` config, api_client (bearer attach, refresh-on-401), live_socket (socket.io_client), models (all DTOs)
- `state/app_state.dart` — single ChangeNotifier: auth + cache + WS fan-in + simulator + CRUD
- `screens/` Login, Shell (nav rail), Dashboard, Live Map, Phantom Fleet, Fleet/Vehicles CRUD, Drivers, Alerts, Leaderboard, Trips
- `theme/app_theme.dart` — dark theme per UI design doc
- Includes Driver Operations review for persisted HOS and DVIR records. Status: `flutter analyze` has no errors (34 info lints remain).

## Frontend: driver/ (IMPLEMENTED)
Flutter app (`ghost_driver`, web + android targets) — mirrors admin's structure:
- `core/` config, api_client (bearer + refresh-on-401), **driver_socket** (socket.io: `live:subscribe` for events + `telemetry` batch streaming with ack), models, **gps_simulator** (synthetic 1 Hz Coimbatore GPS with periodic harsh events; swap for `geolocator` on a real device)
- `driver-operations/` backend endpoints persist HOS duty logs, DVIR inspections, and wellness check-ins with authenticated driver assignment enforcement.
- `state/app_state.dart` — single ChangeNotifier: auth, assigned-vehicle lookup, trip engine (1 Hz fix → 5-point batch → WS ingest → ack), SOS (sends an `sos` event in a telemetry batch), live event feed, trip history
- `screens/` Login, Home (on-duty switch, live location map, trip status card, speed/distance/max metrics, SOS), HOS, DVIR, Trips, Safety (score gauge, coaching, wellness check-in, live feed), Profile
- Status: `flutter analyze` has no errors (3 info lints); release web build compiles

## E2E proof
`backend/scripts/e2e-driver-check.js` — driver login → WS connect → telemetry batch (harsh events + `sos`) → ack `ok` → `live:sos` push → critical alert persisted with lat/lon. Run with backend up.

## Demo accounts (password `ghost123` unless DEMO_PASSWORD set)
- manager@ghost.local (FLEET_MANAGER) · superadmin@ghost.local (SUPER_ADMIN) · dispatch@ghost.local (DISPATCHER) · driver@ghost.local (DRIVER → Arun Kumar, vehicle GT 01)

## Running
```bash
docker compose up -d                 # mongo:27017, redis:6379 (a local mongod may already be up)
cd backend && npm run build && (node dist/main.js 2>&1 | cat >> ~/ghost-backend.log &)
cd admin && flutter pub get && flutter run -d chrome    # manager@ghost.local / ghost123
cd driver && flutter pub get && flutter run -d chrome   # driver@ghost.local / ghost123
```
Driver app flow: log in → On duty → Start trip (telemetry streams, counters tick) → SOS (critical alert appears in the admin app live).
Config knobs: `API_URL` dart-define (admin) or `window.ghostApiUrl` in `web/index.html`; backend `AUTO_SEED`, `DEMO_PASSWORD`.
