import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../providers/game_providers.dart';
import '../theme/app_theme.dart';

class ScoreCalculatorScreen extends ConsumerStatefulWidget {
  const ScoreCalculatorScreen({super.key});

  @override
  ConsumerState<ScoreCalculatorScreen> createState() =>
      _ScoreCalculatorScreenState();
}

class _ScoreCalculatorScreenState extends ConsumerState<ScoreCalculatorScreen> {
  final Map<String, List<TextEditingController>> _controllers = {};

  @override
  void initState() {
    super.initState();
    final players = ref.read(gameSessionProvider).players;
    for (var player in players) {
      _initControllersForPlayer(player.name);
    }
  }

  void _initControllersForPlayer(String playerName) {
    _controllers[playerName] = List.generate(6, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (var controllers in _controllers.values) {
      for (var c in controllers) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _updateScores() {
    final notifier = ref.read(gameSessionProvider.notifier);
    final gameSession = ref.read(gameSessionProvider);
    for (var player in gameSession.players) {
      final controllers = _controllers[player.name];
      if (controllers != null) {
        notifier.updatePlayerScore(
          player.name,
          int.tryParse(controllers[0].text) ?? 0,
          int.tryParse(controllers[1].text) ?? 0,
          int.tryParse(controllers[2].text) ?? 0,
          int.tryParse(controllers[3].text) ?? 0,
          int.tryParse(controllers[4].text) ?? 0,
          int.tryParse(controllers[5].text) ?? 0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameSession = ref.watch(gameSessionProvider);
    final players = gameSession.players;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(players.length, (index) {
            final player = players[index];
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 56) / 2,
              child: _PlayerScoreCard(
                player: player,
                controllers: _controllers[player.name] ??
                    List.generate(6, (_) => TextEditingController()),
                onChanged: _updateScores,
              ),
            );
          }),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Back to Setup'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _updateScores();
                  context.push('/final-scores');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Show Final Scores'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerScoreCard extends ConsumerWidget {
  final Player player;
  final List<TextEditingController> controllers;
  final VoidCallback onChanged;

  const _PlayerScoreCard({
    required this.player,
    required this.controllers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameSession = ref.watch(gameSessionProvider);
    final currentPlayer = gameSession.players.firstWhere(
      (p) => p.name == player.name,
      orElse: () => player,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              player.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _ScoreInput(
              label: 'Yellow',
              color: AppTheme.yellowColor,
              controller: controllers[0],
              onChanged: onChanged,
            ),
            _ScoreInput(
              label: 'Green',
              color: AppTheme.greenColor,
              controller: controllers[1],
              onChanged: onChanged,
            ),
            _ScoreInput(
              label: 'Orange',
              color: AppTheme.orangeColor,
              controller: controllers[2],
              onChanged: onChanged,
            ),
            _ScoreInput(
              label: 'Purple',
              color: AppTheme.purpleColor,
              controller: controllers[3],
              onChanged: onChanged,
            ),
            _ScoreInput(
              label: 'Blue',
              color: AppTheme.blueColor,
              controller: controllers[4],
              onChanged: onChanged,
            ),
            _ScoreInput(
              label: 'Foxes',
              color: AppTheme.foxColor,
              controller: controllers[5],
              onChanged: onChanged,
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bonus:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${currentPlayer.scoreSheet.bonus.total}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${currentPlayer.scoreSheet.totalScore}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreInput extends StatelessWidget {
  final String label;
  final Color color;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _ScoreInput({
    required this.label,
    required this.color,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isFox = label.toLowerCase() == 'foxes';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (isFox)
            Padding(
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset(
                'assets/fox.svg',
                width: 24,
                height: 24,
              ),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
