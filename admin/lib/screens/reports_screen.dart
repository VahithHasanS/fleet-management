import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/kpi_card.dart';
import 'shell.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedDateRange = 'Last 7 Days';
  String _selectedFleet = 'All Fleets';
  String _selectedReportType = 'Safety Overview';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return PageScaffold(
      title: 'Reports & Analytics',
      subtitle: 'Build, schedule, and export business intelligence reports across safety, fuel, and compliance',
      actions: Row(
        children: [
          DropdownButton<String>(
            value: _selectedDateRange,
            items: ['Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days', 'Custom Range'].map((String val) {
              return DropdownMenuItem<String>(value: val, child: Text(val, style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: (val) => setState(() => _selectedDateRange = val!),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export PDF'),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Filters
          Container(
            width: 240,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Report Filters', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 20),
                const Text('Fleet Scope', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedFleet,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: ['All Fleets', 'Coimbatore North', 'Coimbatore South'].map((String val) {
                    return DropdownMenuItem<String>(value: val, child: Text(val, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedFleet = val!),
                ),
                const SizedBox(height: 20),
                const Text('Report Category', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedReportType,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: ['Safety Overview', 'Fuel & Mileage Efficiency', 'ELD & HOS Compliance', 'Maintenance Forecasts'].map((String val) {
                    return DropdownMenuItem<String>(value: val, child: Text(val, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedReportType = val!),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.schedule, size: 16),
                  label: const Text('Schedule Report'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                ),
              ],
            ),
          ),
          // Main Reports Panel
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: KpiCardV2(
                          label: 'Total Distance',
                          value: '${(app.stats.totalVehicles * 210.5).toStringAsFixed(1)} km',
                          icon: Icons.map,
                          iconColor: AppColors.cyan,
                          trendText: '↑ 12.3% from prev week',
                          trendUp: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: KpiCardV2(
                          label: 'Fleet Utilization',
                          value: '84.2%',
                          icon: Icons.star_border,
                          iconColor: AppColors.green,
                          trendText: '↑ 4% vs last week',
                          trendUp: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: KpiCardV2(
                          label: 'Fuel Economy',
                          value: '5.2 km/L',
                          icon: Icons.local_gas_station,
                          iconColor: AppColors.amber,
                          trendText: '↓ 1.2% fuel waste',
                          trendUp: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SectionCard(
                          title: 'Fuel Consumption (Litres per Day)',
                          child: HorizontalBarChartWidget(
                            items: const [
                              BarItem(label: 'Mon', value: 140, color: AppColors.amber),
                              BarItem(label: 'Tue', value: 160, color: AppColors.amber),
                              BarItem(label: 'Wed', value: 155, color: AppColors.amber),
                              BarItem(label: 'Thu', value: 175, color: AppColors.amber),
                              BarItem(label: 'Fri', value: 190, color: AppColors.amber),
                              BarItem(label: 'Sat', value: 120, color: AppColors.amber),
                              BarItem(label: 'Sun', value: 95, color: AppColors.amber),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SectionCard(
                          title: 'Compliance Percentage Trend',
                          child: LineChartWidget(
                            values: const [90, 91.5, 90.8, 92, 92.5, 94.2, 93.8],
                            labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                            lineColor: AppColors.green,
                            height: 200,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SectionCard(
                    title: 'Fleet Run Log & Metric Details',
                    trailing: Row(
                      children: [
                        TextButton(onPressed: () {}, child: const Text('Export CSV')),
                        const SizedBox(width: 8),
                        TextButton(onPressed: () {}, child: const Text('Export PDF')),
                      ],
                    ),
                    child: _buildMetricTable(app),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTable(AppState app) {
    if (app.trips.isEmpty) {
      return const SizedBox(
        height: 200,
        child: EmptyState(message: 'No trip logging entries found.'),
      );
    }
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
        5: FlexColumnWidth(2),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Vehicle', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Driver', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Duration', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Distance', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Max Speed', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Trip Score', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
        ...app.trips.take(6).map((t) => TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(t.vehicleName, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(t.driverName ?? 'Unknown', style: const TextStyle(color: AppColors.text, fontSize: 13))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(formatDuration(t.durationSec), style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${t.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: AppColors.text, fontSize: 13))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${t.maxSpeedKmh.toStringAsFixed(0)} km/h', style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: t.totalScore >= 85 ? AppColors.green : AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('${t.totalScore.toStringAsFixed(0)}/100', style: TextStyle(color: t.totalScore >= 85 ? AppColors.green : AppColors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        )),
      ],
    );
  }
}
