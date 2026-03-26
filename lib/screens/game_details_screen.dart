import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/game_providers.dart';
import '../theme/app_theme.dart';

class GameDetailsScreen extends ConsumerWidget {
  final String gameId;

  const GameDetailsScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailsProvider(gameId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Details'),
      ),
      body: gameAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (game) {
          if (game == null) {
            return const Center(child: Text('Game not found'));
          }

          int maxScore = -1;
          for (var player in game.players) {
            if (player.totalScore > maxScore) {
              maxScore = player.totalScore;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Played on ${game.createdAt != null ? DateFormat.yMMMd().add_jm().format(game.createdAt!) : 'Unknown'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (game.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Notes: ${game.notes}'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Players',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...game.players.map((player) {
                  final isWinner = player.totalScore == maxScore;
                  return Card(
                    color: isWinner ? Colors.amber[100] : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isWinner)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.emoji_events,
                                      color: Colors.amber),
                                ),
                              Text(
                                player.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ScoreRow(
                              label: 'Yellow',
                              value: player.scoreSheet.yellow.total,
                              color: AppTheme.yellowColor),
                          _ScoreRow(
                              label: 'Green',
                              value: player.scoreSheet.green.total,
                              color: AppTheme.greenColor),
                          _ScoreRow(
                              label: 'Orange',
                              value: player.scoreSheet.orange.total,
                              color: AppTheme.orangeColor),
                          _ScoreRow(
                              label: 'Purple',
                              value: player.scoreSheet.purple.total,
                              color: AppTheme.purpleColor),
                          _ScoreRow(
                              label: 'Blue',
                              value: player.scoreSheet.blue.total,
                              color: AppTheme.blueColor),
                          _ScoreRow(
                              label: 'Foxes',
                              value: player.scoreSheet.bonus.foxCount,
                              color: AppTheme.foxColor),
                          _ScoreRow(
                              label: 'Bonus',
                              value: player.scoreSheet.bonus.total,
                              color: AppTheme.bonusColor),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '${player.totalScore}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ScoreRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.getScoreAreaTextColor(label.toLowerCase()),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('$value'),
        ],
      ),
    );
  }
}
