class Alert {
  final String id;
  final String type;
  final String severity;
  final String message;
  final DateTime timestamp;
  final String? vehicleId;
  final String? vehicleName;
  final String? driverName;
  final bool read;
  final double? lat;
  final double? lon;

  Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.vehicleId,
    this.vehicleName,
    this.driverName,
    this.read = false,
    this.lat,
    this.lon,
  });

  factory Alert.fromJson(Map<String, dynamic> j) => Alert(
    id: j['id'] as String? ?? '',
    type: j['type'] as String? ?? 'unknown',
    severity: j['severity'] as String? ?? 'low',
    message: j['message'] as String? ?? '',
    timestamp: DateTime.parse(
      j['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    ),
    vehicleId: j['vehicleId'] as String?,
    vehicleName: j['vehicleName'] as String?,
    driverName: j['driverName'] as String?,
    read: j['read'] as bool? ?? false,
    lat: (j['lat'] as num?)?.toDouble(),
    lon: (j['lon'] as num?)?.toDouble(),
  );
}

class LeaderboardEntry {
  final int rank;
  final String id;
  final String name;
  final String? fleetId;
  final double safetyScore;
  final int positivePoints;
  final int tripsCount;
  final String? avatarColor;

  LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.name,
    this.fleetId,
    this.safetyScore = 100,
    this.positivePoints = 0,
    this.tripsCount = 0,
    this.avatarColor,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    rank: (j['rank'] as num?)?.toInt() ?? 0,
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    fleetId: j['fleetId'] as String?,
    safetyScore: (j['safetyScore'] as num?)?.toDouble() ?? 100,
    positivePoints: (j['positivePoints'] as num?)?.toInt() ?? 0,
    tripsCount: (j['tripsCount'] as num?)?.toInt() ?? 0,
    avatarColor: j['avatarColor'] as String?,
  );
}

class Stats {
  final int totalVehicles;
  final int onlineVehicles;
  final int inTransit;
  final int offlineVehicles;
  final int alertsToday;
  final int eventsToday;
  final int tripsToday;
  final double avgDriverScore;

  Stats({
    this.totalVehicles = 0,
    this.onlineVehicles = 0,
    this.inTransit = 0,
    this.offlineVehicles = 0,
    this.alertsToday = 0,
    this.eventsToday = 0,
    this.tripsToday = 0,
    this.avgDriverScore = 100,
  });

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
    totalVehicles: (j['totalVehicles'] as num?)?.toInt() ?? 0,
    onlineVehicles: (j['onlineVehicles'] as num?)?.toInt() ?? 0,
    inTransit: (j['inTransit'] as num?)?.toInt() ?? 0,
    offlineVehicles: (j['offlineVehicles'] as num?)?.toInt() ?? 0,
    alertsToday: (j['alertsToday'] as num?)?.toInt() ?? 0,
    eventsToday: (j['eventsToday'] as num?)?.toInt() ?? 0,
    tripsToday: (j['tripsToday'] as num?)?.toInt() ?? 0,
    avgDriverScore: (j['avgDriverScore'] as num?)?.toDouble() ?? 100,
  );
}

class SimulatorStatus {
  final bool running;
  final int vehicles;
  final int pointsPerBatch;
  final int intervalMs;
  final DateTime startedAt;
  final int emittedBatches;
  final int emittedEvents;

  SimulatorStatus({
    this.running = false,
    this.vehicles = 0,
    this.pointsPerBatch = 0,
    this.intervalMs = 0,
    DateTime? startedAt,
    this.emittedBatches = 0,
    this.emittedEvents = 0,
  }) : startedAt = startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  factory SimulatorStatus.fromJson(Map<String, dynamic> j) => SimulatorStatus(
    running: j['running'] as bool? ?? false,
    vehicles: (j['vehicles'] as num?)?.toInt() ?? 0,
    pointsPerBatch: (j['pointsPerBatch'] as num?)?.toInt() ?? 0,
    intervalMs: (j['intervalMs'] as num?)?.toInt() ?? 0,
    startedAt: j['startedAt'] != null
        ? DateTime.tryParse(j['startedAt'] as String) ??
              DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.fromMillisecondsSinceEpoch(0),
    emittedBatches: (j['emittedBatches'] as num?)?.toInt() ?? 0,
    emittedEvents: (j['emittedEvents'] as num?)?.toInt() ?? 0,
  );
}

