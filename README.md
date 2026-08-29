# Ghost Telemetry — Intelligent Fleet Management & Driver Safety Monitoring

Monorepo for the Ghost Telemetry hackathon demo: a multi-tenant fleet management and
driver safety platform built from phone-grade sensors and simulated fleet data.

## Repo layout

```
backend/   NestJS + TypeScript + MongoDB (time-series) + Redis Streams
admin/     Flutter Web — operator live map, phantom-fleet simulator, alerts, leaderboard
driver/    Flutter app — Android (+ Web) driver tracking, HOS, DVIR, wellness, coaching, SOS
```

## Quick start (demo)

```bash
# 1. Infra (MongoDB + Redis)
docker compose up -d

# 2. Backend
cd backend
npm install
npm run start:dev      # seed runs automatically on first boot; Swagger at /docs

# 3. Admin web
cd ../admin
flutter pub get
flutter run -d chrome
#   (optional) point at a non-default backend:
#   flutter run -d chrome --dart-define=API_URL=http://host:3000

# 4. Driver app
cd ../driver
flutter pub get
flutter run -d chrome   # or -d <android-device>
#   (optional) point at a non-default backend:
#   set window.ghostApiUrl in driver/web/index.html
```

> **Admin app notes:** the live map is a self-contained canvas (no Google Maps API key
> needed) — it projects the Coimbatore fleet, draws geofence circles and clusters
> markers at low zoom. Login flow + live WebSocket (`/ws`) + simulator + CRUD all
> talk to the real backend. Runtime backend override is supported via
> `window.ghostApiUrl` in `admin/web/index.html`.
>
> The driver app includes the same telemetry-backed live location view for the
> assigned vehicle. Admin REST calls use relative tenant paths so runtime backend
> URL overrides work consistently.

### Maps

Both web applications use interactive OpenStreetMap tiles through `flutter_map`.
Vehicle markers, driver location, geofences, pan/zoom, and live telemetry remain
backed by the application API and Socket.IO stream. OpenStreetMap attribution is
shown inside each map; production deployments should follow the tile usage policy
or configure an approved tile provider.

### Demo users (demo-auth seam — Clerk-ready)

| Role        | Email                  | Password |
|-------------|------------------------|----------|
| Super Admin | `superadmin@ghost.local` | `ghost123` |
| Fleet Manager | `manager@ghost.local`  | `ghost123` |
| Dispatcher  | `dispatch@ghost.local` | `ghost123` |
| Driver      | `driver@ghost.local` | `ghost123` |

### Demo flow

1. Login to the admin web app (Fleet Manager).
2. Open **Fleet** → **Phantom Fleet** → **Start all (50 vehicles)**.
3. Watch vehicles move on the Coimbatore live map; markers cluster at low zoom.
4. Harsh events, speeding, geofence breaches, SOS and (simulated) wellness alerts will
   stream onto the map and the Alerts panel automatically.
5. Open **Leaderboard** to see trips produce weighted penalty scores + positive-driving points.
6. Open the driver app, login as a driver, Start Trip, and watch your real position stream live.
7. Use HOS, DVIR, and Safety wellness check-in; records are persisted and visible in Admin -> Driver Operations.

## Architecture (this demo)

```
Driver app / Simulator ──WebSocket──> Telemetry Ingestion ──> MongoDB time-series
                                          │                        Redis Stream
                                          ▼
                                   Trip Processor ──> trips, safetyEvents, scores
                                          │
                     events/positions/alerts ──WebSocket──> Admin live map
```

- Telemetry schema v1.2, idempotent batches (vehicleId + tripId + seq).
- Redis Streams as the queue seam (Kafka-ready).
- Multi-tenant aware (tenantId on every document, RBAC permission matrix, tenant guard).
- Real code end-to-end; only the 50 Coimbatore vehicles and their events are simulated.

## Tests

```bash
cd backend && npm test
cd backend && node scripts/e2e-driver-check.js
cd admin && flutter analyze && flutter build web
cd driver && flutter analyze && flutter build web
```# fleet-management
