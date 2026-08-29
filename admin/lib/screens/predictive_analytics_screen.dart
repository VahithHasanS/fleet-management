import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/kpi_card.dart';
import 'shell.dart';

class PredictiveAnalyticsScreen extends StatefulWidget {
  const PredictiveAnalyticsScreen({super.key});

  @override
  State<PredictiveAnalyticsScreen> createState() =>
      _PredictiveAnalyticsScreenState();
}

class _PredictiveAnalyticsScreenState extends State<PredictiveAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return PageScaffold(
      title: 'Predictive Analytics',
      subtitle:
          'AI-driven accident forecasts, vehicle risk profiling, and predictive maintenance schedules',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: KpiCardV2(
                    label: 'Accident Risk Probability',
                    value: '0.4%',
                    icon: Icons.shield_outlined,
                    iconColor: AppColors.green,
                    trendText: '↓ 0.2% improvement',
                    trendUp: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Predictive Service Cycles',
                    value: '3 Vehicles',
                    icon: Icons.build_circle_outlined,
                    iconColor: AppColors.amber,
                    trendText: 'Forecasted in 15 days',
                    trendUp: null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'AI Driver Safety Score',
                    value: '88/100',
                    icon: Icons.psychology_outlined,
                    iconColor: AppColors.violet,
                    trendText: '↑ 2.5 points increase',
                    trendUp: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Model Confidence',
                    value: '94%',
                    icon: Icons.offline_bolt_outlined,
                    iconColor: AppColors.cyan,
                    trendText: 'Based on time-series telemetry',
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
                    title: 'High-Risk Vehicles Forecasted (Next 30 Days)',
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(3),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                        4: FlexColumnWidth(3),
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
                                'Risk Profile',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Prob. (AI)',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Confidence',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Primary Threat Factor',
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
                                'GT 01 (Arun Kumar)',
                                style: TextStyle(
                                  color: AppColors.text,
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
                                  color: AppColors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'High Risk Profile',
                                  style: TextStyle(
                                    color: AppColors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                '14.2%',
                                style: TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('96%'),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Repeated speeding + late HOS driving',
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
                                'GT 03 (Vijay Kumar)',
                                style: TextStyle(
                                  color: AppColors.text,
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
                                  color: AppColors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Medium Risk Profile',
                                  style: TextStyle(
                                    color: AppColors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                '6.8%',
                                style: TextStyle(
                                  color: AppColors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('88%'),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Brake temperature sensor flags'),
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
                    title: 'AI Incident Recommendations',
                    child: Column(
                      children: [
                        _buildRecommendation(
                          'Coaching Trigger',
                          'Assign GT 01 arun.kumar to harsh brake remediation module immediately to decrease hazard potential by 30%.',
                          AppColors.violet,
                        ),
                        const SizedBox(height: 12),
                        _buildRecommendation(
                          'Predictive Maintenance',
                          'GT 03 shows high transmission friction patterns. Flag for transmission check within 7 days.',
                          AppColors.amber,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SectionCard(
                    title: 'Risk score distribution across Coimbatore',
                    child: DonutChartWidget(
                      size: 150,
                      centerValue: '85%',
                      centerLabel: 'Safe',
                      sections: const [
                        DonutSection(
                          label: 'Safe (0-5% Risk)',
                          value: 45,
                          color: AppColors.green,
                        ),
                        DonutSection(
                          label: 'Moderate (5-15% Risk)',
                          value: 4,
                          color: AppColors.amber,
                        ),
                        DonutSection(
                          label: 'Severe (>15% Risk)',
                          value: 1,
                          color: AppColors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SectionCard(
                    title: 'Accident Risk Trend Forecast (Quarterly)',
                    child: LineChartWidget(
                      values: const [0.8, 0.75, 0.62, 0.55, 0.48, 0.4, 0.38],
                      labels: const ['Q1', 'Q2', 'Q3', 'Q4', 'Q5', 'Q6', 'Q7'],
                      lineColor: AppColors.cyan,
                      height: 200,
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

  Widget _buildRecommendation(String type, String desc, Color accentColor) {
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
              Icon(Icons.psychology, color: accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                type,
                style: TextStyle(
                  color: accentColor,
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
