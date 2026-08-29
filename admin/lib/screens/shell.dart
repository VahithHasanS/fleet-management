import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'drivers_screen.dart';
import 'fleet_screen.dart';
import 'leaderboard_screen.dart';
import 'live_map_screen.dart';
import 'phantom_fleet_screen.dart';
import 'trips_screen.dart';
import 'driver_operations_screen.dart';
import 'driver_safety_screen.dart';
import 'video_telematics_screen.dart';
import 'breach_screen.dart';
import 'predictive_analytics_screen.dart';
import 'route_optimization_screen.dart';
import 'maintenance_screen.dart';
import 'driver_wellness_screen.dart';
import 'reports_screen.dart';
import 'compliance_screen.dart';
import 'settings_screen.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final Widget Function() builder;
  const _NavItem(this.label, this.icon, this.builder);
}

final List<_NavItem> _navItems = [
  const _NavItem('Dashboard', Icons.dashboard_outlined, DashboardScreen.new),
  const _NavItem('Live Map', Icons.map_outlined, LiveMapScreen.new),
  const _NavItem('Phantom Fleet', Icons.radar, PhantomFleetScreen.new),
  const _NavItem('Fleet & Vehicles', Icons.local_shipping_outlined, FleetScreen.new),
  const _NavItem('Drivers', Icons.people_outline, DriversScreen.new),
  const _NavItem('Driver Safety', Icons.shield_outlined, DriverSafetyScreen.new),
  const _NavItem('Video Telematics', Icons.videocam_outlined, VideoTelematicsScreen.new),
  const _NavItem('Camera Breaches', Icons.warning_amber, BreachScreen.new),
  const _NavItem('Predictive Analytics', Icons.psychology_outlined, PredictiveAnalyticsScreen.new),
  const _NavItem('Route Optimization', Icons.alt_route, RouteOptimizationScreen.new),
  const _NavItem('Maintenance', Icons.build_circle_outlined, MaintenanceScreen.new),
  const _NavItem('Driver Wellness', Icons.favorite_border, DriverWellnessScreen.new),
  const _NavItem('Reports & Analytics', Icons.analytics_outlined, ReportsScreen.new),
  const _NavItem('Compliance & ELD', Icons.verified_outlined, ComplianceScreen.new),
  const _NavItem('Driver Operations', Icons.fact_check_outlined, DriverOperationsScreen.new),
  const _NavItem('Alerts Logs', Icons.notifications_active_outlined, AlertsScreen.new),
  const _NavItem('Leaderboard', Icons.leaderboard_outlined, LeaderboardScreen.new),
  const _NavItem('Trips History', Icons.route_outlined, TripsScreen.new),
  const _NavItem('Settings', Icons.settings_outlined, SettingsScreen.new),
];

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final index = app.currentNavIndex.clamp(0, _navItems.length - 1);
    final item = _navItems[index];

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppColors.surface,
            child: Column(
              children: [
                const _Brand(),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _navItems.length,
                    itemBuilder: (context, i) {
                      final it = _navItems[i];
                      final selected = i == index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Material(
                          color: selected ? AppColors.accent.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => app.setNavIndex(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              child: Row(
                                children: [
                                  Icon(
                                    it.icon,
                                    size: 19,
                                    color: selected ? AppColors.accentLight : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      it.label,
                                      style: TextStyle(
                                        color: selected ? AppColors.text : AppColors.textMuted,
                                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (app.user != null) UserChip(user: app.user!),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: app.wsConnected ? AppColors.green : AppColors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            app.wsConnected ? 'Live feed active' : 'Feed disconnected',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () => context.read<AppState>().logout(),
                        icon: const Icon(Icons.logout, size: 14),
                        label: const Text('Sign out', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Panel
          Expanded(
            child: Container(
              color: AppColors.bg,
              child: Column(
                children: [
                  _TopBar(selectedTitle: item.label),
                  Expanded(
                    child: item.builder(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.violet],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.gps_fixed, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FleetSafe',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Intelligent Operations',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String selectedTitle;
  const _TopBar({required this.selectedTitle});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Search box
          Container(
            width: 300,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              style: const TextStyle(fontSize: 13, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Search vehicles, drivers, dispatches...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          const Spacer(),
          // Date/Time
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(today, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(width: 24),
          // Messages Badge
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.mail_outline, size: 20, color: AppColors.textMuted),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: const Text('5', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
          // Notifications Badge
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, size: 20, color: AppColors.textMuted),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: const Text('12', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shared page scaffold for content screens.
class PageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? actions;
  final Widget child;
  final bool scrollable;

  const PageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.child,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              if (actions != null) actions!,
            ],
          ),
        ),
        Expanded(
          child: scrollable
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: child,
                )
              : child,
        ),
      ],
    );
  }
}
