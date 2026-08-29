import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Safety tab: average score gauge, coaching tips derived from the driver's
/// event history, and the live event feed pushed over the socket.
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  static String _coachingFor(String type) {
    switch (type) {
      case 'harsh_brake':
        return 'Keep more following distance and anticipate stops to brake smoothly.';
      case 'harsh_accel':
        return 'Accelerate gradually — hard throttle burns fuel and risks traction.';
      case 'harsh_corner':
        return 'Slow down before turns, not during them.';
      case 'speeding':
        return 'Stay within posted limits; speed is the top crash-risk factor.';
      case 'geofence_breach':
        return 'You left an approved zone — check with dispatch.';
      case 'smooth_driving':
        return 'Great smooth driving — keep it up!';
      default:
        return 'Drive smooth, score high.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final score = s.avgScore.round();
    // Count event types across recent history to prioritise coaching.
    final counts = <String, int>{};
    for (final e in s.myEvents) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }
    final topTypes =
        (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .take(3)
            .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ScoreCard(score: score),
        const SizedBox(height: 16),
        _CameraMonitorCard(),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () => _showWellnessDialog(context),
          icon: const Icon(Icons.health_and_safety_outlined),
          label: const Text('Wellness check-in'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Coaching tips',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (topTypes.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.emoji_events, color: AppColors.green),
              title: Text('No problem areas detected'),
              subtitle: Text('Keep driving to build your record.'),
            ),
          )
        else
          ...topTypes.map(
            (e) => Card(
              child: ListTile(
                leading: Icon(
                  Icons.school_outlined,
                  color: AppColors.accentLight,
                ),
                title: Text(e.key.replaceAll('_', ' ')),
                subtitle: Text(_coachingFor(e.key)),
                trailing: Text(
                  '×${e.value}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        _LiveFeedSection(s: s),
      ],
    );
  }

  Future<void> _showWellnessDialog(BuildContext context) async {
    var fatigue = 3;
    var stress = 3;
    var hydration = 3;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Wellness check-in'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _scale('Fatigue', fatigue, (v) => setState(() => fatigue = v)),
              _scale('Stress', stress, (v) => setState(() => stress = v)),
              _scale(
                'Hydration',
                hydration,
                (v) => setState(() => hydration = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final error = await context.read<AppState>().submitWellness(
                  fatigue: fatigue,
                  stress: stress,
                  hydration: hydration,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Wellness check-in saved')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scale(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        DropdownButton<int>(
          value: value,
          items: [
            for (var i = 1; i <= 5; i++)
              DropdownMenuItem(value: i, child: Text('$i / 5')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 10,
                      color: AppColors.scoreColor(score),
                      backgroundColor: AppColors.surfaceAlt,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.scoreColor(score),
                        ),
                      ),
                      const Text(
                        'Safety score',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              score >= 90
                  ? 'Excellent — among the safest drivers'
                  : score >= 75
                  ? 'Good — a few habits to polish'
                  : score >= 60
                  ? 'Needs attention'
                  : 'High risk — review coaching below',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveFeedSection extends StatelessWidget {
  const _LiveFeedSection({required this.s});
  final AppState s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Live events',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: () => s.refreshHistory(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (s.liveFeed.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No live events yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        else
          ...s.liveFeed.take(15).map((m) {
            final d = m.data;
            final type = (d['type'] ?? d['event']?['type'] ?? m.event)
                .toString();
            final sev = (d['severity'] ?? d['event']?['severity'] ?? 'low')
                .toString();
            return Card(
              child: ListTile(
                leading: Icon(Icons.bolt, color: AppColors.severityColor(sev)),
                title: Text(type.replaceAll('_', ' ')),
                subtitle: Text(m.event),
                dense: true,
              ),
            );
                    }),
      ],
    );
  }
}

class _CameraMonitorCard extends StatelessWidget {
  const _CameraMonitorCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cam = s.camera;
    final active = s.tripActive && s.cameraEnabled;
    final statusText = cam.lastError != null
        ? cam.lastError!
        : !cam.detectionAvailable
            ? 'Face detection not available on this platform'
            : (active
                ? (cam.streaming
                    ? 'Live feed + drowsiness detection ON'
                    : 'Camera starting...')
                : 'Enable to monitor drowsiness');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.videocam, color: AppColors.accentLight),
                const SizedBox(width: 8),
                const Text('Driver Monitoring (cabin camera)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Switch(
                  value: s.cameraEnabled,
                  onChanged: s.tripActive
                      ? (v) => s.setCameraEnabled(v)
                      : (v) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(v
                                  ? 'Camera starts with the next trip'
                                  : 'Camera disabled')));
                        },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(statusText,
                style: TextStyle(
                    color: cam.lastError != null
                        ? AppColors.red
                        : cam.lastBreach != null
                            ? AppColors.amber
                            : AppColors.textMuted,
                    fontSize: 12)),
            if (cam.lastBreach != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    '${cam.lastBreach} — open the Video Telematics screen on the admin app to review the live feed.',
                    style: const TextStyle(color: AppColors.red, fontSize: 12)),
              ),
            if (cam.initialized && active)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  height: 110,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CameraPreview(cam.controller!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
