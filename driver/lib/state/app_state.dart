import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/driver_socket.dart';
import '../core/gps_simulator.dart';
import '../core/models.dart';
import '../core/monitor/camera_monitor.dart';

/// Central state for the driver app: auth, assigned vehicle lookup, the
/// active trip telemetry loop, live event feed, SOS, and trip history.
class AppState extends ChangeNotifier {
  AppState() {
    api = ApiClient()..onUnauthorized = _tryRefresh;
    socket = DriverSocket()
      ..onMessage = _onLiveMessage
      ..onConnectionChange = (connected) {
        wsConnected = connected;
        if (connected && user != null) {
          socket.subscribe(tenantId: user!.tenantId);
        }
        notifyListeners();
      };
    camera
      ..onStateChanged = () {
        cameraLastError = camera.lastError;
        notifyListeners();
      }
      ..onFrame = (frame) async {
        final v = myVehicle;
        if (user == null || v == null || !tripActive) return false;
        final ack = await socket.sendVideoFrame({
          ...frame,
          'vehicleId': v.id,
          'tripId': _tripId,
        });
        return ack?['status'] == 'ok';
      }
      ..onBreach = (breach) async {
        final v = myVehicle;
        if (user == null || v == null) return false;
        final ack = await socket.sendVideoBreach({
          ...breach,
          'vehicleId': v.id,
          'tripId': _tripId,
        });
        if (ack?['status'] == 'ok') {
          liveFeed.insert(
            0,
            LiveMessage(
              'camera_breach',
              {
                'breachType': breach['breachType'],
                'severity': breach['severity'],
                'detail': breach['detail'],
                'vehicleId': v.id,
              },
            ),
          );
          notifyListeners();
        }
        return ack?['status'] == 'ok';
      };
  }

  late final ApiClient api;
  late final DriverSocket socket;

  // ---------- auth ----------
  AuthUser? user;
  bool loading = false;
  String? error;

  // ---------- derived entities ----------
  VehicleRecord? myVehicle;
  List<VehicleRecord> vehicles = [];
  List<TripRecord> myTrips = [];

  void setMyVehicle(VehicleRecord v) {
    myVehicle = v;
    notifyListeners();
  }
  List<SafetyEventRecord> myEvents = [];
  List<HosLog> hosLogs = [];
  List<DvirInspection> inspections = [];
  List<LiveMessage> liveFeed = [];

  bool wsConnected = false;

  // ---------- driver camera monitoring (video telematics) ----------
  final CameraMonitor camera = CameraMonitor();
  bool cameraEnabled = false;
  String? cameraLastError;

  // ---------- active trip ----------
  bool onDuty = false;
  bool tripActive = false;
  DateTime? tripStart;
  int pointsSent = 0;
  int batchesSent = 0;
  int batchesAcked = 0;
  double distanceKm = 0;
  double maxSpeedKmh = 0;
  double lastSpeedKmh = 0;
  double lastLat = 0;
  double lastLon = 0;
  bool streaming = false;
  String? lastIngestStatus;
  bool sosSent = false;

  Timer? _tripTimer;
  GpsSimulator? _gps;
  String? _tripId;
  final List<Map<String, dynamic>> _pending = [];

  String? get driverId => user?.driverId;
  int get tripElapsedSec =>
      tripStart == null ? 0 : DateTime.now().difference(tripStart!).inSeconds;

  double get avgScore {
    if (myTrips.isEmpty) return 100;
    final s = myTrips.fold<int>(0, (a, t) => a + t.totalScore) / myTrips.length;
    return s.roundToDouble();
  }

