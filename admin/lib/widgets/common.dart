import 'package:flutter/material.dart';

import '../core/models.dart';
import '../theme/app_theme.dart';

/// Severity pill using the shared severity palette.
class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge(this.severity, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Friendly label for an event type (snake_case -> Title Case).
String eventLabel(String type) {
  const map = {
    'harsh_brake': 'Harsh Brake',
    'harsh_accel': 'Harsh Acceleration',
    'harsh_corner': 'Harsh Corner',
    'speeding': 'Speeding',
    'geofence_breach': 'Geofence Breach',
    'sos': 'SOS',
    'wellness_alert': 'Wellness Alert',
    'smooth_driving': 'Smooth Driving',
  };
  return map[type] ?? type.replaceAll('_', ' ');
}

IconData eventIcon(String type) {
  switch (type) {
    case 'harsh_brake':
      return Icons.speed;
    case 'harsh_accel':
      return Icons.flash_on;
    case 'harsh_corner':
      return Icons.turn_right;
    case 'speeding':
      return Icons.speed;
    case 'geofence_breach':
      return Icons.gps_not_fixed;
    case 'sos':
      return Icons.sos;
    case 'wellness_alert':
      return Icons.favorite;
    default:
      return Icons.warning_amber;
  }
}

/// Circular driver-score gauge.
class ScoreGauge extends StatelessWidget {
  final double score;
  final double size;
  const ScoreGauge({super.key, required this.score, this.size = 90});

  Color get _color => score >= 90
      ? AppColors.green
      : score >= 75
          ? AppColors.amber
          : AppColors.red;

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: AlwaysStoppedAnimation(_color),
          ),
          Center(
            child: Text(
              score.toStringAsFixed(0),
              style: TextStyle(
                  color: AppColors.text, fontSize: size * 0.24, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty-state placeholder used across list screens.
class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Compact user/role avatar.
class UserChip extends StatelessWidget {
  final AuthUser user;
  const UserChip({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = (user.name ?? user.email).split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.accent,
          child: Text(initials.toUpperCase(),
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name ?? user.email,
                style: const TextStyle(color: AppColors.text, fontSize: 13)),
            Text(roleLabel(user.role),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

String roleLabel(String role) {
  switch (role) {
    case 'SUPER_ADMIN':
      return 'Super Admin';
    case 'FLEET_MANAGER':
      return 'Fleet Manager';
    case 'DISPATCHER':
      return 'Dispatcher';
    case 'DRIVER':
      return 'Driver';
    case 'MAINTENANCE':
      return 'Maintenance';
    case 'ANALYST':
      return 'Analyst';
    default:
      return role;
  }
}

/// Formats a duration in seconds as Hh Mm or Mm Ss.
String formatDuration(int sec) {
  if (sec >= 3600) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    return '${h}h ${m}m';
  }
  final m = sec ~/ 60;
  final s = sec % 60;
  return '${m}m ${s}s';
}
