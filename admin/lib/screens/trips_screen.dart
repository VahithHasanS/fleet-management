import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final trips = app.trips;
    final events = app.events;

    return PageScaffold(
      title: 'Trips & Safety Events',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent trips (${trips.length})',
              style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (trips.isEmpty)
            const EmptyState(message: 'No trips yet. Start the phantom fleet to generate trips.')
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(AppColors.surfaceAlt),
                columns: const [
                  DataColumn(label: Text('Vehicle',
                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Driver',
                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Distance',
                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Duration',
                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Avg speed',
                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Score',
                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Events',
                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600))),
                ],
                rows: [
                  for (final t in trips)
                    DataRow(cells: [
                      DataCell(Text(t.vehicleName,
                          style: const TextStyle(color: AppColors.text, fontSize: 13))),
                      DataCell(Text(t.driverName ?? '—',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                      DataCell(Text('${t.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                      DataCell(Text(formatDuration(t.durationSec),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                      DataCell(Text('${t.avgSpeedKmh.toStringAsFixed(0)} km/h',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                      DataCell(Text('${t.totalScore.toStringAsFixed(0)}',
                          style: TextStyle(color: scoreColor(t.totalScore), fontSize: 12, fontWeight: FontWeight.w600))),
                      DataCell(t.eventCount == 0
                          ? const Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text('${t.eventCount}',
                                  style: const TextStyle(color: AppColors.red, fontSize: 11, fontWeight: FontWeight.w600)))),
                    ]),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text('Live safety events (${events.length})',
              style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const EmptyState(message: 'No safety events recorded yet.')
          else
            for (final e in events.take(40)) _EventRow(event: e),
        ],
      ),
    );
  }

  Color scoreColor(double s) =>
      s >= 95 ? AppColors.green : s >= 85 ? AppColors.amber : AppColors.red;
}

class _EventRow extends StatelessWidget {
  final dynamic event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final e = event;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SeverityBadge(e.severity),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eventLabel(e.type),
                    style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${e.vehicleName ?? 'Vehicle'} · ${_timeAgo(e.timestamp)}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text('${(e.confidence * 100).toStringAsFixed(0)}% conf',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

