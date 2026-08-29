import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/live_socket.dart';
import '../core/models.dart';

/// Central application state: authentication, cached domain entities, live
/// telemetry over the WebSocket and simulator control.
///
/// A single [AppState] instance is exposed via a `ChangeNotifierProvider`, and
/// every screen reads from it. Live socket events mutate the same collections
/// the REST endpoints populate, so the UI stays in sync automatically.
class AppState extends ChangeNotifier {
  AppState() {
    _api.onUnauthorized = _tryRefresh;
    _live.onMessage = _handleLiveMessage;
    _live.onConnectionChange = (c) {
      _wsConnected = c;
      notifyListeners();
    };
  }

  final ApiClient _api = ApiClient();
  final LiveSocket _live = LiveSocket();
  Timer? _pollTimer;

  // ---------------- auth ----------------
  AuthUser? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _busy = false;
  String? _error;
  bool _wsConnected = false;
  int _currentNavIndex = 0;

  AuthUser? get user => _user;
  String? get tenantId => _user?.tenantId;
  bool get busy => _busy;
  String? get error => _error;
  bool get wsConnected => _wsConnected;
  int get currentNavIndex => _currentNavIndex;

  void setNavIndex(int i) {
    _currentNavIndex = i;
    notifyListeners();
  }

  // ---------------- entities ----------------
  List<Vehicle> _vehicles = [];
  List<Driver> _drivers = [];
  List<Fleet> _fleets = [];
  List<Geofence> _geofences = [];
  List<Trip> _trips = [];
  List<SafetyEvent> _events = [];
  List<Alert> _alerts = [];
  List<LeaderboardEntry> _leaderboard = [];
  Stats _stats = Stats();
  SimulatorStatus _simulator = SimulatorStatus();
  List<Map<String, dynamic>> _driverHos = [];
  List<Map<String, dynamic>> _driverDvir = [];
  List<CameraBreach> _cameraBreaches = [];

  // ---------------- insights ----------------
  Map<String, dynamic> _reportSummary = {};
  Map<String, dynamic> _reportDaily = {};
  Map<String, dynamic> _predictiveRisks = {};
  Map<String, dynamic> _complianceSummary = {};
  Map<String, dynamic> _wellnessFleet = {};
  Map<String, dynamic> _routeOptimization = {};

  Map<String, dynamic> get reportSummary => _reportSummary;
  Map<String, dynamic> get reportDaily => _reportDaily;
  Map<String, dynamic> get predictiveRisks => _predictiveRisks;
  Map<String, dynamic> get complianceSummary => _complianceSummary;
  Map<String, dynamic> get wellnessFleet => _wellnessFleet;
  Map<String, dynamic> get routeOptimization => _routeOptimization;

