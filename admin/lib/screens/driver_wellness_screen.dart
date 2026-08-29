import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/kpi_card.dart';
import 'shell.dart';

class DriverWellnessScreen extends StatefulWidget {
  const DriverWellnessScreen({super.key});

  @override
  State<DriverWellnessScreen> createState() => _DriverWellnessScreenState();
}

class _DriverWellnessScreenState extends State<DriverWellnessScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return PageScaffold(
      title: 'Driver Wellness & Fatigue Monitor',
      subtitle:
          'Analyze driver fatigue markers, stress metrics, resting indices and wellness scores',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: KpiCardV2(
                    label: 'Average Wellness Score',
                    value: '78/100',
                    icon: Icons.favorite,
                    iconColor: AppColors.cyan,
                    trendText: 'Stable this week',
                    trendUp: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'High Fatigue Drivers',
                    value: '2 Drivers',
                    icon: Icons.warning,
                    iconColor: AppColors.red,
                    trendText: 'Needs dispatch break assignment',
                    trendUp: null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Stress Index Average',
                    value: 'Low (2.4/10)',
                    icon: Icons.psychology,
                    iconColor: AppColors.green,
                    trendText: '↓ 0.5 points decline',
                    trendUp: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCardV2(
                    label: 'Active Wellness Alerts',
                    value: '1 Active Alert',
                    icon: Icons.notifications_active,
                    iconColor: AppColors.amber,
                    trendText: 'GT 02 driver arun.kumar HR high',
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
                    title: 'Wellness Score Distribution',
                    child: DonutChartWidget(
                      size: 150,
                      centerValue: '78',
                      centerLabel: 'Wellness',
                      sections: const [
                        DonutSection(
                          label: 'Excellent (>85)',
                          value: 34,
                          color: AppColors.green,
                        ),
                        DonutSection(
                          label: 'Moderate (70-84)',
                          value: 12,
                          color: AppColors.cyan,
                        ),
                        DonutSection(
                          label: 'Fatigued (<70)',
                          value: 4,
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
                    title: 'Active Fatigue Monitor (HOS Context)',
                    child: Column(
                      children: [
                        _buildFatigueRow(
                          'Arun Kumar (GT 01)',
                          '6.2/10 Moderate',
                          AppColors.amber,
                          0.62,
                        ),
                        const Divider(),
                        _buildFatigueRow(
                          'Vijay Kumar (GT 03)',
                          '8.4/10 Severe Risk',
                          AppColors.red,
                          0.84,
                        ),
                        const Divider(),
                        _buildFatigueRow(
                          'Rahul Dev (GT 05)',
                          '2.1/10 Safe Rested',
                          AppColors.green,
                          0.21,
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
                  child: SectionCard(
                    title: 'Heart Rate Average Trend during Shifts',
                    child: LineChartWidget(
                      values: const [72, 74, 73, 85, 78, 76, 75],
                      labels: const [
                        '10:00',
                        '11:00',
                        '12:00',
                        '13:00',
                        '14:00',
                        '15:00',
                        '16:00',
                      ],
                      lineColor: AppColors.cyan,
                      height: 200,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SectionCard(
                    title: 'AI Rest & Wellness Recommendations',
                    child: Column(
                      children: [
                        _buildRec(
                          'Fatigue Trigger (GT 03)',
                          'Vijay Kumar has driven 10 hours of consecutive duty limit. Recommend dispatching 2 hour nap period.',
                          AppColors.red,
                        ),
                        const SizedBox(height: 12),
                        _buildRec(
                          'HR Elevation Alert (GT 01)',
                          'Arun Kumar heart rate spike detected during harsh braking event. Suggest dispatch check-in.',
                          AppColors.amber,
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

  Widget _buildFatigueRow(
    String name,
    String level,
    Color color,
    double progress,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                level,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: AppColors.border,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRec(String header, String desc, Color color) {
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
              Icon(Icons.health_and_safety, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                header,
                style: TextStyle(
                  color: color,
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
