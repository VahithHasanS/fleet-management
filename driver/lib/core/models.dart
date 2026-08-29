/// Lightweight models mirroring the backend DTOs the driver app consumes.
library;

class AuthUser {
  final String userId;
  final String email;
  final String role;
  final String tenantId;
  final String name;
  final String? driverId;
  final String accessToken;
  final String refreshToken;

  AuthUser({
    required this.userId,
    required this.email,
    required this.role,
    required this.tenantId,
    required this.name,
    this.driverId,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthUser.fromResponse(Map<String, dynamic> j) {
    final u = j['user'] as Map<String, dynamic>? ?? const {};
    return AuthUser(
      userId: u['userId']?.toString() ?? '',
      email: u['email']?.toString() ?? '',
      role: u['role']?.toString() ?? '',
      tenantId: u['tenantId']?.toString() ?? '',
      name: u['name']?.toString() ?? '',
      driverId: u['driverId']?.toString(),
      accessToken: j['accessToken']?.toString() ?? '',
      refreshToken: j['refreshToken']?.toString() ?? '',
    );
  }
}

class VehicleRecord {
  final String id;
  final String name;
  final String plate;
  final String vehicleClass;
  final String? driverId;
  final String? fleetId;
  final double? lat;
  final double? lon;

  VehicleRecord({
    required this.id,
    required this.name,
    required this.plate,
    required this.vehicleClass,
    this.driverId,
    this.fleetId,
    this.lat,
    this.lon,
  });

  factory VehicleRecord.fromJson(Map<String, dynamic> j) => VehicleRecord(
    id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    plate: j['plate']?.toString() ?? '',
    vehicleClass: j['vehicleClass']?.toString() ?? 'car',
    driverId: j['driverId']?.toString(),
    fleetId: j['fleetId']?.toString(),
    lat: (j['lat'] as num?)?.toDouble(),
    lon: (j['lon'] as num?)?.toDouble(),
  );
}

class TripRecord {
  final String id;
  final String vehicleName;
  final String startTime;
  final String endTime;
  final int durationSec;
  final double distanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int totalScore;
  final int positivePoints;
  final int eventCount;
  final bool smoothTrip;

  TripRecord({
    required this.id,
    required this.vehicleName,
    required this.startTime,
    required this.endTime,
    required this.durationSec,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.totalScore,
    required this.positivePoints,
    required this.eventCount,
    required this.smoothTrip,
  });

  factory TripRecord.fromJson(Map<String, dynamic> j) => TripRecord(
    id: j['_id']?.toString() ?? j['tripId']?.toString() ?? '',
    vehicleName: j['vehicleName']?.toString() ?? '',
    startTime: j['startTime']?.toString() ?? '',
    endTime: j['endTime']?.toString() ?? '',
    durationSec: (j['durationSec'] as num?)?.toInt() ?? 0,
    distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
    avgSpeedKmh: (j['avgSpeedKmh'] as num?)?.toDouble() ?? 0,
    maxSpeedKmh: (j['maxSpeedKmh'] as num?)?.toDouble() ?? 0,
    totalScore: (j['totalScore'] as num?)?.toInt() ?? 0,
    positivePoints: (j['positivePoints'] as num?)?.toInt() ?? 0,
    eventCount: (j['eventCount'] as num?)?.toInt() ?? 0,
    smoothTrip: j['smoothTrip'] == true,
  );
}

class SafetyEventRecord {
  final String id;
  final String type;
  final String severity;
  final double magnitude;
  final double confidence;
  final String timestamp;
  final String? detail;

  SafetyEventRecord({
    required this.id,
    required this.type,
    required this.severity,
    required this.magnitude,
    required this.confidence,
    required this.timestamp,
    this.detail,
  });

  factory SafetyEventRecord.fromJson(Map<String, dynamic> j) =>
      SafetyEventRecord(
        id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        severity: j['severity']?.toString() ?? 'low',
        magnitude: (j['magnitude'] as num?)?.toDouble() ?? 0,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
        timestamp: j['timestamp']?.toString() ?? '',
        detail: j['detail']?.toString(),
      );
}

class HosLog {
  final String id;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? note;

  HosLog({
    required this.id,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.note,
  });

  factory HosLog.fromJson(Map<String, dynamic> j) => HosLog(
    id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
    status: j['status']?.toString() ?? 'off_duty',
    startedAt:
        DateTime.tryParse(j['startedAt']?.toString() ?? '') ?? DateTime.now(),
    endedAt: DateTime.tryParse(j['endedAt']?.toString() ?? ''),
    note: j['note']?.toString(),
  );
}

class DvirInspection {
  final String id;
  final String inspectionType;
  final bool safeToOperate;
  final DateTime submittedAt;
  final List<Map<String, dynamic>> items;

  DvirInspection({
    required this.id,
    required this.inspectionType,
    required this.safeToOperate,
    required this.submittedAt,
    required this.items,
  });

  factory DvirInspection.fromJson(Map<String, dynamic> j) => DvirInspection(
    id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
    inspectionType: j['inspectionType']?.toString() ?? 'pre_trip',
    safeToOperate: j['safeToOperate'] == true,
    submittedAt:
        DateTime.tryParse(j['submittedAt']?.toString() ?? '') ?? DateTime.now(),
    items: (j['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
  );
}