  // ========================================================== auth
  Future<bool> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.post(
        '/api/v1/auth/login',
        body: {'email': email, 'password': password},
      );
      user = AuthUser.fromResponse((res as Map).cast<String, dynamic>());
      api.token = user!.accessToken;
      socket.connect(token: user!.accessToken);
      await _loadDriverContext();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (e) {
      error = 'Cannot reach backend at ${AppConfig.apiUrl}';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> _tryRefresh() async {
    if (user == null || user!.refreshToken.isEmpty) return null;
    try {
      final res = await api.post(
        '/api/v1/auth/refresh',
        body: {'refreshToken': user!.refreshToken},
        retryOnUnauthorized: false,
      );
      final fresh = AuthUser.fromResponse((res as Map).cast<String, dynamic>());
      user = _withTokens(fresh.accessToken, fresh.refreshToken);
      api.token = fresh.accessToken;
      return fresh.accessToken;
    } catch (_) {
      return null;
    }
  }

  AuthUser _withTokens(String access, String refresh) => AuthUser(
    userId: user!.userId,
    email: user!.email,
    role: user!.role,
    tenantId: user!.tenantId,
    name: user!.name,
    driverId: user!.driverId,
    accessToken: access,
    refreshToken: refresh,
  );

  void logout() {
    _stopTripLoop();
    camera.stop();
    socket.disconnect();
    user = null;
    myVehicle = null;
    myTrips = [];
    myEvents = [];
    liveFeed = [];
    tripActive = false;
    onDuty = false;
    api.token = null;
    notifyListeners();
  }

  // ========================================================== data loads
  Future<void> _loadDriverContext() async {
    final t = user!.tenantId;
    try {
      // DRIVER role has vehicles.read → find the vehicle assigned to me.
      final vehiclesRaw = await api.get('/api/v1/tenants/$t/vehicles');
      final list = (vehiclesRaw as List)
          .map(
            (e) => VehicleRecord.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList();
      vehicles = list;
      final did = driverId;
      if (did != null) {
        for (final v in list) {
          if (v.driverId == did) {
            myVehicle = v;
            break;
          }
        }
      }
      myVehicle ??= list.isEmpty ? null : list.first;
    } catch (_) {}
    await refreshHistory();
    await refreshOperations();
    notifyListeners();
  }

  Future<void> refreshHistory() async {
    if (user == null) return;
    final t = user!.tenantId;
    try {
      final did = driverId;
      if (did != null) {
        final trips = await api.get(
          '/api/v1/tenants/$t/trips',
          query: {'driverId': did, 'limit': '20'},
        );
        myTrips = (trips as List)
            .map((e) => TripRecord.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      }
      final vid = myVehicle?.id;
      if (vid != null) {
        final events = await api.get(
          '/api/v1/tenants/$t/events',
          query: {'vehicleId': vid, 'limit': '30'},
        );
        myEvents = (events as List)
            .map(
              (e) => SafetyEventRecord.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> refreshOperations() async {
    if (user == null) return;
    final base = '/api/v1/tenants/${user!.tenantId}/driver-operations';
    try {
      final hos = await api.get('$base/hos');
      hosLogs = (hos as List)
          .map((e) => HosLog.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      final dvir = await api.get('$base/dvir');
      inspections = (dvir as List)
          .map(
            (e) => DvirInspection.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList();
    } catch (_) {}
    notifyListeners();
  }

  // ========================================================== trip engine
  void setOnDuty(bool value) {
    onDuty = value;
    _recordHos(value ? 'on_duty' : 'off_duty');
    notifyListeners();
  }

  Future<void> _recordHos(String status) async {
    if (user == null) return;
    try {
      await api.post(
        '/api/v1/tenants/${user!.tenantId}/driver-operations/hos',
        body: {
          'vehicleId': myVehicle?.id,
          'status': status,
          'note': 'Driver app status update',
        },
      );
      await refreshOperations();
    } catch (_) {}
  }

  Future<void> startTrip() async {
    if (tripActive || myVehicle == null) return;
    tripActive = true;
    _recordHos('driving');
    tripStart = DateTime.now();
    _tripId =
        'trip-${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(9999)}';
    _gps = GpsSimulator(
      startLat: myVehicle?.lat ?? 11.0168,
      startLon: myVehicle?.lon ?? 76.9558,
    );
    pointsSent = 0;
    batchesSent = 0;
    batchesAcked = 0;
    distanceKm = 0;
    maxSpeedKmh = 0;
    sosSent = false;
    lastIngestStatus = null;
    streaming = true;
    // Auto-enable cabin camera monitor for drowsiness detection.
    cameraEnabled = true;
    await _startCamera();
    // 1 Hz fix; one batch of 5 points every 5 s.
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  Future<void> setCameraEnabled(bool value) async {
    cameraEnabled = value;
    if (value && tripActive) {
      await _startCamera();
    } else if (!value) {
      camera.stop();
    }
    notifyListeners();
  }

  Future<void> _startCamera() async {
    if (camera.initialized) return;
    await camera.start();
    cameraLastError = camera.lastError;
  }

  void endTrip() {
    _flushBatch();
    _recordHos('on_duty');
    _stopTripLoop();
    camera.stop();
    tripActive = false;
    streaming = false;
    notifyListeners();
    refreshHistory();
  }

  void _stopTripLoop() {
    _tripTimer?.cancel();
    _tripTimer = null;
  }

  void _tick() {
    final gps = _gps;
    if (gps == null) return;
    final fix = gps.tick();
    gps.advanceTime();
    _pending.add(fix);
    lastSpeedKmh = (fix['spd'] as num).toDouble();
    lastLat = (fix['lat'] as num).toDouble();
    lastLon = (fix['lon'] as num).toDouble();
    if (lastSpeedKmh > maxSpeedKmh) maxSpeedKmh = lastSpeedKmh;
    distanceKm += lastSpeedKmh / 3.6 / 3600; // 1 s at speed
    pointsSent++;

    if (_pending.length >= 5) _flushBatch();
    notifyListeners();
  }

  Future<void> _flushBatch() async {
    if (_pending.isEmpty || user == null || myVehicle == null) return;
    final points = List<Map<String, dynamic>>.from(_pending);
    _pending.clear();
    final lastT = (points.last['t'] as num).toInt();
    final batch = {
      'schemaVersion': '1.2',
      'vehicleId': myVehicle!.id,
      'tripId': _tripId,
      'seq': socket.nextSeq(),
      'batchStart': DateTime.now()
          .toUtc()
          .subtract(Duration(seconds: lastT + 5))
          .toIso8601String(),
      'points': points,
    };
    batchesSent++;
    final ack = await socket.sendBatch(batch);
    lastIngestStatus = ack == null
        ? 'no-ack'
        : (ack['status']?.toString() ?? 'unknown');
    if (ack != null && ack['status'] == 'ok') batchesAcked++;
    notifyListeners();
  }

  // ========================================================== SOS
  Future<bool> sendSos() async {
    if (user == null || myVehicle == null || sosSent) return false;
    sosSent = true;
    final batch = <String, dynamic>{
      'schemaVersion': '1.2',
      'vehicleId': myVehicle!.id,
      'seq': socket.nextSeq(),
      'batchStart': DateTime.now().toUtc().toIso8601String(),
      'points': [
        {
          't': 0,
          'lat': tripActive ? lastLat : (myVehicle!.lat ?? 11.0168),
          'lon': tripActive ? lastLon : (myVehicle!.lon ?? 76.9558),
          'spd': tripActive ? lastSpeedKmh : 0,
          'hdg': 0,
          'acc': 0,
          'conf': 1,
        },
      ],
      'events': [
        {
          'type': 'sos',
          't': 0,
          'magnitude': 1.0,
          'conf': 1.0,
          'detail': 'SOS pressed by ${user!.name} in the driver app',
        },
      ],
    };
    if (tripActive) batch['tripId'] = _tripId;
    final ack = await socket.sendBatch(batch);
    notifyListeners();
    Timer(const Duration(seconds: 5), () {
      sosSent = false;
      notifyListeners();
    });
    return ack?['status'] == 'ok';
  }

  Future<String?> submitDvir({
    required String inspectionType,
    required List<Map<String, dynamic>> items,
    required bool safeToOperate,
  }) async {
    if (user == null || myVehicle == null) return 'No assigned vehicle';
    try {
      await api.post(
        '/api/v1/tenants/${user!.tenantId}/driver-operations/dvir',
        body: {
          'vehicleId': myVehicle!.id,
          'inspectionType': inspectionType,
          'safeToOperate': safeToOperate,
          'items': items,
        },
      );
      await refreshOperations();
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Inspection submission failed';
    }
  }

  Future<String?> submitWellness({
    required int fatigue,
    required int stress,
    required int hydration,
    String? note,
  }) async {
    if (user == null) return 'Not authenticated';
    try {
      await api.post(
        '/api/v1/tenants/${user!.tenantId}/driver-operations/wellness',
        body: {
          'fatigue': fatigue,
          'stress': stress,
          'hydration': hydration,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Wellness check-in failed';
    }
  }

  // ========================================================== live feed
  void _onLiveMessage(LiveMessage m) {
    if (m.event != 'live:event' &&
        m.event != 'live:alert' &&
        m.event != 'live:sos') {
      return;
    }
    final vId = m.data['vehicleId']?.toString();
    final mine = myVehicle?.id;
    if (vId != null && mine != null && vId != mine) return;
    liveFeed.insert(0, m);
    if (liveFeed.length > 50) liveFeed.removeLast();
    if (tripActive) refreshHistory();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTripLoop();
    socket.disconnect();
    api.dispose();
    super.dispose();
  }
}
