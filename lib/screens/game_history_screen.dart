import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/game_providers.dart';

class GameHistoryScreen extends ConsumerStatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  ConsumerState<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends ConsumerState<GameHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'date';
  String _sortOrder = 'desc';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = GameHistoryFilter(
      query: _searchController.text.isEmpty ? null : _searchController.text,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    final gamesAsync = ref.watch(gameHistoryProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search games...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Sort by: '),
                    DropdownButton<String>(
                      value: _sortBy,
                      items: const [
                        DropdownMenuItem(value: 'date', child: Text('Date')),
                        DropdownMenuItem(value: 'score', child: Text('Score')),
                        DropdownMenuItem(
                            value: 'player_count', child: Text('Players')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _sortOrder == 'desc'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                      ),
                      onPressed: () {
                        setState(() {
                          _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: gamesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (games) {
                if (games.isEmpty) {
                  return const Center(
                    child: Text('No games found'),
                  );
                }
                return ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${game.winnerName}: ${game.winnerScore} pts',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${game.playerCount} players • ${game.createdAt != null ? DateFormat.yMMMd().format(game.createdAt!) : 'Unknown date'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/game-details/${game.id}'),
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
}
