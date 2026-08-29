import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/kpi_card.dart';
import 'shell.dart';

class DriverSafetyScreen extends StatefulWidget {
  const DriverSafetyScreen({super.key});

  @override
  State<DriverSafetyScreen> createState() => _DriverSafetyScreenState();
}

class _DriverSafetyScreenState extends State<DriverSafetyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final stats = app.stats;
    final leaderboard = app.leaderboard;
    final events = app.events;

    return PageScaffold(
      title: 'Driver Safety Dashboard',
      subtitle:
          'Monitor driver behaviors, safety scoring, events, and coaching metrics',
      actions: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Driver Scorecard'),
          Tab(text: 'Events'),
          Tab(text: 'Coaching'),
          Tab(text: 'Leaderboards'),
          Tab(text: 'Trends'),
        ],
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(stats, leaderboard, events),
          _buildScorecardTab(leaderboard),
          _buildEventsTab(events),
          _buildCoachingTab(leaderboard),
          _buildLeaderboardTab(leaderboard),
          _buildTrendsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    Stats stats,
    List<dynamic> leaderboard,
    List<dynamic> events,
  ) {
    final avgScore = stats.avgDriverScore;
    final totalEvents = events.length;

    // Safety Distribution Section
    final lowRisk = leaderboard.where((d) => d.safetyScore >= 85).length;
    final medRisk = leaderboard
        .where((d) => d.safetyScore >= 70 && d.safetyScore < 85)
        .length;
    final highRisk = leaderboard.where((d) => d.safetyScore < 70).length;
    final totalDrivers = leaderboard.isEmpty ? 1 : leaderboard.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: KpiCardV2(
                  label: 'Avg Safety Score',
                  value: avgScore.toStringAsFixed(1),
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.green,
                  trendText: '↑ 2.1% from last week',
                  trendUp: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCardV2(
                  label: 'High Risk Drivers',
                  value: '$highRisk',
                  icon: Icons.dangerous_outlined,
                  iconColor: AppColors.red,
                  trendText: '↓ 1 driver this week',
                  trendUp: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCardV2(
                  label: 'Total Safety Events',
                  value: '$totalEvents',
                  icon: Icons.warning_amber_outlined,
                  iconColor: AppColors.amber,
                  trendText: '↓ 14% vs yesterday',
                  trendUp: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCardV2(
                  label: 'Coaching Completed',
                  value: '${(totalEvents * 0.75).round()}',
                  icon: Icons.school_outlined,
                  iconColor: AppColors.violet,
                  trendText: '↑ 12 completed today',
                  trendUp: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCardV2(
                  label: 'Drivers Improved',
                  value: '${(totalDrivers * 0.4).round()}',
                  icon: Icons.trending_up,
                  iconColor: AppColors.cyan,
                  trendText: '↑ 5% increase',
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
                  title: 'Safety Score Distribution',
                  child: SizedBox(
                    height: 200,
                    child: DonutChartWidget(
                      centerValue: avgScore.toStringAsFixed(0),
                      centerLabel: 'Avg Score',
                      sections: [
                        DonutSection(
                          label: 'Low Risk (85-100)',
                          value: lowRisk,
                          color: AppColors.green,
                          percentage: ((lowRisk / totalDrivers) * 100).round(),
                        ),
                        DonutSection(
                          label: 'Medium Risk (70-84)',
                          value: medRisk,
                          color: AppColors.amber,
                          percentage: ((medRisk / totalDrivers) * 100).round(),
                        ),
                        DonutSection(
                          label: 'High Risk (<70)',
                          value: highRisk,
                          color: AppColors.red,
                          percentage: ((highRisk / totalDrivers) * 100).round(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: SectionCard(
                  title: 'Weekly Score Trend',
                  child: LineChartWidget(
                    values: const [82, 83.5, 84, 83.8, 85, 85.8, 86.2],
                    labels: const [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ],
                    lineColor: AppColors.accent,
                    height: 200,
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
                  title: 'Top Drivers (Safety Leaderboard)',
                  child: _buildDriverTable(leaderboard.take(5).toList()),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: SectionCard(
                  title: 'Recent Safety Events',
                  child: _buildRecentEventsList(events.take(5).toList()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverTable(List<dynamic> drivers) {
    if (drivers.isEmpty) {
      return const SizedBox(
        height: 200,
        child: EmptyState(message: 'No drivers loaded yet.'),
      );
    }
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(4),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '#',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Driver',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Safety Score',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Trips',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Status',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        ...drivers.map((d) {
          final score = d.safetyScore;
          final scoreColor = score >= 85
              ? AppColors.green
              : score >= 70
              ? AppColors.amber
              : AppColors.red;
          return TableRow(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '${d.rank}',
                  style: const TextStyle(color: AppColors.text, fontSize: 13),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  d.name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scoreColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${score.toStringAsFixed(0)}/100',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '${d.tripsCount}',
                  style: const TextStyle(color: AppColors.text, fontSize: 13),
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
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Compliant',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildRecentEventsList(List<dynamic> events) {
    if (events.isEmpty) {
      return const SizedBox(
        height: 200,
        child: EmptyState(message: 'No safety events recorded.'),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = events[i];
        final severityColor = AppColors.severityColor(e.severity);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(eventIcon(e.type), color: severityColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventLabel(e.type),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${e.vehicleName ?? 'Vehicle'} · Driver ID: ${e.driverId ?? 'N/A'}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SeverityBadge(e.severity),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(e.timestamp),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScorecardTab(List<dynamic> leaderboard) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Safety Score Factors',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              _buildFactorCard(
                'Harsh Braking',
                'Impact on safety score: High',
                92,
                AppColors.green,
              ),
              _buildFactorCard(
                'Harsh Acceleration',
                'Impact on safety score: Low',
                88,
                AppColors.green,
              ),
              _buildFactorCard(
                'Harsh Cornering',
                'Impact on safety score: Medium',
                79,
                AppColors.amber,
              ),
              _buildFactorCard(
                'Speeding Incidents',
                'Impact on safety score: Critical',
                65,
                AppColors.red,
              ),
              _buildFactorCard(
                'Distracted Driving',
                'Impact on safety score: High',
                98,
                AppColors.green,
              ),
              _buildFactorCard(
                'Seatbelt Usage',
                'Impact on safety score: High',
                100,
                AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Driver Scores Breakdown',
            child: _buildDriverTable(leaderboard),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorCard(
    String title,
    String subtitle,
    double score,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              color: color,
              backgroundColor: AppColors.border,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(List<dynamic> events) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Full Incident History',
            trailing: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Export CSV'),
            ),
            child: _buildEventsTable(events),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTable(List<dynamic> events) {
    if (events.isEmpty) {
      return const SizedBox(
        height: 200,
        child: EmptyState(message: 'No safety incidents found.'),
      );
    }
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
        5: FlexColumnWidth(2),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Incident',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Severity',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Vehicle',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Driver ID',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Timestamp',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Action',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        ...events.map((e) {
          return TableRow(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      eventIcon(e.type),
                      color: AppColors.severityColor(e.severity),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      eventLabel(e.type),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SeverityBadge(e.severity),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  e.vehicleName ?? 'N/A',
                  style: const TextStyle(color: AppColors.text, fontSize: 13),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  e.driverId ?? 'N/A',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _formatDateTime(e.timestamp),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Review', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCoachingTab(List<dynamic> leaderboard) {
    final coachedDrivers = leaderboard.take(3).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Coaching Sessions',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: coachedDrivers.length,
            itemBuilder: (context, idx) {
              final d = coachedDrivers[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.violet.withOpacity(0.2),
                        child: const Icon(
                          Icons.school,
                          color: AppColors.violet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Speeding Remedial Course for ${d.name}',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Driver score is ${d.safetyScore.toStringAsFixed(0)} due to frequent speeding alerts in GT 01.',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Assign Session'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(List<dynamic> leaderboard) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Fleet-wide Safety Rankings',
            child: _buildDriverTable(leaderboard),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionCard(
                  title: 'Safety Incidents over Time (30 Days)',
                  child: LineChartWidget(
                    values: const [
                      45,
                      38,
                      42,
                      35,
                      30,
                      25,
                      20,
                      18,
                      15,
                      12,
                      10,
                      8,
                    ],
                    labels: const [
                      'W1',
                      'W2',
                      'W3',
                      'W4',
                      'W5',
                      'W6',
                      'W7',
                      'W8',
                      'W9',
                      'W10',
                      'W11',
                      'W12',
                    ],
                    lineColor: AppColors.red,
                    height: 200,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: SectionCard(
                  title: 'Average Safety Score Improvement',
                  child: LineChartWidget(
                    values: const [
                      78,
                      79,
                      81,
                      82,
                      82.5,
                      83.8,
                      85,
                      85.5,
                      86.2,
                      87,
                      87.5,
                      88.2,
                    ],
                    labels: const [
                      'W1',
                      'W2',
                      'W3',
                      'W4',
                      'W5',
                      'W6',
                      'W7',
                      'W8',
                      'W9',
                      'W10',
                      'W11',
                      'W12',
                    ],
                    lineColor: AppColors.green,
                    height: 200,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
