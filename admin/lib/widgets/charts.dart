import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../theme/app_theme.dart';

/// A reusable donut chart widget used for Vehicle Status, Driver Status,
/// Safety Score Distribution, etc.
class DonutChartWidget extends StatelessWidget {
  final List<DonutSection> sections;
  final String centerLabel;
  final String centerValue;
  final double size;
  final bool showLegend;

  const DonutChartWidget({
    super.key,
    required this.sections,
    required this.centerLabel,
    required this.centerValue,
    this.size = 180,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections
                      .map(
                        (s) => PieChartSectionData(
                          value: s.value.toDouble(),
                          color: s.color,
                          radius: 22,
                          showTitle: false,
                        ),
                      )
                      .toList(),
                  centerSpaceRadius: size * 0.32,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerValue,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    centerLabel,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showLegend) ...[
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections.map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${s.value}',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (s.percentage != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${s.percentage}%)',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class DonutSection {
  final String label;
  final int value;
  final Color color;
  final int? percentage;

  const DonutSection({
    required this.label,
    required this.value,
    required this.color,
    this.percentage,
  });
}

/// Reusable line chart widget for trend data.
class LineChartWidget extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final bool showArea;
  final double height;
  final String? tooltipPrefix;

  const LineChartWidget({
    super.key,
    required this.values,
    required this.labels,
    this.lineColor = AppColors.accent,
    this.showArea = true,
    this.height = 200,
    this.tooltipPrefix,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);

    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    final maxY = values.reduce((a, b) => a > b ? a : b);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 4 : 10,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border.withOpacity(0.5),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: labels.length > 7 ? 2 : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[idx],
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (values.length - 1).toDouble(),
          minY: (minY - range * 0.1).clamp(0, double.infinity),
          maxY: maxY + range * 0.1,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '${tooltipPrefix ?? ''}${s.y.toStringAsFixed(0)}',
                      TextStyle(
                        color: lineColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 3.5,
                  color: lineColor,
                  strokeWidth: 2,
                  strokeColor: AppColors.surface,
                ),
              ),
              belowBarData: showArea
                  ? BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.08),
                    )
                  : BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal bar chart for displaying ranked items.
class HorizontalBarChartWidget extends StatelessWidget {
  final List<BarItem> items;
  final double height;

  const HorizontalBarChartWidget({
    super.key,
    required this.items,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return SizedBox(height: height);
    final maxVal =
        items.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        final progress = maxVal > 0 ? item.value / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${item.value}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class BarItem {
  final String label;
  final int value;
  final Color color;
  const BarItem({
    required this.label,
    required this.value,
    this.color = AppColors.red,
  });
}
