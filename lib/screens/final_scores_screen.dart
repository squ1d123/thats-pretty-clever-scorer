import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/game_providers.dart';

class FinalScoresScreen extends ConsumerWidget {
  const FinalScoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameSession = ref.watch(gameSessionProvider);
    final players = gameSession.players;

    int maxScore = -1;
    for (var player in players) {
      if (player.totalScore > maxScore) {
        maxScore = player.totalScore;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Scores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Final Scores',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(),
            ...players.map((player) {
              final isWinner = player.totalScore == maxScore;
              return Card(
                color: isWinner ? Colors.amber[200] : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (isWinner)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.emoji_events,
                              color: Colors.black, size: 32),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isWinner
                                  ? '${player.name} (WINNER)'
                                  : player.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isWinner ? Colors.black87 : null,
                              ),
                            ),
                            Text(
                              '${player.totalScore} points',
                              style: TextStyle(
                                fontSize: 16,
                                color: isWinner ? Colors.black54 : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.pop();
          } else if (index == 1) {
            _showSaveDialog(context, ref);
          } else if (index == 2) {
            ref.read(gameSessionProvider.notifier).clearPlayers();
            context.go('/setup');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.arrow_back_outlined),
            selectedIcon: Icon(Icons.arrow_back),
            label: 'Calculator',
          ),
          NavigationDestination(
            icon: Icon(Icons.save_outlined),
            selectedIcon: Icon(Icons.save),
            label: 'Save',
          ),
          NavigationDestination(
            icon: Icon(Icons.refresh_outlined),
            selectedIcon: Icon(Icons.refresh),
            label: 'New Game',
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Game'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Enter optional notes...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final gameSession = ref.read(gameSessionProvider);
              gameSession.notes = notesController.text;
              await ref
                  .read(gameSessionProvider.notifier)
                  .saveGame(notesController.text);
              ref.invalidate(databaseStatsProvider(null));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game saved successfully!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
