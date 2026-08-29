import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Profile tab — driver identity, assigned vehicle, HOS-style duty summary,
/// connection info and logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                  child: Text(
                    (u?.name.isNotEmpty ?? false) ? u!.name[0] : '?',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentLight),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u?.name ?? '—',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(u?.email ?? '',
                          style:
                              const TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Chip(
                        label: const Text('DRIVER',
                            style: TextStyle(fontSize: 11)),
                        avatar: const Icon(Icons.badge,
                            size: 14, color: AppColors.accentLight),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _Row(icon: Icons.local_shipping_outlined, label: 'Vehicle',
                  value: '${s.myVehicle?.name ?? '—'} (${s.myVehicle?.plate ?? '—'})'),
              const Divider(height: 1),
              _Row(icon: Icons.timer_outlined, label: 'Duty status',
                  value: s.onDuty ? 'On duty' : 'Off duty'),
              const Divider(height: 1),
              _Row(icon: Icons.route_outlined, label: 'Trips recorded',
                  value: '${s.myTrips.length}'),
              const Divider(height: 1),
              _Row(icon: Icons.shield_outlined, label: 'Avg safety score',
                  value: '${s.avgScore.round()}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _Row(icon: Icons.dns_outlined, label: 'Backend',
                  value: AppConfig.apiUrl),
              const Divider(height: 1),
              _Row(icon: Icons.wifi, label: 'Live socket',
                  value: s.wsConnected ? 'Connected' : 'Disconnected'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red,
            side: const BorderSide(color: AppColors.red),
          ),
          onPressed: () => s.logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentLight, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      dense: true,
    );
  }
}
