import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'safety_screen.dart';
import 'profile_screen.dart';
import 'hos_screen.dart';
import 'dvir_screen.dart';
import 'trips_screen.dart';
import '../widgets/driver_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pages = <Widget>[
      const _TripTab(),
      const HosScreen(),
      const DvirScreen(),
      const SafetyScreen(),
      const TripsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.navigation_rounded,
              color: AppColors.accent,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(s.user?.name ?? 'Ghost Driver'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(
                s.wsConnected ? Icons.wifi : Icons.wifi_off,
                size: 14,
                color: s.wsConnected ? AppColors.green : AppColors.red,
              ),
              label: Text(
                s.wsConnected ? 'Live' : 'Offline',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Trip',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'HOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'DVIR',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Safety',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _TripTab extends StatelessWidget {
  const _TripTab();

  String _fmtDur(int sec) {
    final m = sec ~/ 60, r = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = s.myVehicle;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.accentLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v?.name ?? 'No vehicle assigned',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        v?.plate ?? '—',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: s.onDuty,
                  onChanged: s.setOnDuty,
                  activeThumbColor: AppColors.green,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        DriverMap(
          latitude: s.lastLat == 0 ? (v?.lat ?? 11.0168) : s.lastLat,
          longitude: s.lastLon == 0 ? (v?.lon ?? 76.9558) : s.lastLon,
          speedKmh: s.lastSpeedKmh,
          live: s.wsConnected && s.tripActive,
        ),
        const SizedBox(height: 16),
        _TripStatusCard(s: s),
        const SizedBox(height: 16),
        Row(
          children: [
            _Metric(
              label: 'Elapsed',
              value: _fmtDur(s.tripElapsedSec),
              icon: Icons.timer_outlined,
            ),
            const SizedBox(width: 12),
            _Metric(
              label: 'Speed',
              value: '${s.lastSpeedKmh.round()} km/h',
              icon: Icons.speed,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Metric(
              label: 'Distance',
              value: '${s.distanceKm.toStringAsFixed(2)} km',
              icon: Icons.straighten,
            ),
            const SizedBox(width: 12),
            _Metric(
              label: 'Max speed',
              value: '${s.maxSpeedKmh.round()} km/h',
              icon: Icons.trending_up,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SosButton(s: s),
      ],
    );
  }
}

class _TripStatusCard extends StatelessWidget {
  const _TripStatusCard({required this.s});
  final AppState s;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: s.tripActive ? AppColors.surfaceAlt : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              s.tripActive ? Icons.play_circle_fill : Icons.trip_origin,
              size: 64,
              color: s.tripActive ? AppColors.green : AppColors.textMuted,
            ),
            const SizedBox(height: 10),
            Text(
              s.tripActive ? 'Trip in progress' : 'No active trip',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (s.tripActive) ...[
              const SizedBox(height: 4),
              Text(
                'Streaming ${s.pointsSent} points · ${s.batchesAcked}/${s.batchesSent} batches acked (${s.lastIngestStatus ?? '—'})',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: s.tripActive || !s.onDuty ? null : s.startTrip,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start trip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: s.tripActive ? s.endTrip : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                    ),
                    icon: const Icon(Icons.stop),
                    label: const Text('End trip'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton({required this.s});
  final AppState s;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: s.sosSent
            ? null
            : () async {
                final ok = await s.sendSos();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'SOS sent — fleet manager notified'
                            : 'SOS queued (will retry when connected)',
                      ),
                    ),
                  );
                }
              },
        icon: const Icon(Icons.emergency, size: 28),
        label: Text(
          s.sosSent ? 'SOS SENT' : 'SOS — Emergency',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.accentLight),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
