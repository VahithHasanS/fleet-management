import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final alerts = app.alerts;
    final unread = alerts.where((a) => !a.read).length;

    return PageScaffold(
      title: 'Alerts',
      scrollable: true,
      actions: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.red.withOpacity(0.4)),
        ),
        child: Text(
          '$unread unread',
          style: const TextStyle(
            color: AppColors.red,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: alerts.isEmpty
          ? const EmptyState(
              message:
                  'No alerts yet. Start the phantom fleet to stream safety alerts.',
            )
          : Column(
              children: [
                for (final a in alerts.take(60)) _AlertTile(app: app, alert: a),
              ],
            ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AppState app;
  final dynamic alert;
  const _AlertTile({required this.app, required this.alert});

  @override
  Widget build(BuildContext context) {
    final a = alert;
    final color = AppColors.severityColor(a.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: a.read ? AppColors.border : color.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(eventIcon(a.type), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SeverityBadge(a.severity),
                    const SizedBox(width: 8),
                    Text(
                      eventLabel(a.type),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(a.timestamp),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  a.message,
                  style: const TextStyle(color: AppColors.text, fontSize: 13),
                ),
                Text(
                  '${a.vehicleName ?? 'Vehicle'} · ${a.driverName ?? '—'}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!a.read)
            IconButton(
              icon: const Icon(Icons.done, size: 18),
              color: AppColors.accentLight,
              onPressed: () async {
                final err = await app.acknowledgeAlert(a.id);
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
