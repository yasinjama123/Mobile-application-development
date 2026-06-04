import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db  = context.read<AppProvider>().db;
    final uid = context.read<AppProvider>().firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Community Leaderboard')),
      body: StreamBuilder<List<LeaderboardEntry>>(
        stream: db.leaderboardStream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary));
          }
          final entries = snap.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('No data yet',
                style: TextStyle(color: AppColors.gray400)));
          }

          return CustomScrollView(
            slivers: [
              // Top 3 podium
              if (entries.length >= 3)
                SliverToBoxAdapter(child: _Podium(entries: entries.take(3).toList())),
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(children: [
                    const Text('RANK', style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w600, color: AppColors.gray400,
                        letterSpacing: 0.5)),
                    const SizedBox(width: 16),
                    const Expanded(child: Text('USER', style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w600, color: AppColors.gray400,
                        letterSpacing: 0.5))),
                    const Text('REPORTS', style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w600, color: AppColors.gray400,
                        letterSpacing: 0.5)),
                    const SizedBox(width: 16),
                    const Text('POINTS', style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w600, color: AppColors.gray400,
                        letterSpacing: 0.5)),
                  ]),
                ),
              ),
              // List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final e        = entries[i];
                      final isMe     = e.uid == uid;
                      final rankIcon = e.rank == 1 ? '🥇' : e.rank == 2 ? '🥈' : e.rank == 3 ? '🥉' : null;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primaryLight
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMe
                                ? AppColors.primary
                                : const Color(0x14000000),
                            width: isMe ? 1 : 0.5,
                          ),
                        ),
                        child: Row(children: [
                          SizedBox(width: 36,
                            child: rankIcon != null
                                ? Text(rankIcon,
                                    style: const TextStyle(fontSize: 20))
                                : Text('#${e.rank}',
                                    style: TextStyle(fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isMe ? AppColors.primary : AppColors.gray400)),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.primary : AppColors.gray100,
                              shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                e.displayName.isNotEmpty
                                    ? e.displayName[0].toUpperCase() : '?',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: isMe ? Colors.white : AppColors.gray800)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Text(e.displayName,
                                    style: TextStyle(fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isMe ? AppColors.primaryDark : null)),
                                if (isMe) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Text('You',
                                        style: TextStyle(fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ]),
                            ]),
                          ),
                          Text('${e.reportCount}',
                              style: const TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray800)),
                          const SizedBox(width: 24),
                          Row(children: [
                            const Text('⭐ ', style: TextStyle(fontSize: 12)),
                            Text('${e.points}',
                                style: const TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.amber)),
                          ]),
                        ]),
                      );
                    },
                    childCount: entries.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    final order = entries.length >= 3
        ? [entries[1], entries[0], entries[2]]
        : entries;
    final heights = [100.0, 130.0, 80.0];
    final medals  = ['🥈', '🥇', '🥉'];
    final colors  = [
      AppColors.gray100, AppColors.amber.withOpacity(0.2), AppColors.accentLight
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.asMap().entries.map((e) {
          final entry = e.value;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(medals[e.key], style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(entry.displayName.split(' ').first,
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text('${entry.points} pts',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.gray400)),
                const SizedBox(height: 6),
                Container(
                  height: heights[e.key],
                  decoration: BoxDecoration(
                    color: colors[e.key],
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                  ),
                  child: Center(
                    child: Text('#${entry.rank}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
