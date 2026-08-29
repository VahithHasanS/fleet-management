import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/kpi_card.dart';
import 'shell.dart';

class RouteOptimizationScreen extends StatefulWidget {
  const RouteOptimizationScreen({super.key});

  @override
  State<RouteOptimizationScreen> createState() =>
      _RouteOptimizationScreenState();
}

class _RouteOptimizationScreenState extends State<RouteOptimizationScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final vehicles = app.vehicles;
    final stats = app.stats;

    final inTransitCount = stats.inTransit > 0 ? stats.inTransit : (vehicles.isEmpty ? 4 : vehicles.length);
    final fuelSavings = (inTransitCount * 22.5).toStringAsFixed(0);

    return PageScaffold(
      title: 'Route Optimization',
      subtitle:
          'Dispatch optimized routes, analyze traffic delays, and track fuel/time savings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: KpiCardV2(
                    label: 'Average Trip Delay',
                    value: '4.2 Min',
                    icon: Icons.hourglass_empty,
                    iconColor: AppColors.green,
                    trendText: '↓ 1.5m reduction',
                    trendUp: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Estimated Fuel Savings',
                    value: '$fuelSavings Litres',
                    icon: Icons.local_gas_station_outlined,
                    iconColor: AppColors.cyan,
                    trendText: '↑ 12% this month',
                    trendUp: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Route Adherence Rating',
                    value: '96.2%',
                    icon: Icons.alt_route,
                    iconColor: AppColors.green,
                    trendText: '↑ 2.1% improvement',
                    trendUp: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Active Dispatches',
                    value: '$inTransitCount Routes',
                    icon: Icons.navigation_outlined,
                    iconColor: AppColors.accent,
                    trendText: 'Live fleet dispatching',
                    trendUp: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: SectionCard(
                    title: 'Optimized Dispatch Routing Logs',
                    child: vehicles.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No registered vehicles found for dispatch routing.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          )
                        : Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2.5),
                              1: FlexColumnWidth(4),
                              2: FlexColumnWidth(2.5),
                              3: FlexColumnWidth(3),
                              4: FlexColumnWidth(2),
                            },
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.border),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'Vehicle / Driver',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'Route Description',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'Est. Duration',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'Fuel Optimization',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'Status',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              for (final v in vehicles.take(6))
                                TableRow(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColors.border,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v.name,
                                            style: const TextStyle(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            v.driver?.name ?? v.plate,
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        'Depot Hub → Route Sector ${v.plate}',
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Text('1 hr 15 min'),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        'Saved 2.1 L (AI Route)',
                                        style: TextStyle(
                                          color: AppColors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.green.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          v.status.replaceAll('_', ' ').toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: SectionCard(
                    title: 'AI Traffic delay recommendations',
                    child: Column(
                      children: [
                        _buildAlert(
                          'Toll Road Jam Warning',
                          'Avinashi Road flyover construction congestion. AI rerouting GT 04 to Bypass South Road recommended.',
                          AppColors.amber,
                        ),
                        const SizedBox(height: 12),
                        _buildAlert(
                          'Heavy Cargo Reroute',
                          'GT 02 HGV weight limit restrictions flag on Singanallur Canal Bridge. Rerouted via NH-544.',
                          AppColors.cyan,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlert(String title, String desc, Color alertColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route, color: alertColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: alertColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(color: AppColors.text, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
