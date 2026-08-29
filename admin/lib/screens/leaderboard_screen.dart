import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final entries = app.leaderboard;
    return PageScaffold(
      title: 'Safety Leaderboard',
      child: entries.isEmpty
          ? const EmptyState(
              message: 'Leaderboard is empty. Start the phantom fleet so trips produce weighted penalty scores + positive-driving points.')
          : Column(
              children: [
                for (final (i, e) in entries.indexed) _Row(entry: e, rank: i + 1),
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final dynamic entry;
  final int rank;
  const _Row({required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final isTop = rank <= 3;
    final medal = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : AppColors.textMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isTop ? medal.withOpacity(0.5) : AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: medal.withOpacity(0.2),
              child: Text('#$rank',
                  style: TextStyle(
                      color: medal, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name,
                    style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${e.tripsCount} trips · +${e.positivePoints} positive pts',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          ScoreGauge(score: e.safetyScore, size: 52),
        ],
      ),
    );
  }
}