  Future<void> fetchReportSummary({int days = 7}) async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get(
        '${AppConfig.tenantBase(t)}/insights/reports/summary',
        query: {'days': '$days'},
      );
      _reportSummary = Map<String, dynamic>.from(raw as Map);
      notifyListeners();
    } catch (e) {
      debugPrint('report summary failed: $e');
    }
  }

  Future<void> fetchReportDaily({int days = 7}) async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get(
        '${AppConfig.tenantBase(t)}/insights/reports/daily',
        query: {'days': '$days'},
      );
      _reportDaily = Map<String, dynamic>.from(raw as Map);
      notifyListeners();
    } catch (e) {
      debugPrint('report daily failed: $e');
    }
  }

  Future<void> fetchPredictiveRisks() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get(
        '${AppConfig.tenantBase(t)}/insights/predictive/risks',
      );
      _predictiveRisks = Map<String, dynamic>.from(raw as Map);
      notifyListeners();
    } catch (e) {
      debugPrint('predictive risks failed: $e');
    }
  }

  Future<void> fetchComplianceSummary() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get(
        '${AppConfig.tenantBase(t)}/insights/compliance/summary',
      );
      _complianceSummary = Map<String, dynamic>.from(raw as Map);
      notifyListeners();
    } catch (e) {
      debugPrint('compliance summary failed: $e');
    }
  }

  Future<void> fetchWellnessFleet() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get(
        '${AppConfig.tenantBase(t)}/insights/wellness/fleet',
      );
      _wellnessFleet = Map<String, dynamic>.from(raw as Map);
      notifyListeners();
    } catch (e) {
      debugPrint('wellness fleet failed: $e');
    }
  }

  Future<void> optimizeRoute(String vehicleId, List<String> stops) async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.post(
        '${AppConfig.tenantBase(t)}/insights/route/optimize',
        body: {'vehicleId': vehicleId, 'stops': stops},
      );
      _routeOptimization = Map<String, dynamic>.from(raw as Map);
      notifyListeners();
    } catch (e) {
      debugPrint('route optimize failed: $e');
    }
  }

  /// Most recent live frame from a subscribed driver's cabin camera.
  String? _videoFrameB64;
  String? _videoFrameVehicleId;
  DateTime? _videoFrameAt;
  DateTime? _lastBreachAt;
  String? _lastBreachType;
  String? _lastBreachVehicle;

  // Live positions keyed by vehicleId (replaces REST snapshot when present).

  final Map<String, LiveSnapshot> _livePositions = {};

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  List<Driver> get drivers => List.unmodifiable(_drivers);
  List<Fleet> get fleets => List.unmodifiable(_fleets);
  List<Geofence> get geofences => List.unmodifiable(_geofences);
  List<Trip> get trips => List.unmodifiable(_trips);
  List<SafetyEvent> get events => List.unmodifiable(_events);
  List<Alert> get alerts => List.unmodifiable(_alerts);
  List<LeaderboardEntry> get leaderboard => List.unmodifiable(_leaderboard);
  Stats get stats => _stats;
  SimulatorStatus get simulator => _simulator;
  List<Map<String, dynamic>> get driverHos => List.unmodifiable(_driverHos);
  List<Map<String, dynamic>> get driverDvir => List.unmodifiable(_driverDvir);

  List<CameraBreach> get cameraBreaches => List.unmodifiable(_cameraBreaches);
  List<CameraBreach> get breaches => List.unmodifiable(_cameraBreaches);

  void _insertBreach(CameraBreach b, Map<String, dynamic> raw) {
    _cameraBreaches = [b, ..._cameraBreaches.where((x) => x.id != b.id)];
    if (_cameraBreaches.length > 200)
      _cameraBreaches = _cameraBreaches.sublist(0, 200);
    // Surface the camera breach as a persistent alert so the badge/alerts log
    // stays consistent (the breach payload is not an Alert-shaped document).
    final alert = Alert(
      id: 'breach-${b.id}',
      type: 'camera_breach',
      severity: b.severity,
      message: 'Camera AI: ${b.breachType} on ${b.vehicleName ?? b.vehicleId}',
      timestamp: b.timestamp,
      vehicleId: b.vehicleId,
      vehicleName: b.vehicleName,
      driverName: b.driverName,
      read: false,
    );
    _alerts = [alert, ..._alerts.where((a) => a.id != alert.id)];
  }

  String? get videoFrameB64 => _videoFrameB64;
  String? get videoFrameVehicleId => _videoFrameVehicleId;
  DateTime? get videoFrameAt => _videoFrameAt;
  DateTime? get lastBreachAt => _lastBreachAt;
  String? get lastBreachType => _lastBreachType;
  String? get lastBreachVehicle => _lastBreachVehicle;

  Future<void> fetchCameraBreaches({String? vehicleId}) async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get(
        '${AppConfig.tenantBase(t)}/video/breaches',
        query: vehicleId != null ? {'vehicleId': vehicleId} : null,
      );
      _cameraBreaches = (raw as List)
          .map(
            (e) => CameraBreach.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('camera breaches fetch failed: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchVideoStats() async {
    final t = tenantId;
    if (t == null) return null;
    try {
      final raw = await _api.get('${AppConfig.tenantBase(t)}/video/stats');
      return Map<String, dynamic>.from(raw as Map);
    } catch (e) {
      debugPrint('video stats failed: $e');
      return null;
    }
  }

  /// Admin opts into the per-tenant cabin-camera frame stream.
  void subscribeToVideoFeed() {
    if (_accessToken == null) return;
    _live.emit('video:subscribe', {'tenantId': tenantId ?? ''});
  }

  Vehicle? vehicleById(String id) {
    for (final v in _vehicles) {
      if (v.id == id) return v;
    }
    return null;
  }

  LiveSnapshot? livePosition(String? id) =>
      id == null ? null : _livePositions[id];

  /// All vehicle positions to plot on the map: live position first, then the
  /// REST snapshot.
  List<
    ({
      String id,
      String name,
      String plate,
      String status,
      double lat,
      double lon,
      double speed,
      double heading,
      String? driver,
    })
  >
  get mapPoints {
    final out =
        <
          ({
            String id,
            String name,
            String plate,
            String status,
            double lat,
            double lon,
            double speed,
            double heading,
            String? driver,
          })
        >[];
    for (final v in _vehicles) {
      final live = _livePositions[v.id];
      if (live != null) {
        out.add((
          id: v.id,
          name: live.name,
          plate: live.plate,
          status: live.status,
          lat: live.lat,
          lon: live.lon,
          speed: live.speedKmh,
          heading: live.heading,
          driver: live.driverName,
        ));
      } else if (v.lat != null && v.lon != null) {
        out.add((
          id: v.id,
          name: v.name,
          plate: v.plate,
          status: v.status,
          lat: v.lat!,
          lon: v.lon!,
          speed: v.speedKmh,
          heading: v.heading,
          driver: v.driver?.name,
        ));
      }
    }
    return out;
  }

  Future<bool> login(String email, String password) async {
    _setBusy(true);
    _error = null;
    try {
      final raw = await _api.post(
        '/api/v1/auth/login',
        body: {'email': email, 'password': password},
      );
      final result = LoginResult.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      await _applySession(result);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e is ApiException ? e.message : 'Login failed';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _applySession(LoginResult result) async {
    _user = result.user;
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _api.token = _accessToken;
    await _bootstrap();
    // Pull persisted camera breaches and opt into the live cabin-feed stream.
    await fetchCameraBreaches();
    subscribeToVideoFeed();
  }

  Future<String?> _tryRefresh() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return null;
    try {
      final raw = await _api.post(
        '/api/v1/auth/refresh',
        body: {'refreshToken': _refreshToken},
        retryOnUnauthorized: false,
      );
      final result = LoginResult.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      _accessToken = result.accessToken;
      _refreshToken = result.refreshToken;
      _api.token = _accessToken;
      return _accessToken;
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    _stopPolling();
    _live.disconnect();
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _api.token = null;
    _vehicles = [];
    _drivers = [];
    _fleets = [];
    _geofences = [];
    _trips = [];
    _events = [];
    _alerts = [];
    _leaderboard = [];
    _livePositions.clear();
    _cameraBreaches = [];
    _videoFrameB64 = null;
    _lastBreachAt = null;
    _stats = Stats();
    _simulator = SimulatorStatus();
    _currentNavIndex = 0;
    notifyListeners();
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  // ---------------- web socket ----------------
  void _startLive() {
    if (_accessToken == null) return;
    _live.connect(token: _accessToken!, tenantId: tenantId);
    _startPolling();
  }

  void _handleLiveMessage(LiveMessage msg) {
    switch (msg.event) {
      case 'live:position':
        final id = msg.data['vehicleId'] as String? ?? '';
        if (id.isNotEmpty) _livePositions[id] = LiveSnapshot.fromJson(msg.data);
        break;
      case 'live:alert':
        final alert = Alert.fromJson(msg.data);
        _alerts = [alert, ..._alerts.where((a) => a.id != alert.id)];
        if (_alerts.length > 200) _alerts = _alerts.sublist(0, 200);
        break;
      case 'live:event':
        final e = SafetyEvent.fromJson(msg.data);
        _events = [e, ..._events.where((ev) => ev.id != e.id)];
        if (_events.length > 200) _events = _events.sublist(0, 200);
        break;
      case 'live:leaderboard':
        final list = (msg.data['leaderboard'] as List? ?? [])
            .map(
              (e) => LeaderboardEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
        if (list.isNotEmpty) _leaderboard = list;
        break;
      case 'simulator:status':
        _simulator = SimulatorStatus.fromJson(msg.data);
        break;
      case 'live:sos':
        final id = msg.data['vehicleId'] as String? ?? '';
        if (id.isNotEmpty) _livePositions[id] = LiveSnapshot.fromJson(msg.data);
        _events = [
          SafetyEvent(
            id: 'sos-${DateTime.now().millisecondsSinceEpoch}',
            type: 'sos',
            severity: 'critical',
            timestamp: DateTime.now(),
            vehicleId: id,
          ),
          ..._events,
        ];
        break;
      case 'live:video_breach':
        final b = CameraBreach.fromJson(Map<String, dynamic>.from(msg.data));
        _insertBreach(b, msg.data);
        _lastBreachAt = b.timestamp;
        _lastBreachType = b.breachType;
        _lastBreachVehicle = b.vehicleName ?? b.vehicleId;
        notifyListeners();
        break;
      case 'video:frame':
        // Live cabin frame relayed from a subscribed driver.
        _videoFrameB64 = msg.data['jpg'] as String?;
        _videoFrameVehicleId = msg.data['vehicleId'] as String?;
        _videoFrameAt = msg.data['ts'] != null
            ? DateTime.fromMillisecondsSinceEpoch(msg.data['ts'] as int)
            : DateTime.now();
        notifyListeners();
        break;
      case 'live:trip':
        _scheduleTripRefresh();
        break;
    }
    notifyListeners();
  }

  Timer? _tripRefreshTimer;
  void _scheduleTripRefresh() {
    _tripRefreshTimer?.cancel();
    _tripRefreshTimer = Timer(const Duration(seconds: 1), () async {
      await fetchTrips();
    });
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(refreshLight());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _tripRefreshTimer?.cancel();
  }

  // ---------------- bootstrap & fetch ----------------
  Future<void> _bootstrap() async {
    _startLive();
    await Future.wait([
      fetchVehicles(),
      fetchDrivers(),
      fetchFleets(),
      fetchGeofences(),
      fetchLeaderboard(),
      fetchStats(),
      fetchSimulatorStatus(),
    ]);
    unawaited(fetchTrips());
    unawaited(fetchEvents());
    unawaited(fetchAlerts());
    unawaited(fetchCameraBreaches());
  }

  Future<void> refreshAll() async {
    await _bootstrap();
  }

  /// Lightweight periodic refresh (stats + vehicles + simulator status).
  Future<void> refreshLight() async {
    await Future.wait([fetchStats(), fetchVehicles(), fetchSimulatorStatus()]);
  }

  Future<void> fetchVehicles() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get('${AppConfig.tenantBase(t)}/vehicles');
      _vehicles = (raw as List)
          .map((e) => Vehicle.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchVehicles failed: $e');
    }
  }

  Future<void> fetchDrivers() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get('${AppConfig.tenantBase(t)}/drivers');
      _drivers = (raw as List)
          .map((e) => Driver.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchDrivers failed: $e');
    }
  }

  Future<void> fetchFleets() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get('${AppConfig.tenantBase(t)}/fleets');
      _fleets = (raw as List)
          .map((e) => Fleet.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchFleets failed: $e');
    }
  }

  Future<void> fetchGeofences() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get('${AppConfig.tenantBase(t)}/geofences');
      _geofences = (raw as List)
          .map((e) => Geofence.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchGeofences failed: $e');
    }
  }

  Future<void> fetchTrips() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get(
        '${AppConfig.tenantBase(t)}/trips',
        query: {'limit': '50'},
      );
      _trips = (raw as List)
          .map((e) => Trip.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchTrips failed: $e');
    }
  }

  Future<void> fetchEvents() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get(
        '${AppConfig.tenantBase(t)}/events',
        query: {'limit': '100'},
      );
      _events = (raw as List)
          .map((e) => SafetyEvent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchEvents failed: $e');
    }
  }

  Future<void> fetchAlerts() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get(
        '${AppConfig.tenantBase(t)}/alerts',
        query: {'limit': '100'},
      );
      _alerts = (raw as List)
          .map((e) => Alert.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchAlerts failed: $e');
    }
  }

  Future<void> fetchLeaderboard() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get('${AppConfig.tenantBase(t)}/leaderboard');
      _leaderboard = (raw as List)
          .map(
            (e) =>
                LeaderboardEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchLeaderboard failed: $e');
    }
  }

  Future<void> fetchStats() async {
    final t = tenantId;
    if (t == null) return;
    try {
      final raw = await _api.get('${AppConfig.tenantBase(t)}/stats');
      _stats = Stats.fromJson(Map<String, dynamic>.from(raw as Map));
      notifyListeners();
    } catch (e) {
      debugPrint('fetchStats failed: $e');
    }
  }

  Future<void> fetchDriverOperations(String driverId) async {
    final t = tenantId;
    if (t == null || driverId.isEmpty) return;
    try {
      final base = '${AppConfig.tenantBase(t)}/driver-operations';
      final hos = await _api.get('$base/hos', query: {'driverId': driverId});
      final dvir = await _api.get('$base/dvir', query: {'driverId': driverId});
      _driverHos = (hos as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _driverDvir = (dvir as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('driver operations failed: $e');
    }
  }

  // ---------------- write operations ----------------
  Future<String?> createVehicle(Map<String, dynamic> body) async {
    final t = tenantId;
    if (t == null) return 'Not authenticated';
    try {
      await _api.post('${AppConfig.tenantBase(t)}/vehicles', body: body);
      await fetchVehicles();
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Create failed';
    }
  }

  Future<String?> updateVehicle(String id, Map<String, dynamic> body) async {
    final t = tenantId;
    if (t == null) return 'Not authenticated';
    try {
      await _api.patch('${AppConfig.tenantBase(t)}/vehicles/$id', body: body);
      await fetchVehicles();
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Update failed';
    }
  }

  Future<String?> deleteVehicle(String id) async {
    final t = tenantId;
    if (t == null) return 'Not authenticated';
    try {
      await _api.delete('${AppConfig.tenantBase(t)}/vehicles/$id');
      _livePositions.remove(id);
      await fetchVehicles();
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Delete failed';
    }
  }

  Future<String?> createDriver(Map<String, dynamic> body) async {
    final t = tenantId;
    if (t == null) return 'Not authenticated';
    try {
      await _api.post('${AppConfig.tenantBase(t)}/drivers', body: body);
      await fetchDrivers();
      await fetchLeaderboard();
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Create failed';
    }
  }

  Future<String?> createFleet(Map<String, dynamic> body) async {
    final t = tenantId;
    if (t == null) return 'Not authenticated';
    try {
      await _api.post('${AppConfig.tenantBase(t)}/fleets', body: body);
      await fetchFleets();
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Create failed';
    }
  }

  Future<String?> createGeofence(Map<String, dynamic> body) async {
    final t = tenantId;
    if (t == null) return 'Not authenticated';
    try {
      await _api.post('${AppConfig.tenantBase(t)}/geofences', body: body);
      await fetchGeofences();
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Create failed';
    }
  }

  Future<String?> deleteGeofence(String id) async {
    final t = tenantId;
    if (t == null) return 'Not authenticated';
    try {
      await _api.delete('${AppConfig.tenantBase(t)}/geofences/$id');
      await fetchGeofences();
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Delete failed';
    }
  }

  Future<String?> acknowledgeAlert(String id) async {
    final t = tenantId;
    if (t == null) return 'Not authenticated';
    try {
      await _api.patch('${AppConfig.tenantBase(t)}/alerts/$id/read');
      _alerts = [
        for (final a in _alerts)
          if (a.id == id) Alert.fromJson({..._toMap(a), 'read': true}) else a,
      ];
      notifyListeners();
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Ack failed';
    }
  }

  // ---------------- simulator ----------------
  Future<SimulatorStatus> fetchSimulatorStatus() async {
    try {
      final raw = await _api.get('/api/v1/simulator/status');
      _simulator = SimulatorStatus.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('simulator status failed: $e');
    }
    return _simulator;
  }

  Future<String?> simulatorControl(String action) async {
    try {
      final raw = await _api.post('/api/v1/simulator/$action');
      _simulator = SimulatorStatus.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      notifyListeners();
      await refreshAll();
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Simulator action failed';
    }
  }

  Future<String?> triggerEvent(String vehicleId, String type) async {
    try {
      await _api.post(
        '/api/v1/simulator/vehicles/$vehicleId/event',
        body: {'type': type},
      );
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Trigger failed';
    }
  }

  Map<String, dynamic> _toMap(Alert a) => {
    'id': a.id,
    'type': a.type,
    'severity': a.severity,
    'message': a.message,
    'timestamp': a.timestamp.toIso8601String(),
    if (a.vehicleId != null) 'vehicleId': a.vehicleId,
    if (a.vehicleName != null) 'vehicleName': a.vehicleName,
    if (a.driverName != null) 'driverName': a.driverName,
    'read': a.read,
    if (a.lat != null) 'lat': a.lat,
    if (a.lon != null) 'lon': a.lon,
  };
}
