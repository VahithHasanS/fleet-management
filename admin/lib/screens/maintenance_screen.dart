import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/kpi_card.dart';
import 'shell.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return PageScaffold(
      title: 'Maintenance Management',
      subtitle:
          'Schedule repairs, track work orders, monitor diagnostic codes, and check parts inventory',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: KpiCardV2(
                    label: 'Active Work Orders',
                    value: '3 Pending',
                    icon: Icons.build_circle_outlined,
                    iconColor: AppColors.amber,
                    trendText: '1 scheduled today',
                    trendUp: null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Maintenance Cost (Mo.)',
                    value: '₹42,500',
                    icon: Icons.currency_rupee,
                    iconColor: AppColors.violet,
                    trendText: '↓ 8% from last month',
                    trendUp: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Fleet Health Index',
                    value: '95%',
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.green,
                    trendText: '47/50 active vehicles operational',
                    trendUp: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Pending DTC Faults',
                    value: '1 fault',
                    icon: Icons.error_outline,
                    iconColor: AppColors.red,
                    trendText: 'GT 03 engine cylinder misfire',
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
                  flex: 3,
                  child: SectionCard(
                    title: 'Cost Breakdown by Service',
                    child: DonutChartWidget(
                      size: 150,
                      centerValue: '₹42k',
                      centerLabel: 'Total Spent',
                      sections: const [
                        DonutSection(
                          label: 'Engine Repair',
                          value: 25000,
                          color: AppColors.red,
                        ),
                        DonutSection(
                          label: 'Brakes & Tires',
                          value: 12500,
                          color: AppColors.amber,
                        ),
                        DonutSection(
                          label: 'Fluid & Battery',
                          value: 5000,
                          color: AppColors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: SectionCard(
                    title: 'Active Work Orders status',
                    child: Column(
                      children: [
                        _buildWorkOrder(
                          'WO-9281',
                          'GT 03 Transmission Repair',
                          'In Progress',
                          AppColors.accent,
                        ),
                        const Divider(),
                        _buildWorkOrder(
                          'WO-9280',
                          'GT 12 Front Tires Replacement',
                          'Scheduled',
                          AppColors.amber,
                        ),
                        const Divider(),
                        _buildWorkOrder(
                          'WO-9279',
                          'GT 01 Scheduled Oil Change',
                          'Completed',
                          AppColors.green,
                        ),
                      ],
                    ),
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
                    title: 'Upcoming Scheduled Maintenance',
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(3),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
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
                                'Vehicle',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Service Type',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Due Kilometer',
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
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'GT 01',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('10,000 km Oil & Filter Change'),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('10,500 km'),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Approaching Due',
                                  style: TextStyle(
                                    color: AppColors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'GT 05',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Brake Pad Replacement'),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('15,000 km'),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'OK Operational',
                                  style: TextStyle(
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
                    title: 'Spare Parts Inventory & Low Stock Alerts',
                    child: Column(
                      children: [
                        _buildInventoryRow(
                          'Synthetic Engine Oil (5W-30)',
                          '12 cans remaining',
                          AppColors.green,
                          0.8,
                        ),
                        const SizedBox(height: 12),
                        _buildInventoryRow(
                          'Brake Rotors (Medium Duty)',
                          '2 units left - LOW STOCK',
                          AppColors.red,
                          0.2,
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

  Widget _buildWorkOrder(
    String woId,
    String title,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            woId,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(
    String partName,
    String desc,
    Color barColor,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          partName,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            color: barColor,
            backgroundColor: AppColors.border,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
