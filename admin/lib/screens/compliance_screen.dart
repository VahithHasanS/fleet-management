import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/kpi_card.dart';
import 'shell.dart';

class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return PageScaffold(
      title: 'Compliance Dashboard',
      subtitle:
          'Oversee ELD Compliance, Hours of Service (HOS) violations, and DVIR logs',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: KpiCardV2(
                    label: 'Compliance Rating',
                    value: '98.4%',
                    icon: Icons.assignment_turned_in,
                    iconColor: AppColors.green,
                    trendText: '↑ 0.5% this month',
                    trendUp: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Pending DVIR Signoffs',
                    value: '4',
                    icon: Icons.rate_review,
                    iconColor: AppColors.amber,
                    trendText: '4 submitted today',
                    trendUp: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'ELD Violations',
                    value: '0',
                    icon: Icons.gavel,
                    iconColor: AppColors.green,
                    trendText: 'No critical violations',
                    trendUp: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Expiring CDL Docs',
                    value: '2',
                    icon: Icons.description,
                    iconColor: AppColors.red,
                    trendText: 'Within 30 days',
                    trendUp: null,
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
                    title: 'FMCSA Regulation Distribution',
                    child: DonutChartWidget(
                      size: 150,
                      centerValue: '98%',
                      centerLabel: 'On Time',
                      sections: const [
                        DonutSection(
                          label: 'HOS Logs Valid',
                          value: 42,
                          color: AppColors.green,
                        ),
                        DonutSection(
                          label: 'DVIR Inspections',
                          value: 38,
                          color: AppColors.cyan,
                        ),
                        DonutSection(
                          label: 'Expiring License Alert',
                          value: 2,
                          color: AppColors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: SectionCard(
                    title: 'ELD / HOS Log Edit History',
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        _ViolationRow(
                          time: '18:44',
                          driver: 'Arun Kumar',
                          status: 'HOS Log Edit Request',
                          desc: 'Sleeper berth adjustmentGT 01',
                          color: AppColors.amber,
                        ),
                        Divider(),
                        _ViolationRow(
                          time: '15:20',
                          driver: 'Vijay Kumar',
                          status: 'DVIR Defect Created',
                          desc: 'Brake fluid level low in GT 03',
                          color: AppColors.red,
                        ),
                        Divider(),
                        _ViolationRow(
                          time: '12:05',
                          driver: 'Rahul Dev',
                          status: 'Log Certified',
                          desc: '14-hour cycle certified GT 05',
                          color: AppColors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionCard(
              title: 'Expiring Driver Documents & Credentials',
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
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
                          'Driver',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Document Type',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Document No.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Expiry Date',
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
                        bottom: BorderSide(color: AppColors.border, width: 0.5),
                      ),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Vijay Kumar',
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Commercial DL'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('DL-339281-COI'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          '2026-09-15',
                          style: TextStyle(color: AppColors.amber),
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
                            color: AppColors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Expiring Soon',
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
                        bottom: BorderSide(color: AppColors.border, width: 0.5),
                      ),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Rahul Dev',
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Medical Certificate'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('MC-920192-TN'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          '2026-09-02',
                          style: TextStyle(color: AppColors.red),
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
                            color: AppColors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Critical Warning',
                            style: TextStyle(
                              color: AppColors.red,
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
          ],
        ),
      ),
    );
  }
}

class _ViolationRow extends StatelessWidget {
  final String time;
  final String driver;
  final String status;
  final String desc;
  final Color color;

  const _ViolationRow({
    required this.time,
    required this.driver,
    required this.status,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Driver: $driver',
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
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
