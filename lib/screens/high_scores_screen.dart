import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/game_providers.dart';

class HighScoresScreen extends ConsumerWidget {
  const HighScoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highScoresAsync = ref.watch(highScoresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('High Scores'),
      ),
      body: highScoresAsync.when(
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
                child: ListTile(
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
                ),
              );
            },
          );
        },
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
