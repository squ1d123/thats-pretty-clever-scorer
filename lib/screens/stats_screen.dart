import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/game_providers.dart';

enum StatsTimeRange {
  allTime('All Time', null),
  lastMonth('Last Month', 1),
  last3Months('Last 3 Months', 3),
  last6Months('Last 6 Months', 6),
  lastYear('Last Year', 12);

  final String label;
  final int? months;
  const StatsTimeRange(this.label, this.months);
}

final statsTimeRangeProvider =
    StateProvider<StatsTimeRange>((ref) => StatsTimeRange.allTime);

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeRange = ref.watch(statsTimeRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          PopupMenuButton<StatsTimeRange>(
            initialValue: timeRange,
            onSelected: (range) =>
                ref.read(statsTimeRangeProvider.notifier).state = range,
            itemBuilder: (context) => StatsTimeRange.values
                .map((range) => PopupMenuItem(
                      value: range,
                      child: Text(range.label),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.date_range),
                  const SizedBox(width: 8),
                  Text(timeRange.label),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ref.watch(databaseStatsProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (stats) {
              if (stats['games'] == 0) {
                return const Center(
                  child: Text('No games to display statistics for yet.'),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOverviewCards(context, stats),
                    const SizedBox(height: 24),
                    _buildGamesPerMonthChart(context, ref),
                    const SizedBox(height: 24),
                    _buildAverageScoresChart(context, ref),
                    const SizedBox(height: 24),
                    _buildWinDistributionChart(context, ref),
                    const SizedBox(height: 24),
                    _buildTopPlayersList(context, ref),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Games',
            value: stats['games']?.toString() ?? '0',
            icon: Icons.sports_esports,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Total Players',
            value: stats['players']?.toString() ?? '0',
            icon: Icons.people,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Highest Score',
            value: stats['highest_score']?.toString() ?? '0',
            icon: Icons.emoji_events,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildGamesPerMonthChart(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(gamesPerMonthProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Games Per Month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            dataAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Text('Error: $err'),
              data: (data) {
                if (data.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('No data available')),
                  );
                }
                final maxCount = data
                    .map((e) => e['count'] as int? ?? 0)
                    .reduce((a, b) => a > b ? a : b);
                return SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (maxCount + 2).toDouble(),
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= data.length)
                                return const Text('');
                              final month =
                                  data[value.toInt()]['month'] as String?;
                              if (month == null || month.length < 5)
                                return const Text('');
                              return Text(
                                month.substring(5),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                            reservedSize: 22,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: (entry.value['count'] as int).toDouble(),
                              color: Theme.of(context).primaryColor,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageScoresChart(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(averageScoreByPositionProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Average Score by Player',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            dataAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Text('Error: $err'),
              data: (data) {
                if (data.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                        child: Text(
                            'No data available (need 2+ games with same player)')),
                  );
                }
                final maxAvg = data
                    .map((e) => (e['avg_score'] as num?)?.toDouble() ?? 0.0)
                    .reduce((a, b) => a > b ? a : b);
                return SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxAvg + 20,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= data.length)
                                return const Text('');
                              final name =
                                  data[value.toInt()]['name'] as String? ?? '';
                              if (name.isEmpty) return const Text('');
                              final displayName = name.length > 8
                                  ? '${name.substring(0, 8)}...'
                                  : name;
                              return Text(
                                displayName,
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                            reservedSize: 32,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: (entry.value['avg_score'] as num?)
                                      ?.toDouble() ??
                                  0.0,
                              color: Colors.orange,
                              width: 24,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinDistributionChart(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(winPercentageByPlayerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Win Percentage by Player',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            dataAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Text('Error: $err'),
              data: (data) {
                if (data.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                        child: Text(
                            'No data available (need 2+ games with same player)')),
                  );
                }
                final maxPct = data
                    .map(
                        (e) => (e['win_percentage'] as num?)?.toDouble() ?? 0.0)
                    .reduce((a, b) => a > b ? a : b);
                return SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxPct > 0 ? maxPct + 10 : 100,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= data.length)
                                return const Text('');
                              final name =
                                  data[value.toInt()]['name'] as String? ?? '';
                              if (name.isEmpty) return const Text('');
                              final displayName = name.length > 8
                                  ? '${name.substring(0, 8)}...'
                                  : name;
                              return Text(
                                displayName,
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                            reservedSize: 32,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.asMap().entries.map((entry) {
                        final pct = (entry.value['win_percentage'] as num?)
                                ?.toDouble() ??
                            0.0;
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: pct,
                              color: pct > 50 ? Colors.green : Colors.orange,
                              width: 24,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPlayersList(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(topPlayersProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Players by Average Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            dataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
              data: (data) {
                if (data.isEmpty) {
                  return const Text('No player data available');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final player = data[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRankColor(index),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(player['name'] as String),
                      subtitle: Text('${player['games_played']} games played'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Avg: ${(player['avg_score'] as num).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Best: ${player['max_score']}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
