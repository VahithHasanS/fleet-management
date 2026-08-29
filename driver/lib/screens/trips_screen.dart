import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Trip history tab — the driver's scored trips, newest first.
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.myTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.route_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('No trips yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Go on duty and start a trip from the Trip tab.',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => s.refreshHistory(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    final df = DateFormat('dd MMM, HH:mm');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: s.myTrips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t = s.myTrips[i];
        final start = DateTime.tryParse(t.startTime);
        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor:
                  AppColors.scoreColor(t.totalScore).withValues(alpha: 0.15),
              child: Text(
                '${t.totalScore}',
                style: TextStyle(
                    color: AppColors.scoreColor(t.totalScore),
                    fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(
                '${start != null ? df.format(start.toLocal()) : t.startTime} · ${t.distanceKm.toStringAsFixed(1)} km'),
            subtitle: Text(
                '${t.durationSec ~/ 60} min · avg ${t.avgSpeedKmh.round()} · max ${t.maxSpeedKmh.round()} km/h'
                '${t.positivePoints > 0 ? ' · +${t.positivePoints} bonus' : ''}'),
            trailing: t.smoothTrip
                ? const Icon(Icons.emoji_events, color: AppColors.amber)
                : Text('${t.eventCount} events',
                    style:
                        const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
        );
      },
    );
  }
}