/// A live vehicle position pushed over the WebSocket (VehicleSnapshot).
class LiveSnapshot {
  final String vehicleId;
  final String name;
  final String plate;
  final String vehicleClass;
  final String? driverName;
  final double lat;
  final double lon;
  final double speedKmh;
  final double heading;
  final String status;
  final int lastSeen;

  LiveSnapshot({
    required this.vehicleId,
    required this.name,
    required this.plate,
    required this.vehicleClass,
    this.driverName,
    required this.lat,
    required this.lon,
    this.speedKmh = 0,
    this.heading = 0,
    this.status = 'online',
    this.lastSeen = 0,
  });

  factory LiveSnapshot.fromJson(Map<String, dynamic> j) => LiveSnapshot(
    vehicleId: j['vehicleId'] as String? ?? '',
    name: j['name'] as String? ?? '',
    plate: j['plate'] as String? ?? '',
    vehicleClass: j['vehicleClass'] as String? ?? 'car',
    driverName: j['driverName'] as String?,
    lat: (j['lat'] as num?)?.toDouble() ?? 0,
    lon: (j['lon'] as num?)?.toDouble() ?? 0,
    speedKmh: (j['speedKmh'] as num?)?.toDouble() ?? 0,
    heading: (j['heading'] as num?)?.toDouble() ?? 0,
    status: j['status'] as String? ?? 'online',
    lastSeen: (j['lastSeen'] as num?)?.toInt() ?? 0,
  );
}

/// Data models mirroring the Ghost Telemetry backend API contract.
///
/// Field names intentionally match the JSON returned by the NestJS services so
/// Dart JSON decoding is a thin, explicit layer.

class AuthUser {
  final String userId;
  final String email;
  final String role;
  final String? tenantId;
  final String? name;
  final String? driverId;

  AuthUser({
    required this.userId,
    required this.email,
    required this.role,
    this.tenantId,
    this.name,
    this.driverId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    userId: j['userId'] as String? ?? '',
    email: j['email'] as String? ?? '',
    role: j['role'] as String? ?? 'DRIVER',
    tenantId: j['tenantId'] as String?,
    name: j['name'] as String?,
    driverId: j['driverId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'role': role,
    if (tenantId != null) 'tenantId': tenantId,
    if (name != null) 'name': name,
    if (driverId != null) 'driverId': driverId,
  };

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isManager => role == 'FLEET_MANAGER';
}

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AuthUser user;

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> j) => LoginResult(
    accessToken: j['accessToken'] as String? ?? '',
    refreshToken: j['refreshToken'] as String? ?? '',
    expiresIn: (j['expiresIn'] as num?)?.toInt() ?? 900,
    user: AuthUser.fromJson((j['user'] as Map<String, dynamic>?) ?? {}),
  );
}

class DriverRef {
  final String id;
  final String name;
  DriverRef({required this.id, required this.name});
  factory DriverRef.fromJson(Map<String, dynamic> j) =>
      DriverRef(id: j['id'] as String? ?? '', name: j['name'] as String? ?? '');
}

class Vehicle {
  final String id;
  final String? fleetId;
  final String name;
  final String plate;
  final String vehicleClass;
  final int? speedLimitKmh;
  final DriverRef? driver;
  final String status;
  final double? lat;
  final double? lon;
  final double speedKmh;
  final double heading;
  final int lastSeen;

  Vehicle({
    required this.id,
    this.fleetId,
    required this.name,
    required this.plate,
    required this.vehicleClass,
    this.speedLimitKmh,
    this.driver,
    required this.status,
    this.lat,
    this.lon,
    this.speedKmh = 0,
    this.heading = 0,
    this.lastSeen = 0,
  });

