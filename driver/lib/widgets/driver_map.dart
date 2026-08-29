import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

class DriverMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double speedKmh;
  final bool live;

  const DriverMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: point, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ghosttelemetry.driver',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 52,
                    height: 52,
                    child: _DriverPin(live: live),
                  ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                live ? 'LIVE LOCATION' : 'LAST KNOWN LOCATION',
                style: TextStyle(
                  color: live ? AppColors.green : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '${speedKmh.round()} km/h',
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverPin extends StatelessWidget {
  final bool live;
  const _DriverPin({required this.live});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: live ? AppColors.green : AppColors.accent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 7)],
        ),
        child: const Icon(Icons.navigation, color: Colors.white, size: 25),
      );
}
