import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import 'shell.dart';
import '../core/models.dart';

class VideoTelematicsScreen extends StatefulWidget {
  const VideoTelematicsScreen({super.key});

  @override
  State<VideoTelematicsScreen> createState() => _VideoTelematicsScreenState();
}

class _VideoTelematicsScreenState extends State<VideoTelematicsScreen> {
  String _selectedVehicle = 'All';
  Map<String, dynamic>? _stats;
  bool _isDrowsy = false;
  DateTime? _drowsySince;
  Timer? _drowsinessTimer;
  Timer? _videoSubscriptionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      app.fetchCameraBreaches();
      app.fetchVideoStats().then((s) => setState(() => _stats = s));
      app.addListener(_handleAppChanged);
      // Ensure video subscription is active after login
      app.subscribeToVideoFeed();
    });
    _drowsinessTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isDrowsy && DateTime.now().difference(_drowsySince!).inSeconds > 5) {
        setState(() => _isDrowsy = false);
      }
    });
    // Periodically re-subscribe to video feed to handle reconnections
    _videoSubscriptionTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        final app = context.read<AppState>();
        app.subscribeToVideoFeed();
      }
    });
  }

  @override
  void dispose() {
    final app = context.read<AppState>();
    app.removeListener(_handleAppChanged);
    _drowsinessTimer?.cancel();
    _videoSubscriptionTimer?.cancel();
    super.dispose();
  }

  void _handleAppChanged() {
    if (!mounted) return;
    final app = context.read<AppState>();
    final breachType = app.lastBreachType;
    if (breachType != null && (breachType.contains('drowsiness') || breachType.contains('eye_closure'))) {
      setState(() {
        _isDrowsy = true;
        _drowsySince = DateTime.now();
      });
    }
    if (_stats == null && app.breaches.isNotEmpty) {
      app.fetchVideoStats().then((s) => setState(() => _stats = s));
    }
  }

  List<CameraBreach> get _breaches {
    final app = context.read<AppState>();
    var list = app.breaches.whereType<CameraBreach>();
    if (_selectedVehicle != 'All') {
      list = list.where((b) => (b.vehicleName ?? b.vehicleId) == _selectedVehicle);
    }
    return list.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final liveFrame = app.videoFrameB64;
    final liveVehicle = app.videoFrameVehicleId;
    final vehicleName = liveVehicle != null
        ? (app.vehicleById(liveVehicle)?.name ?? liveVehicle)
        : null;
    final breaches = _breaches;
    final byType = <String, int>{};
    for (final b in breaches) {
      byType[b.breachType] = (byType[b.breachType] ?? 0) + 1;
    }

    return PageScaffold(
      title: 'Video Telematics',
      subtitle: 'Live driver cabin feed, AI drowsiness/eye-closure breaches, and incident clips',
      actions: Row(
        children: [
          if (app.lastBreachType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isDrowsy ? AppColors.red.withOpacity(0.2) : AppColors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isDrowsy ? AppColors.red : AppColors.amber),
              ),
              child: Row(children: [
                Icon(_isDrowsy ? Icons.bedtime : Icons.remove, color: _isDrowsy ? AppColors.red : AppColors.amber, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${app.lastBreachType!.replaceAll('_', ' ')} · ${app.lastBreachVehicle ?? ''}',
                  style: TextStyle(color: _isDrowsy ? AppColors.red : AppColors.amber, fontSize: 12),
                ),
              ]),
            ),
          const Spacer(),
          DropdownButton<String>(
          value: _selectedVehicle,
          items: ['All', ...{for (final b in breaches) (b.vehicleName ?? b.vehicleId)}]
              .toList()
              .asMap()
              .entries
              .map((e) => DropdownMenuItem(
                  value: e.value,
                  child: Text(e.value, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (v) => setState(() => _selectedVehicle = v ?? 'All'),
        ),
        const SizedBox(width: 8),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Row(children: [
            Expanded(
              flex: 5,
              child: SectionCard(
                title: liveVehicle == null
                    ? 'Live Cabin Feed (subscribe via fleet map)'
                    : 'Live Cabin Feed — $vehicleName',
                child: liveFrame == null
                    ? Container(
                        color: AppColors.surfaceAlt,
                        child: const Center(
                            child: Text('Waiting for a driver camera frame…',
                                style: TextStyle(color: AppColors.textMuted))),
                      )
                    : Image.memory(
                        base64Decode(liveFrame),
                        gaplessPlayback: true,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: SectionCard(
                title: 'Camera AI Breach Log',
                child: breaches.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No camera breaches recorded.',
                            style: TextStyle(color: AppColors.textMuted)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: breaches.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) => _breachTile(breach: breaches[i]),
                      ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        _trailing(app, breaches, byType),
      ]),
    );
  }

  Widget _breachTile({required CameraBreach breach}) {
    final color = AppColors.severityColor(breach.severity);
    final icon = breach.breachType == 'eye_closure'
        ? Icons.visibility_off
        : breach.breachType == 'drowsiness'
            ? Icons.bedtime
            : breach.breachType == 'yawning'
                ? Icons.sentiment_dissatisfied
                : breach.breachType == 'distraction'
                    ? Icons.phone_android
                    : Icons.videocam_off;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        breach.breachType.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${breach.vehicleName ?? breach.vehicleId} · ${(breach.confidence * 100).toStringAsFixed(0)}% conf.',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
      trailing: Text(
        _formatTime(breach.timestamp),
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Widget _trailing(AppState app, List<CameraBreach> breaches, Map<String, int> byType) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: KpiCard(
            label: 'Total Camera Breaches',
            value: breaches.length.toString(),
            icon: Icons.videocam_off,
            color: AppColors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCard(
            label: 'Drowsiness',
            value: (byType['drowsiness'] ?? 0).toString(),
            icon: Icons.bedtime,
            color: AppColors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCard(
            label: 'Eye Closure',
            value: (byType['eye_closure'] ?? 0).toString(),
            icon: Icons.visibility_off,
            color: AppColors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCard(
            label: 'Distraction',
            value: (byType['distraction'] ?? 0).toString(),
            icon: Icons.phone_android,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
