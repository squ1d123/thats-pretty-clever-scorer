import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/game_providers.dart';
import '../models/game_version.dart';

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

  Widget _buildColorPreview(GameVersion version) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Colors: ${version.colorNames.join(", ")}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: version.colors.map((color) {
                return Expanded(
                  child: Container(
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
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
              'Select Game Version:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<GameVersion>(
              segments: GameVersion.values
                  .where((v) => v != GameVersion.all)
                  .map((v) => ButtonSegment(
                        value: v,
                        label: Text(v.displayName),
                      ))
                  .toList(),
              selected: {gameSession.gameVersion},
              onSelectionChanged: (selected) {
                ref
                    .read(gameSessionProvider.notifier)
                    .setGameVersion(selected.first);
              },
            ),
            const SizedBox(height: 8),
            _buildColorPreview(gameSession.gameVersion),
            const SizedBox(height: 16),
            const Divider(),
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
            const Text('Quick Add:',
                style: TextStyle(fontStyle: FontStyle.italic)),
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
                        ref
                            .read(gameSessionProvider.notifier)
                            .removePlayer(index);
                      },
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      bottomNavigationBar: players.isEmpty
          ? null
          : NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (index) {
                if (index == 1) {
                  ref.read(gameSessionProvider.notifier).calculateScores();
                  context.push('/calculator');
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calculate_outlined),
                  selectedIcon: Icon(Icons.calculate),
                  label: 'Calculator',
                ),
              ],
            ),
    );
  }
}
