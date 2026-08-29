import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/custom_map.dart';
import 'shell.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});
  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  String? _selectedId;
  String _searchQuery = '';

  void _select(String? id) => setState(() => _selectedId = id);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final points = app.mapPoints.map(MapMarker.fromRecord).toList();
    final geofences = [
      for (final g in app.geofences)
        (
          name: g.name,
          centerLat: g.centerLat,
          centerLon: g.centerLon,
          radiusM: g.radiusM,
          color: (g.color != null && g.color!.isNotEmpty)
              ? Color(int.parse(g.color!.replaceFirst('#', '0xFF')))
              : AppColors.cyan,
        ),
    ];

    // Filter vehicles by search query
    final filteredVehicles = app.vehicles.where((v) {
      final nameMatches = v.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final plateMatches = v.plate.toLowerCase().contains(_searchQuery.toLowerCase());
      final driverMatches = (v.driver?.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || plateMatches || driverMatches;
    }).toList();

    return PageScaffold(
      title: 'Fleet Tracking & Live Map',
      subtitle: 'Real-time vehicle GPS positions, active route tracks, status, and telemetry streams',
      actions: Row(
        children: [
          IconButton(
            tooltip: 'Refresh live fleet data',
            onPressed: app.busy ? null : app.refreshAll,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      scrollable: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Pane: Map View
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 12, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomMap(
                markers: points,
                geofences: geofences,
                selectedMarkerId: _selectedId,
              ),
            ),
          ),
          // Right Pane: Fleet List Sidebar
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 24, 24),
              child: Column(
                children: [
                  // Filter header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      style: const TextStyle(fontSize: 13, color: AppColors.text),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Filter by vehicle, plate, or driver...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Vehicle List
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Active Vehicles (${filteredVehicles.length})',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  '${app.vehicles.where((v) => app.livePosition(v.id)?.status == 'in_transit' || v.status == 'in_transit').length} In Transit',
                                  style: const TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: filteredVehicles.isEmpty
                                ? const EmptyState(
                                    message: 'No matching active vehicles.',
                                  )
                                : ListView.builder(
                                    itemCount: filteredVehicles.length,
                                    itemBuilder: (context, i) {
                                      final v = filteredVehicles[i];
                                      final live = app.livePosition(v.id);
                                      final status = live?.status ?? v.status;
                                      final speed = live?.speedKmh ?? v.speedKmh;
                                      final selected = _selectedId == v.id;
                                      final fuelLevel = 100 - (i * 7) % 60; // Mocked battery/fuel level
                                      return InkWell(
                                        onTap: () => _select(selected ? null : v.id),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? AppColors.accent.withOpacity(0.12)
                                                : AppColors.surfaceAlt,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: selected
                                                  ? AppColors.accent
                                                  : AppColors.border,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: AppColors.statusColor(status),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      v.name,
                                                      style: const TextStyle(
                                                        color: AppColors.text,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${v.plate} · ${v.driver?.name ?? 'No Driver'}',
                                                      style: const TextStyle(
                                                        color: AppColors.textMuted,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.local_gas_station, size: 10, color: AppColors.textMuted),
                                                        const SizedBox(width: 4),
                                                        Text('$fuelLevel%', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                                        const SizedBox(width: 12),
                                                        const Icon(Icons.flash_on, size: 10, color: AppColors.textMuted),
                                                        const SizedBox(width: 4),
                                                        Text('${(12.4 + (i * 0.1) % 1.2).toStringAsFixed(1)}V', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.statusColor(status).withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${speed.toStringAsFixed(0)} km/h',
                                                  style: TextStyle(
                                                    color: AppColors.statusColor(status),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedId != null) ...[
                    const SizedBox(height: 12),
                    _VehicleDetail(app: app, vehicleId: _selectedId!, onSelect: _select),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleDetail extends StatelessWidget {
  final AppState app;
  final String vehicleId;
  final ValueChanged<String?> onSelect;
  const _VehicleDetail({required this.app, required this.vehicleId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final v = app.vehicleById(vehicleId);
    if (v == null) return const SizedBox.shrink();
    final live = app.livePosition(vehicleId);
    final status = live?.status ?? v.status;
    final speed = live?.speedKmh ?? v.speedKmh;
    final heading = live?.heading ?? v.heading;
    final vehicleEvents = app.events
        .where((e) => e.vehicleId == vehicleId)
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${v.plate} · ${v.vehicleClass.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (v.driver != null)
                      Text(
                        'Driver: ${v.driver!.name}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => onSelect(null),
                    icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  SeverityBadge(status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Speed', value: '${speed.toStringAsFixed(0)} km/h'),
              _Stat(label: 'Heading', value: '${heading.toStringAsFixed(0)}°'),
              _Stat(label: 'Limit', value: '${v.speedLimitKmh ?? '—'} km/h'),
            ],
          ),
          if (vehicleEvents.isNotEmpty) ...[
            const Divider(height: 20),
            const Text(
              'Recent Events',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            for (final e in vehicleEvents)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SeverityBadge(e.severity),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        eventLabel(e.type),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      _timeAgo2(e.timestamp),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

String _timeAgo2(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  return '${diff.inHours}h';
}
