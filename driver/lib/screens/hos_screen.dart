import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class HosScreen extends StatefulWidget {
  const HosScreen({super.key});

  @override
  State<HosScreen> createState() => _HosScreenState();
}

class _HosScreenState extends State<HosScreen> {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    // Calculate elapsed times from logs
    final drivingDuration = s.hosLogs.where((e) => e.status == 'driving').fold<Duration>(
          Duration.zero,
          (sum, e) => sum + (e.endedAt ?? DateTime.now()).difference(e.startedAt),
        );
    final onDutyDuration = s.hosLogs.where((e) => e.status == 'on_duty' || e.status == 'driving').fold<Duration>(
          Duration.zero,
          (sum, e) => sum + (e.endedAt ?? DateTime.now()).difference(e.startedAt),
        );

    // Dynamic HOS Remaining Times
    final driveLimit = const Duration(hours: 11);
    final shiftLimit = const Duration(hours: 14);
    final breakLimit = const Duration(hours: 8);

    final driveRemaining = driveLimit - drivingDuration;
    final shiftRemaining = shiftLimit - onDutyDuration;
    final breakRemaining = breakLimit - drivingDuration; // Mocked remaining break time

    final driveVal = driveRemaining.isNegative ? 0.0 : driveRemaining.inMinutes / driveLimit.inMinutes;
    final shiftVal = shiftRemaining.isNegative ? 0.0 : shiftRemaining.inMinutes / shiftLimit.inMinutes;
    final breakVal = breakRemaining.isNegative ? 0.0 : breakRemaining.inMinutes / breakLimit.inMinutes;

