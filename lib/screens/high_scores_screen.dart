import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/game_providers.dart';
import '../models/game_version.dart';

class HighScoresScreen extends ConsumerStatefulWidget {
  const HighScoresScreen({super.key});

  @override
  ConsumerState<HighScoresScreen> createState() => _HighScoresScreenState();
}

class _HighScoresScreenState extends ConsumerState<HighScoresScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedVersion = ref.watch(gameVersionFilterProvider);
    final highScoresAsync = ref.watch(highScoresProvider(selectedVersion));

    return Scaffold(
      appBar: AppBar(
        title: const Text('High Scores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<GameVersion?>(
              value: selectedVersion,
              decoration: const InputDecoration(
                labelText: 'Filter by version',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Versions'),
                ),
                ...GameVersion.values.map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.displayName),
                    )),
              ],
              onChanged: (value) {
                ref.read(gameVersionFilterProvider.notifier).state = value;
              },
            ),
          ),
          Expanded(
            child: highScoresAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (scores) {
                if (scores.isEmpty) {
                  return const Center(
                    child: Text('No high scores yet. Play some games!'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: scores.length,
                  itemBuilder: (context, index) {
                    final score = scores[index];
                    final medal = _getMedal(index);
                    return Card(
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getMedalColor(index),
                          child: Text(
                            medal,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        title: Text(
                          score.playerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Achieved ${DateFormat.yMMMd().format(score.achievedAt)}',
                        ),
                        trailing: Text(
                          '${score.score}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          if (score.gameId != null)
                            _ExpandedGameDetails(gameId: score.gameId!)
                          else
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Game details not available'),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getMedal(int index) {
    switch (index) {
      case 0:
        return '1';
      case 1:
        return '2';
      case 2:
        return '3';
      default:
        return '${index + 1}';
    }
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey[400]!;
      case 2:
        return Colors.brown[300]!;
      default:
        return Colors.blueGrey;
    }
  }
}

class _ExpandedGameDetails extends ConsumerWidget {
  final int gameId;

  const _ExpandedGameDetails({required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailsByIdProvider(gameId));

    return gameAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading game: $err'),
      ),
      data: (game) {
        if (game == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Game not found'),
          );
        }

        final players = game.players.toList()
          ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Game on ${DateFormat.yMMMd().format(game.createdAt ?? DateTime.now())}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...players.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${p.name}: ${p.totalScore} pts',
                      style: TextStyle(
                        color: p == game.winner ? Colors.green : null,
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push('/game-details/${game.id}'),
                child: const Text('View Full Game Details'),
              ),
            ],
          ),
        );
      },
    );
  }
}