  factory Vehicle.fromJson(Map<String, dynamic> j) {
    final driverJson = j['driver'];
    return Vehicle(
      id: j['id'] as String? ?? '',
      fleetId: j['fleetId'] as String?,
      name: j['name'] as String? ?? '',
      plate: j['plate'] as String? ?? '',
      vehicleClass: j['vehicleClass'] as String? ?? 'car',
      speedLimitKmh: (j['speedLimitKmh'] as num?)?.toInt(),
      driver: driverJson is Map<String, dynamic>
          ? DriverRef.fromJson(driverJson)
          : null,
      status: j['status'] as String? ?? 'offline',
      lat: (j['lat'] as num?)?.toDouble(),
      lon: (j['lon'] as num?)?.toDouble(),
      speedKmh: (j['speedKmh'] as num?)?.toDouble() ?? 0,
      heading: (j['heading'] as num?)?.toDouble() ?? 0,
      lastSeen: (j['lastSeen'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isOnline =>
      DateTime.now().millisecondsSinceEpoch - lastSeen < 120000 ||
      status == 'in_transit' ||
      status == 'online';
}

class Driver {
  final String id;
  final String? fleetId;
  final String name;
  final String? phone;
  final String? email;
  final String? avatarColor;
  final double safetyScore;
  final int positivePoints;
  final int tripsCount;
  final String? status;

  Driver({
    required this.id,
    this.fleetId,
    required this.name,
    this.phone,
    this.email,
    this.avatarColor,
    this.safetyScore = 100,
    this.positivePoints = 0,
    this.tripsCount = 0,
    this.status = 'on_duty',
  });

  factory Driver.fromJson(Map<String, dynamic> j) => Driver(
    id: j['id'] as String? ?? '',
    fleetId: j['fleetId'] as String?,
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String?,
    email: j['email'] as String?,
    avatarColor: j['avatarColor'] as String?,
    safetyScore: (j['safetyScore'] as num?)?.toDouble() ?? 100,
    positivePoints: (j['positivePoints'] as num?)?.toInt() ?? 0,
    tripsCount: (j['tripsCount'] as num?)?.toInt() ?? 0,
    status: j['status'] as String? ?? 'on_duty',
  );
}

class Fleet {
  final String id;
  final String name;
  final String? city;
  final int vehicleCount;
  Fleet({
    required this.id,
    required this.name,
    this.city,
    this.vehicleCount = 0,
  });
  factory Fleet.fromJson(Map<String, dynamic> j) => Fleet(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    city: j['city'] as String?,
    vehicleCount: (j['vehicleCount'] as num?)?.toInt() ?? 0,
  );
}

class Geofence {
  final String id;
  final String name;
  final double centerLat;
  final double centerLon;
  final int radiusM;
  final String? color;
  Geofence({
    required this.id,
    required this.name,
    required this.centerLat,
    required this.centerLon,
    required this.radiusM,
    this.color,
  });
  factory Geofence.fromJson(Map<String, dynamic> j) => Geofence(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    centerLat: (j['centerLat'] as num?)?.toDouble() ?? 0,
    centerLon: (j['centerLon'] as num?)?.toDouble() ?? 0,
    radiusM: (j['radiusM'] as num?)?.toInt() ?? 500,
    color: j['color'] as String?,
  );
}

class Trip {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final String? driverId;
  final String? driverName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSec;
  final double distanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double totalScore;
  final int positivePoints;
  final int eventCount;
  final bool smoothTrip;

  Trip({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    this.driverId,
    this.driverName,
    required this.startTime,
    this.endTime,
    this.durationSec = 0,
    this.distanceKm = 0,
    this.avgSpeedKmh = 0,
    this.maxSpeedKmh = 0,
    this.totalScore = 100,
    this.positivePoints = 0,
    this.eventCount = 0,
    this.smoothTrip = false,
  });

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
    id: j['id'] as String? ?? '',
    vehicleId: j['vehicleId'] as String? ?? '',
    vehicleName: j['vehicleName'] as String? ?? '',
    driverId: j['driverId'] as String?,
    driverName: j['driverName'] as String?,
    startTime: DateTime.parse(
      j['startTime'] as String? ?? DateTime.now().toIso8601String(),
    ),
    endTime: j['endTime'] != null
        ? DateTime.tryParse(j['endTime'] as String)
        : null,
    durationSec: (j['durationSec'] as num?)?.toInt() ?? 0,
    distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
    avgSpeedKmh: (j['avgSpeedKmh'] as num?)?.toDouble() ?? 0,
    maxSpeedKmh: (j['maxSpeedKmh'] as num?)?.toDouble() ?? 0,
    totalScore: (j['totalScore'] as num?)?.toDouble() ?? 100,
    positivePoints: (j['positivePoints'] as num?)?.toInt() ?? 0,
    eventCount: (j['eventCount'] as num?)?.toInt() ?? 0,
    smoothTrip: j['smoothTrip'] as bool? ?? false,
  );
}

class SafetyEvent {
  final String id;
  final String type;
  final String severity;
  final double magnitude;
  final double confidence;
  final DateTime timestamp;
  final String vehicleId;
  final String? vehicleName;
  final String? driverId;
  final double? lat;
  final double? lon;
  final String? detail;
  final bool acknowledged;

  SafetyEvent({
    required this.id,
    required this.type,
    required this.severity,
    this.magnitude = 0,
    this.confidence = 0,
    required this.timestamp,
    required this.vehicleId,
    this.vehicleName,
    this.driverId,
    this.lat,
    this.lon,
    this.detail,
    this.acknowledged = false,
  });

  factory SafetyEvent.fromJson(Map<String, dynamic> j) => SafetyEvent(
    id: j['id'] as String? ?? '',
    type: j['type'] as String? ?? 'unknown',
    severity: j['severity'] as String? ?? 'low',
    magnitude: (j['magnitude'] as num?)?.toDouble() ?? 0,
    confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
    timestamp: DateTime.parse(
      j['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    ),
    vehicleId: j['vehicleId'] as String? ?? '',
    vehicleName: j['vehicleName'] as String?,
    driverId: j['driverId'] as String?,
    lat: (j['lat'] as num?)?.toDouble(),
    lon: (j['lon'] as num?)?.toDouble(),
    detail: j['detail'] as String?,
    acknowledged: j['acknowledged'] as bool? ?? false,
  );
}

/// A camera-AI driver-monitoring breach persisted by the backend.
class CameraBreach {
  final String id;
  final String vehicleId;
  final String? vehicleName;
  final String? driverId;
  final String? driverName;
  final String breachType;
  final String severity;
  final DateTime timestamp;
  final int durationMs;
  final double confidence;
  final double? ear;
  final String? snapshot; // base64 JPEG (thumbnail) — large; handle carefully.
  final String? detail;

  CameraBreach({
    required this.id,
    required this.vehicleId,
    this.vehicleName,
    this.driverId,
    this.driverName,
    required this.breachType,
    required this.severity,
    required this.timestamp,
    this.durationMs = 0,
    this.confidence = 0.5,
    this.ear,
    this.snapshot,
    this.detail,
  });

  factory CameraBreach.fromJson(Map<String, dynamic> j) => CameraBreach(
    id: j['id'] as String? ?? '',
    vehicleId: j['vehicleId'] as String? ?? '',
    vehicleName: j['vehicleName'] as String?,
    driverId: j['driverId'] as String?,
    driverName: j['driverName'] as String?,
    breachType: j['breachType'] as String? ?? 'unknown',
    severity: j['severity'] as String? ?? 'medium',
    timestamp: DateTime.parse(
      j['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    ),
    durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
    confidence: (j['confidence'] as num?)?.toDouble() ?? 0.5,
    ear: (j['ear'] as num?)?.toDouble(),
    snapshot: j['snapshot'] as String?,
    detail: j['detail'] as String?,
  );
}
