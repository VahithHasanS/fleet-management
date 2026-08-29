# ai_context.md — AI & Sensor Context

## Project Overview
**SNS — "Ghost Telemetry" Fleet Safety Platform**: an intelligent fleet management & driver-safety system (IoV / telematics domain) built for the Coimbatore, India market. The system ingests vehicle telemetry, scores driver safety in real time, surfaces alerts/geofence events, and visualizes a live fleet map for fleet managers — plus a companion driver app.

## AI Integration Context

### Video Telematics & Drowsiness Detection
- **Frontend**: Admin dashboard (`VideoTelematicsScreen`) integrates real-time camera feed using Flutter `camera` package
- **Camera Support**: Supports multiple camera views (Road View, Cabin View, Dual View) with platform-specific camera initialization
- **Drowsiness Detection**: 
  - Real-time monitoring of driver eye state via camera frames
  - Triggers `live:event` socket channel when drowsiness detected
  - Events stored as safety events in MongoDB with severity levels (low/medium/high/critical)
  - UI shows "DRIVER SLEEPING" indicator in red when closed eyes detected
- **Detection Pipeline**:
  1. Camera frame captured via `CameraController`
  2. Frame processed for eye state (EAR - Eye Aspect Ratio calculation)
  3. If eyes closed beyond threshold → drowsiness event emitted
  4. Backend processor creates safety event + breach record
  5. Admin UI updates to show driver sleeping status

### Backend Safety Event Processing
- **Existing event types**: harsh_brake, harsh_accel, harsh_corner, speeding, geofence_breach, sos, wellness_alert
- **New integration**: drowsiness events follow same pattern as other safety events
- **Breach storage**: Drowsiness breaches stored in MongoDB `safety_events` collection
- **Live push**: Via `pubsub.emit('live.event', {...})` to admin WebSocket clients
- **Alert creation**: Critical drowsiness events trigger `emitAlert()` → `live.alert` push

### Sensor & Telemetry Flow
- **Driver app**: GPS simulator (1 Hz fixes) → 5-point batches → socket.io `telemetry` message (schemaVersion 1.2)
- **Safety scoring**: Harsh events → geofence breaches → SOS → critical alerts
- **Breach cooldown**: 60s cooldown on geofence breaches to prevent duplicate alerts
- **SOS handling**: Single event → critical alert + `live:sos` push → admin critical alert creation

## Architecture Context
```
┌─────────────┐   HTTP/WS    ┌──────────────────────────────────────┐
│ admin/      │ ───────────► │ backend/ (NestJS, port 3000)         │
│ Flutter Web │ ◄─socket.io─ │  auth (JWT+refresh)                  │
│             │   /ws        │  telemetry (ingest + WS gateway)     │
└─────────────┘              │  processing (safety scoring engine)  │
                             │  simulator ("Phantom Fleet")         │
                                 └──────▲────────────┬──────────────────┘
                                        │            ▼
                                      MongoDB     Redis (pub/sub, live)
```

## Key Decisions
- **No Google Maps API keys**: Self-drawn Flutter canvas for maps around Coimbatore
- **Single state management**: ChangeNotifier over redux/bloc for small app size
- **Real-time via Socket.IO**: All live data flows through `/ws` path with token authentication
- **Camera platform handling**: `availableCameras()` returns different types on Android/iOS/Web
- **Backend-first safety processing**: All event classification and breach detection happens in NestJS processor

## Running Context
- Backend: `cd backend && npm run build && node dist/main.js`
- Admin: `cd admin && flutter run -d chrome` (manager@ghost.local / ghost123)
- Driver: `cd driver && flutter run -d chrome` (driver@ghost.local / ghost123)
- Demo accounts: manager@ghost.local, superadmin@ghost.local, dispatch@ghost.local, driver@ghost.local