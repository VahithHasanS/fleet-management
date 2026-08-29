import 'dart:math' as math;

/// Synthetic GPS source for the driver app demo loop.
///
/// On a real device this would be replaced by `geolocator` stream data. For
/// the demo (and Flutter Web where background GPS is unavailable) it walks a
/// vehicle along Coimbatore city roads at a plausible speed, occasionally
/// braking/accelerating hard so the backend scoring engine has events to
/// detect.
class GpsSimulator {
  final double seed;
  late final math.Random rng;

  double lat;
  double lon;
  double headingDeg = 0;
  double speedKmh = 0;
  double _accelG = 0;
  double _lateralG = 0;

  GpsSimulator({double? startLat, double? startLon, this.seed = 7})
      : lat = startLat ?? 11.0168,
        lon = startLon ?? 76.9558 {
    rng = math.Random(seed.toInt());
  }

  static const double _dtSec = 1.0; // 1 Hz fix

  /// Advances the simulation one tick and returns the new fix.
  Map<String, dynamic> tick() {
    // Desired speed wanders between 15 and 70 km/h.
    final target = 15 + 55 * (0.5 + 0.5 * math.sin(seed + _phase));
    _phase += 0.08 + rng.nextDouble() * 0.05;

    // Occasional harsh manoeuvres (~4% of ticks).
    _accelG = 0;
    _lateralG = 0;
    final roll = rng.nextDouble();
    if (roll < 0.02) {
      _accelG = -(0.45 + rng.nextDouble() * 0.25); // harsh brake
      speedKmh = (speedKmh - 25).clamp(0, 90).toDouble();
    } else if (roll < 0.04) {
      _accelG = 0.45 + rng.nextDouble() * 0.25; // harsh accel
      speedKmh = (speedKmh + 20).clamp(0, 90).toDouble();
    } else if (roll < 0.06) {
      _lateralG = 0.35 + rng.nextDouble() * 0.2; // harsh corner
      headingDeg += 35 * (rng.nextBool() ? 1 : -1);
    } else {
      speedKmh += (target - speedKmh) * 0.15;
      headingDeg += (rng.nextDouble() - 0.5) * 8;
    }
    headingDeg = (headingDeg % 360 + 360) % 360;

    // Move along heading.
    final vMs = speedKmh / 3.6;
    final dist = vMs * _dtSec; // metres
    const mPerDegLat = 111_320.0;
    final mPerDegLon = 111_320.0 * math.cos(lat * math.pi / 180);
    lat += (dist * math.cos(headingDeg * math.pi / 180)) / mPerDegLat;
    lon += (dist * math.sin(headingDeg * math.pi / 180)) / mPerDegLon;

    return {
      't': _t,
      'lat': _round(lat),
      'lon': _round(lon),
      'spd': _round(speedKmh),
      'hdg': _round(headingDeg),
      'acc': _round(_accelG),
      'la': _round(_lateralG),
      'conf': 0.95,
      '_dt': _dtSec,
    };
  }

  double _phase = 0;
  int _t = 0;

  void advanceTime() => _t += _dtSec.round();

  static double _round(double v) => (v * 10000).round() / 10000;
}
