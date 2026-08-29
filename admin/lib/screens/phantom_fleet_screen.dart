import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class PhantomFleetScreen extends StatelessWidget {
  const PhantomFleetScreen({super.key});

  static const _simEventTypes = [
    ('harsh_brake', 'Harsh brake'),
    ('harsh_accel', 'Harsh accel'),
    ('harsh_corner', 'Harsh corner'),
    ('sos', 'SOS'),
    ('wellness_alert', 'Wellness'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sim = app.simulator;

    return PageScaffold(
      title: 'Phantom Fleet Simulator',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sim.running ? AppColors.green.withOpacity(0.5) : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 16,
                    color: sim.running ? AppColors.green : AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sim.running ? 'Fleet is running' : 'Fleet is stopped',
                          style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${sim.vehicles} simulated vehicles · ${sim.emittedBatches} batches · ${sim.emittedEvents} events emitted across Coimbatore',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: sim.running ? null : () => _control(context, 'start'),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start all (50)'),
                    ),
                    OutlinedButton.icon(
                      onPressed: sim.running ? () => _control(context, 'stop') : null,
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('Stop'),
                    ),
                    TextButton.icon(
                      onPressed: () => _control(context, 'reset'),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Simulated vehicles',
              style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Inject a safety event into any live vehicle — it streams onto the map, '
              'Alerts and Leaderboard in real time.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 12),
          if (app.vehicles.isEmpty)
            const EmptyState(
                message: 'No simulated vehicles. Make sure the backend is seeded and running.')
          else
            _VehicleGrid(app: app),
        ],
      ),
    );
  }

  Future<void> _control(BuildContext context, String action) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final err = await app.simulatorControl(action);
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.red));
    }
  }
}

class _VehicleGrid extends StatelessWidget {
  final AppState app;
  const _VehicleGrid({required this.app});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = (constraints.maxWidth / 340).floor().clamp(1, 3);
      final per = (app.vehicles.length / columns).ceil().clamp(1, app.vehicles.length);
      return Column(
        children: [
          for (var c = 0; c < columns; c++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (var r = 0; r < per; r++)
                    if (c * per + r < app.vehicles.length)
                      Expanded(
                          child: _SimVehicleCard(
                              app: app, vehicleId: app.vehicles[c * per + r].id)),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _SimVehicleCard extends StatelessWidget {
  final AppState app;
  final String vehicleId;
  const _SimVehicleCard({required this.app, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final v = app.vehicleById(vehicleId);
    if (v == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.name,
                    style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(v.plate,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (type) async {
              final err = await app.triggerEvent(vehicleId, type);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: AppColors.red));
              }
            },
            itemBuilder: (_) => [
              for (final e in PhantomFleetScreen._simEventTypes)
                PopupMenuItem(value: e.$1, child: Text(e.$2)),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bolt, size: 14, color: AppColors.amber),
                SizedBox(width: 4),
                Text('Trigger', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