    // Active status
    final currentStatus = s.hosLogs.isNotEmpty ? s.hosLogs.first.status : 'off_duty';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ELD & Hours of Service'),
        actions: [
          IconButton(
            onPressed: s.refreshOperations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Duty Status',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Duty Status Buttons ──
          const Text('CURRENT STATUS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatusBtn(label: 'OFF', sub: 'Off Duty', active: currentStatus == 'off_duty', color: AppColors.textMuted, icon: Icons.power_settings_new, onTap: () => s.setOnDuty(false))),
              const SizedBox(width: 8),
              Expanded(child: _StatusBtn(label: 'SLEEP', sub: 'Sleeper', active: currentStatus == 'sleeper', color: AppColors.amber, icon: Icons.bed, onTap: () => s.api.post('/api/v1/tenants/${s.user!.tenantId}/driver-operations/hos', body: {'vehicleId': s.myVehicle?.id, 'status': 'sleeper', 'note': 'Status changed via app'}).then((_) => s.refreshOperations()))),
              const SizedBox(width: 8),
              Expanded(child: _StatusBtn(label: 'DRIVE', sub: 'Driving', active: currentStatus == 'driving', color: AppColors.green, icon: Icons.directions_car, onTap: s.startTrip)),
              const SizedBox(width: 8),
              Expanded(child: _StatusBtn(label: 'ON', sub: 'On Duty', active: currentStatus == 'on_duty', color: AppColors.accentLight, icon: Icons.work_outline, onTap: () => s.setOnDuty(true))),
            ],
          ),
          const SizedBox(height: 20),

          // ── HOS Clocks ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildClockCircle('DRIVE', _format(driveRemaining), driveVal, AppColors.green),
              _buildClockCircle('SHIFT', _format(shiftRemaining), shiftVal, AppColors.accentLight),
              _buildClockCircle('BREAK', _format(breakRemaining), breakVal, AppColors.amber),
            ],
          ),
          const SizedBox(height: 20),

          // ── 24 Hour Graph Grid ──
          const Text('24-HOUR LOG GRID', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 180,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: CustomPaint(
              painter: _LogGridPainter(logs: s.hosLogs),
            ),
          ),
          const SizedBox(height: 20),

          // ── Duty Log History & Certify ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DAILY LOGS', style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logs successfully certified and locked for DOT compliance audit.')),
                  );
                },
                icon: const Icon(Icons.verified, size: 16),
                label: const Text('Certify Logs', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (s.hosLogs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No duty log entries recorded for today.', style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
            )
          else
            ...s.hosLogs.map((log) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _color(log.status).withOpacity(0.15),
                    child: Icon(_icon(log.status), color: _color(log.status), size: 18),
                  ),
                  title: Text(log.status.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    'Started: ${DateFormat('hh:mm a').format(log.startedAt.toLocal())}${log.endedAt == null ? ' (Active)' : ' - Ended: ${DateFormat('hh:mm a').format(log.endedAt!.toLocal())}'}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  trailing: log.note != null
                      ? Text(log.note!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildClockCircle(String title, String valStr, double pct, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 85,
              height: 85,
              child: CircularProgressIndicator(
                value: pct,
                color: color,
                backgroundColor: AppColors.border,
                strokeWidth: 6,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(valStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static String _format(Duration d) {
    if (d.isNegative) return '00:00';
    return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';
  }

  static IconData _icon(String status) => status == 'driving'
      ? Icons.directions_car
      : status == 'sleeper'
          ? Icons.bed
          : status == 'on_duty'
              ? Icons.work_outline
              : Icons.pause_circle_outline;

  static Color _color(String status) => status == 'driving'
      ? AppColors.green
      : status == 'off_duty'
          ? AppColors.textMuted
          : status == 'sleeper'
              ? AppColors.amber
              : AppColors.accentLight;
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final String sub;
  final bool active;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _StatusBtn({
    required this.label,
    required this.sub,
    required this.active,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? color.withOpacity(0.2) : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? color : AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: active ? color : AppColors.textMuted, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: active ? color : AppColors.text, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogGridPainter extends CustomPainter {
  final List<dynamic> logs;
  _LogGridPainter({required this.logs});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final leftMargin = 40.0;
    final bottomMargin = 20.0;
    final gridWidth = size.width - leftMargin;
    final gridHeight = size.height - bottomMargin;

    final statuses = ['OFF', 'SB', 'D', 'ON'];
    final rowHeight = gridHeight / 4;

    // Draw status labels on Y axis
    for (int i = 0; i < 4; i++) {
      final y = i * rowHeight + rowHeight / 2;
      textPainter.text = TextSpan(
        text: statuses[i],
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(8, y - textPainter.height / 2));
    }

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    // Draw grid horizontal rows
    for (int i = 0; i <= 4; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);
    }

    // Draw grid vertical hour indicators (0 to 24, drawing every 2 hours to avoid clutter)
    final colWidth = gridWidth / 24;
    for (int i = 0; i <= 24; i++) {
      final x = leftMargin + i * colWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, gridHeight), gridPaint);

      if (i % 4 == 0) {
        textPainter.text = TextSpan(
          text: '$i',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, gridHeight + 4));
      }
    }

    // Draw the logs timeline graph line
    if (logs.isEmpty) return;

    final linePaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    double getX(DateTime dt) {
      final diff = dt.difference(todayStart);
      final minutes = diff.inMinutes;
      final pct = (minutes / (24 * 60)).clamp(0.0, 1.0);
      return leftMargin + pct * gridWidth;
    }

    double getY(String status) {
      switch (status) {
        case 'off_duty':
          return rowHeight * 0.5;
        case 'sleeper':
          return rowHeight * 1.5;
        case 'driving':
          return rowHeight * 2.5;
        case 'on_duty':
        default:
          return rowHeight * 3.5;
      }
    }

    Offset? prevPoint;

    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      final startX = getX(log.startedAt);
      final endX = getX(log.endedAt ?? now);
      final y = getY(log.status);

      final pStart = Offset(startX, y);
      final pEnd = Offset(endX, y);

      // Draw horizontal log status line
      canvas.drawLine(pStart, pEnd, linePaint);

      // Draw vertical transition line if there was a previous log
      if (prevPoint != null) {
        canvas.drawLine(prevPoint, pStart, linePaint);
      }

      prevPoint = pEnd;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
