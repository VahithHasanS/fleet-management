import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

class MapMarker {
  final String id;
  final String name;
  final String plate;
  final String status;
  final double lat;
  final double lon;
  final double speedKmh;
  final double heading;
  final String? driver;

  MapMarker({
    required this.id,
    required this.name,
    required this.plate,
    required this.status,
    required this.lat,
    required this.lon,
    this.speedKmh = 0,
    this.heading = 0,
    this.driver,
  });

  factory MapMarker.fromRecord(
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
    r,
  ) => MapMarker(
    id: r.id,
    name: r.name,
    plate: r.plate,
    status: r.status,
    lat: r.lat,
    lon: r.lon,
    speedKmh: r.speed,
    heading: r.heading,
    driver: r.driver,
  );
}

class CustomMap extends StatelessWidget {
  final List<MapMarker> markers;
  final List<
    ({
      String name,
      double centerLat,
      double centerLon,
      int radiusM,
      Color color,
    })
  >
  geofences;
  final ValueChanged<MapMarker>? onMarkerTap;
  final bool showLegend;
  final String? selectedMarkerId;

  const CustomMap({
    super.key,
    this.markers = const [],
    this.geofences = const [],
    this.onMarkerTap,
    this.showLegend = true,
    this.selectedMarkerId,
  });

  @override
  Widget build(BuildContext context) {
    final center = markers.isNotEmpty
        ? LatLng(markers.first.lat, markers.first.lon)
        : const LatLng(11.0168, 76.9558);
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: markers.isEmpty ? 12 : 11.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ghosttelemetry.admin',
              maxZoom: 19,
            ),
            CircleLayer(
              circles: [
                for (final geofence in geofences)
                  CircleMarker(
                    point: LatLng(geofence.centerLat, geofence.centerLon),
                    radius: geofence.radiusM.toDouble(),
                    useRadiusInMeter: true,
                    color: geofence.color.withValues(alpha: 0.16),
                    borderColor: geofence.color,
                    borderStrokeWidth: 2,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final marker in markers)
                  Marker(
                    point: LatLng(marker.lat, marker.lon),
                    width: selectedMarkerId == marker.id ? 150 : 120,
                    height: 76,
                    child: GestureDetector(
                      onTap: onMarkerTap == null
                          ? null
                          : () => onMarkerTap!(marker),
                      child: _VehiclePin(
                        marker: marker,
                        selected: selectedMarkerId == marker.id,
                      ),
                    ),
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
        if (showLegend)
          const Positioned(left: 12, top: 12, child: _MapLegend()),
        if (markers.isEmpty)
          const Positioned.fill(
            child: IgnorePointer(child: Center(child: _EmptyMapMessage())),
          ),
      ],
    );
  }
}

class _VehiclePin extends StatelessWidget {
  final MapMarker marker;
  final bool selected;

  const _VehiclePin({required this.marker, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(marker.status);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: selected ? Colors.white : color,
              width: selected ? 2 : 1,
            ),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5)],
          ),
          child: Text(
            marker.plate,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(Icons.navigation, color: color, size: 25),
      ],
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    const items = {
      'In transit': AppColors.green,
      'Online': AppColors.accent,
      'Idle': AppColors.amber,
      'Offline': AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: item.value,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.key,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyMapMessage extends StatelessWidget {
  const _EmptyMapMessage();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      'No live vehicle locations yet',
      style: TextStyle(color: AppColors.textMuted),
    ),
  );
}
