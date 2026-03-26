import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/game_providers.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<String> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadRecentPlayers();
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentPlayers() async {
    final db = ref.read(databaseServiceProvider);
    final players = await db.getRecentPlayerNames();
    if (mounted) {
      setState(() {
        _searchResults = players;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final db = ref.read(databaseServiceProvider);
      List<String> players;
      if (query.isEmpty) {
        players = await db.getRecentPlayerNames();
      } else {
        players = await db.searchPlayerNames(query);
      }
      if (mounted) {
        setState(() {
          _searchResults = players;
        });
      }
    });
  }

  void _addPlayer(String name) {
    if (name.trim().isEmpty) return;
    ref.read(gameSessionProvider.notifier).addPlayer(name.trim());
    _playerNameController.clear();
    _loadRecentPlayers();
  }

  @override
  Widget build(BuildContext context) {
    final gameSession = ref.watch(gameSessionProvider);
    final players = gameSession.players;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Players (1-4 players):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search players...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 8),
            const Text('Quick Add:', style: TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            if (_searchResults.isEmpty)
              const Text('No previous players found')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _searchResults.map((name) {
                  return ActionChip(
                    label: Text(name),
                    onPressed: () => _addPlayer(name),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('Or Enter Name:',
                style: TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _playerNameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter player name',
                    ),
                    onSubmitted: _addPlayer,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addPlayer(_playerNameController.text),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('Current Players:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (players.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No players added yet'),
                ),
              )
            else
              ...List.generate(players.length, (index) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(players[index].name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ref.read(gameSessionProvider.notifier).removePlayer(index);
                      },
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: players.isEmpty
                  ? null
                  : () {
                      ref.read(gameSessionProvider.notifier).calculateScores();
                      context.push('/calculator');
                    },
              icon: const Icon(Icons.calculate),
              label: const Text('Open Score Calculator'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
