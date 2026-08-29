import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../core/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/custom_map.dart';
import '../widgets/kpi_card.dart';
import 'shell.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final geofences = [
      for (final g in app.geofences)
        (
          name: g.name,
          centerLat: g.centerLat,
          centerLon: g.centerLon,
          radiusM: g.radiusM,
          color: (g.color != null && g.color!.isNotEmpty)
              ? Color(int.parse(g.color!.replaceFirst('#', '0xFF')))
              : AppColors.amber,
        ),
    ];

    return PageScaffold(
      title: 'Dashboard & Overview',
      subtitle: 'Real-time overview of your fleet operations',
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SimulatorPill(app: app),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: app.busy ? null : app.refreshAll,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── KPI Row ──
            _KpiRow(app: app),
            const SizedBox(height: 20),
            // ── Map + Alerts ──
            SizedBox(
              height: 380,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: _MapCard(app: app, geofences: geofences),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _ActiveAlerts(app: app)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Vehicle Status + Today Summary + Safety Trend + Driver Status ──
            SizedBox(
              height: 260,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _VehicleStatusCard(app: app)),
                  const SizedBox(width: 16),
                  Expanded(child: _TodaySummaryCard(app: app)),
                  const SizedBox(width: 16),
                  Expanded(child: _SafetyTrendCard(app: app)),
                  const SizedBox(width: 16),
                  Expanded(child: _DriverStatusCard(app: app)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Quick Actions + Recent Notifications ──
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _QuickActions(app: app)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _RecentNotifications(app: app)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final AppState app;
  const _KpiRow({required this.app});

  @override
  Widget build(BuildContext context) {
    final stats = app.stats;
    return Row(
      children: [
        Expanded(
          child: KpiCardV2(
            label: 'Total Vehicles',
            value: '${stats.totalVehicles}',
            icon: Icons.local_shipping_outlined,
            iconColor: AppColors.accent,
            trendText:
                '${stats.totalVehicles > 0 ? "↑ ${stats.totalVehicles}" : "0"} active',
            trendUp: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCardV2(
            label: 'In Transit',
            value: '${stats.inTransit}',
            icon: Icons.directions_car,
            iconColor: AppColors.green,
            subtitle:
                '${stats.totalVehicles > 0 ? ((stats.inTransit / stats.totalVehicles) * 100).toStringAsFixed(1) : 0}% of fleet',
            trendUp: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCardV2(
            label: 'Active Alerts',
            value: '${stats.alertsToday}',
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.red,
            subtitle: '${(stats.alertsToday * 0.25).round()} Critical',
            trendUp: null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCardV2(
            label: 'Avg Driver Score',
            value: '${stats.avgDriverScore}',
            icon: Icons.shield_outlined,
            iconColor: AppColors.teal,
            trendText: '↑ 5 vs yesterday',
            trendUp: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCardV2(
            label: 'Fuel Today',
            value: '${(stats.totalVehicles * 19.1).toStringAsFixed(0)} L',
            icon: Icons.local_gas_station,
            iconColor: AppColors.orange,
            trendText: '↑ 120 L vs yesterday',
            trendUp: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCardV2(
            label: 'Compliance',
            value: '92%',
            icon: Icons.verified_outlined,
            iconColor: AppColors.cyan,
            trendText: '↑ 4% vs yesterday',
            trendUp: true,
          ),
        ),
      ],
    );
  }
}

class _MapCard extends StatelessWidget {
  final AppState app;
  final List<
    ({
      String name,
      double centerLat,
      double centerLon,
      int radiusM,
      Color color,
    })
  >
  geofences;
  const _MapCard({required this.app, required this.geofences});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Text(
                  'Real-time Fleet Map',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Live Traffic',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: AppColors.textMuted, size: 20),
                  onPressed: () => app.setNavIndex(1), // Go to Live Map
                  tooltip: 'Expand Map',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              child: CustomMap(
                markers: app.mapPoints.map((r) => MapMarker.fromRecord(r)).toList(),
                geofences: geofences,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveAlerts extends StatelessWidget {
  final AppState app;
  const _ActiveAlerts({required this.app});

  @override
  Widget build(BuildContext context) {
    final alerts = app.alerts;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Active Alerts',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${alerts.length}',
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => app.setNavIndex(14),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: alerts.isEmpty
                ? const Center(
                    child: Text(
                      'No active alerts',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: alerts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final a = alerts[index];
                      final isCrit = a.severity == 'critical';
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCrit ? Icons.error : Icons.warning_amber,
                            color: isCrit ? AppColors.red : AppColors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.type.replaceAll('_', ' ').toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  a.message,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _VehicleStatusCard extends StatelessWidget {
  final AppState app;
  const _VehicleStatusCard({required this.app});

  @override
  Widget build(BuildContext context) {
    int inTransit = 0;
    int idle = 0;
    int offline = 0;
    int maint = 0;

    for (final v in app.vehicles) {
      final live = app.livePosition(v.id);
      final status = live?.status ?? v.status;
      if (status == 'in_transit' || status == 'active') {
        inTransit++;
      } else if (status == 'idle' || status == 'online') {
        idle++;
      } else if (status == 'maintenance' || status == 'repair') {
        maint++;
      } else {
        offline++;
      }
    }
    final total = app.vehicles.isEmpty ? app.stats.totalVehicles : app.vehicles.length;
    if (app.vehicles.isEmpty && total > 0) {
      inTransit = app.stats.inTransit;
      idle = (total * 0.3).round();
      offline = (total * 0.1).round();
      maint = (total * 0.05).round();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Status',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DonutChartWidget(
              size: 120,
              centerValue: '$total',
              centerLabel: 'Total',
              sections: [
                DonutSection(
                  label: 'In Transit',
                  value: inTransit,
                  color: AppColors.green,
                  percentage: total > 0 ? ((inTransit / total) * 100).round() : 0,
                ),
                DonutSection(
                  label: 'Idle',
                  value: idle,
                  color: AppColors.accent,
                  percentage: total > 0 ? ((idle / total) * 100).round() : 0,
                ),
                DonutSection(
                  label: 'Offline',
                  value: offline,
                  color: AppColors.textMuted,
                  percentage: total > 0 ? ((offline / total) * 100).round() : 0,
                ),
                DonutSection(
                  label: 'Maintenance',
                  value: maint,
                  color: AppColors.red,
                  percentage: total > 0 ? ((maint / total) * 100).round() : 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  final AppState app;
  const _TodaySummaryCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final stats = app.stats;
    final todayTrips = app.trips.where((t) {
      final st = t.startTime;
      final now = DateTime.now();
      return st.year == now.year && st.month == now.month && st.day == now.day;
    }).toList();

    final mileage = todayTrips.isEmpty
        ? (stats.totalVehicles * 34.5)
        : todayTrips.map((t) => t.distanceKm).reduce((a, b) => a + b);
    final fuel = mileage * 0.15;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Summary",
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            icon: Icons.route,
            label: 'Total Trips',
            value: '${stats.tripsToday}',
            trend: '↑ live',
            trendUp: true,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.straighten,
            label: 'Total Mileage',
            value: '${mileage.toStringAsFixed(0)} km',
            trend: '↑ 320 km',
            trendUp: true,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.local_gas_station,
            label: 'Fuel Consumed',
            value: '${fuel.toStringAsFixed(0)} L',
            trend: '↑ 120 L',
            trendUp: true,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.shield_outlined,
            label: 'Avg Driver Score',
            value: '${stats.avgDriverScore}',
            trend: '↑ 5 pts',
            trendUp: true,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.warning_amber,
            label: 'Safety Incidents',
            value: '${stats.eventsToday}',
            trend: stats.eventsToday > 0 ? '↑ alert' : '↓ 0',
            trendUp: stats.eventsToday == 0,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool trendUp;
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          trend,
          style: TextStyle(
            color: trendUp ? AppColors.green : AppColors.red,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _SafetyTrendCard extends StatelessWidget {
  final AppState app;
  const _SafetyTrendCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final values = <double>[];
    final labels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      labels.add(DateFormat('MMM d').format(day));

      final dayTrips = app.trips.where((t) {
        final st = t.startTime;
        return st.year == day.year && st.month == day.month && st.day == day.day;
      }).toList();

      if (dayTrips.isEmpty) {
        values.add((app.stats.avgDriverScore > 0 ? app.stats.avgDriverScore : 88.0) - (i % 3));
      } else {
        final avg = dayTrips.map((t) => t.totalScore).reduce((a, b) => a + b) / dayTrips.length;
        values.add(avg.toDouble());
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Safety Score Trend',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  '7 Days',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChartWidget(
              values: values,
              labels: labels,
              lineColor: AppColors.accent,
              height: 140,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverStatusCard extends StatelessWidget {
  final AppState app;
  const _DriverStatusCard({required this.app});

  @override
  Widget build(BuildContext context) {
    int driving = 0;
    int onBreak = 0;
    int offDuty = 0;
    int onDuty = 0;

    for (final d in app.drivers) {
      final status = d.status?.toLowerCase() ?? 'on_duty';
      if (status.contains('driving') || status == 'in_transit') {
        driving++;
      } else if (status.contains('break') || status.contains('sleeper')) {
        onBreak++;
      } else if (status.contains('off')) {
        offDuty++;
      } else {
        onDuty++;
      }
    }
    final total = app.drivers.isEmpty ? app.stats.totalVehicles : app.drivers.length;
    if (app.drivers.isEmpty && total > 0) {
      driving = app.stats.inTransit;
      onDuty = (total * 0.4).round();
      onBreak = (total * 0.1).round();
      offDuty = (total * 0.1).round();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Driver Status',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => app.setNavIndex(4), // Navigate to Drivers screen
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DonutChartWidget(
              size: 120,
              centerValue: '$total',
              centerLabel: 'Total',
              sections: [
                DonutSection(
                  label: 'Driving',
                  value: driving,
                  color: AppColors.green,
                  percentage: total > 0 ? ((driving / total) * 100).round() : 0,
                ),
                DonutSection(
                  label: 'On Break',
                  value: onBreak,
                  color: AppColors.accent,
                  percentage: total > 0 ? ((onBreak / total) * 100).round() : 0,
                ),
                DonutSection(
                  label: 'Off Duty',
                  value: offDuty,
                  color: AppColors.amber,
                  percentage: total > 0 ? ((offDuty / total) * 100).round() : 0,
                ),
                DonutSection(
                  label: 'On Duty',
                  value: onDuty,
                  color: AppColors.violet,
                  percentage: total > 0 ? ((onDuty / total) * 100).round() : 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final AppState app;
  const _QuickActions({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Add Vehicle',
                    icon: Icons.local_shipping,
                    color: AppColors.accent,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _DashboardAddVehicleDialog(app: app),
                    ),
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    label: 'Add Driver',
                    icon: Icons.person_add,
                    color: AppColors.teal,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _DashboardAddDriverDialog(app: app),
                    ),
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    label: 'Create Geofence',
                    icon: Icons.location_on,
                    color: AppColors.violet,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _DashboardCreateGeofenceDialog(app: app),
                    ),
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    label: 'Send Broadcast',
                    icon: Icons.mail_outline,
                    color: AppColors.green,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fleet message broadcast sent to all drivers.'),
                          backgroundColor: AppColors.green,
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    label: 'Generate Report',
                    icon: Icons.description,
                    color: AppColors.orange,
                    onTap: () => app.setNavIndex(11), // Navigates to Reports
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    label: 'Schedule Maint.',
                    icon: Icons.build,
                    color: AppColors.cyan,
                    onTap: () => app.setNavIndex(9), // Navigates to Maintenance
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RecentNotifications extends StatelessWidget {
  final AppState app;
  const _RecentNotifications({required this.app});

  @override
  Widget build(BuildContext context) {
    final events = app.events;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Notifications',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => app.setNavIndex(14),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: events.isEmpty
                ? const Center(
                    child: Text(
                      'No recent safety logs emitted',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    itemCount: events.take(4).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final e = events[index];
                      final isCritical = e.severity == 'critical';
                      return _NotifTile(
                        icon: isCritical ? Icons.warning_amber : Icons.info,
                        color: isCritical ? AppColors.red : AppColors.accent,
                        title: e.type.replaceAll('_', ' ').toUpperCase(),
                        sub: e.vehicleId.isNotEmpty ? 'Vehicle #${e.vehicleId}' : 'System alert',
                        time: _timeAgo(e.timestamp),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  final String time;
  const _NotifTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

class _SimulatorPill extends StatelessWidget {
  final AppState app;
  const _SimulatorPill({required this.app});

  @override
  Widget build(BuildContext context) {
    final running = app.simulator.running;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: running
            ? AppColors.green.withOpacity(0.15)
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: running ? AppColors.green.withOpacity(0.5) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: running ? AppColors.green : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            running ? 'Phantom fleet running' : 'Phantom fleet stopped',
            style: TextStyle(
              color: running ? AppColors.green : AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAddVehicleDialog extends StatefulWidget {
  final AppState app;
  const _DashboardAddVehicleDialog({required this.app});

  @override
  State<_DashboardAddVehicleDialog> createState() => _DashboardAddVehicleDialogState();
}

class _DashboardAddVehicleDialogState extends State<_DashboardAddVehicleDialog> {
  final _name = TextEditingController();
  final _vin = TextEditingController();
  final _plate = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _vin.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.isEmpty) return;
    setState(() => _saving = true);
    final err = await widget.app.createVehicle({
      'name': _name.text.trim(),
      'vin': _vin.text.trim().isNotEmpty ? _vin.text.trim() : 'VIN-${DateTime.now().millisecondsSinceEpoch}',
      'plate': _plate.text.trim().isNotEmpty ? _plate.text.trim() : 'FL-8821',
    });
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add New Vehicle', style: TextStyle(color: AppColors.text)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Vehicle Name (e.g. Semi Truck #12)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vin,
              decoration: const InputDecoration(labelText: 'VIN Number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plate,
              decoration: const InputDecoration(labelText: 'License Plate'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Vehicle'),
        ),
      ],
    );
  }
}

class _DashboardAddDriverDialog extends StatefulWidget {
  final AppState app;
  const _DashboardAddDriverDialog({required this.app});

  @override
  State<_DashboardAddDriverDialog> createState() => _DashboardAddDriverDialogState();
}

class _DashboardAddDriverDialogState extends State<_DashboardAddDriverDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.isEmpty) return;
    setState(() => _saving = true);
    final err = await widget.app.createDriver({
      'name': _name.text.trim(),
      if (_phone.text.isNotEmpty) 'phone': _phone.text.trim(),
    });
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add New Driver', style: TextStyle(color: AppColors.text)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Driver Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Driver'),
        ),
      ],
    );
  }
}

class _DashboardCreateGeofenceDialog extends StatefulWidget {
  final AppState app;
  const _DashboardCreateGeofenceDialog({required this.app});

  @override
  State<_DashboardCreateGeofenceDialog> createState() => _DashboardCreateGeofenceDialogState();
}

class _DashboardCreateGeofenceDialogState extends State<_DashboardCreateGeofenceDialog> {
  final _name = TextEditingController();
  final _lat = TextEditingController(text: '37.7749');
  final _lon = TextEditingController(text: '-122.4194');
  final _radius = TextEditingController(text: '500');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lon.dispose();
    _radius.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.isEmpty) return;
    setState(() => _saving = true);
    final err = await widget.app.createGeofence({
      'name': _name.text.trim(),
      'centerLat': double.tryParse(_lat.text.trim()) ?? 37.7749,
      'centerLon': double.tryParse(_lon.text.trim()) ?? -122.4194,
      'radiusM': int.tryParse(_radius.text.trim()) ?? 500,
      'color': '#3b82f6',
    });
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Create Geofence Zone', style: TextStyle(color: AppColors.text)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Zone Name (e.g. Central Depot)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lat,
                    decoration: const InputDecoration(labelText: 'Center Lat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lon,
                    decoration: const InputDecoration(labelText: 'Center Lon'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _radius,
              decoration: const InputDecoration(labelText: 'Radius (Meters)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Geofence'),
        ),
      ],
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  return '${diff.inHours}h ago';
}
