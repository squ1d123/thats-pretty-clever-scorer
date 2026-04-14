import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player.dart';
import '../../providers/game_providers.dart';
import '../../theme/app_theme.dart';
import 'score_display_row.dart';

enum PlayerCardMode { input, display }

class PlayerScoreCard extends ConsumerWidget {
  final Player player;
  final List<Color> colors;
  final List<String> colorNames;
  final List<TextEditingController>? controllers;
  final VoidCallback? onChanged;
  final PlayerCardMode mode;
  final bool isWinner;

  const PlayerScoreCard({
    super.key,
    required this.player,
    required this.colors,
    required this.colorNames,
    this.controllers,
    this.onChanged,
    this.mode = PlayerCardMode.display,
    this.isWinner = false,
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
      color: isWinner ? Colors.amber[200] : null,
      shape: isWinner
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade700, width: 1),
            ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            if (mode == PlayerCardMode.input)
              ..._buildInputRows()
            else
              ..._buildDisplayRows(),
            const Divider(),
            _buildBonusRow(currentPlayer),
            const SizedBox(height: 8),
            _buildTotalRow(currentPlayer),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.emoji_events, color: Colors.orange, size: 24),
          ),
        Text(
          isWinner ? '${player.name} (WINNER)' : player.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isWinner ? Colors.black87 : null,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildInputRows() {
    return [
      ScoreInputRow(
        label: colorNames[0],
        color: colors[0],
        controller: controllers![0],
        onChanged: onChanged!,
      ),
      ScoreInputRow(
        label: colorNames[1],
        color: colors[1],
        controller: controllers![1],
        onChanged: onChanged!,
      ),
      ScoreInputRow(
        label: colorNames[2],
        color: colors[2],
        controller: controllers![2],
        onChanged: onChanged!,
      ),
      ScoreInputRow(
        label: colorNames[3],
        color: colors[3],
        controller: controllers![3],
        onChanged: onChanged!,
      ),
      ScoreInputRow(
        label: colorNames[4],
        color: colors[4],
        controller: controllers![4],
        onChanged: onChanged!,
      ),
      ScoreInputRow(
        label: 'Foxes',
        color: AppTheme.foxColor,
        controller: controllers![5],
        onChanged: onChanged!,
        isFox: true,
      ),
    ];
  }

  List<Widget> _buildDisplayRows() {
    return [
      ScoreDisplayRow(
        label: colorNames[0],
        value: player.scoreSheet.yellow.total,
        color: colors[0],
        isWinner: isWinner,
      ),
      ScoreDisplayRow(
        label: colorNames[1],
        value: player.scoreSheet.green.total,
        color: colors[1],
        isWinner: isWinner,
      ),
      ScoreDisplayRow(
        label: colorNames[2],
        value: player.scoreSheet.orange.total,
        color: colors[2],
        isWinner: isWinner,
      ),
      ScoreDisplayRow(
        label: colorNames[3],
        value: player.scoreSheet.purple.total,
        color: colors[3],
        isWinner: isWinner,
      ),
      ScoreDisplayRow(
        label: colorNames[4],
        value: player.scoreSheet.blue.total,
        color: colors[4],
        isWinner: isWinner,
      ),
      ScoreDisplayRow(
        label: 'Foxes',
        value: player.scoreSheet.bonus.foxCount,
        color: AppTheme.foxColor,
        isWinner: isWinner,
      ),
      ScoreDisplayRow(
        label: 'Bonus',
        value: player.scoreSheet.bonus.total,
        color: AppTheme.bonusColor,
        isWinner: isWinner,
      ),
    ];
  }

  Widget _buildBonusRow(Player currentPlayer) {
    return Row(
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
    );
  }

  Widget _buildTotalRow(Player currentPlayer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isWinner ? Colors.black87 : null,
          ),
        ),
        Text(
          '${currentPlayer.totalScore}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isWinner ? Colors.black87 : null,
          ),
        ),
      ],
    );
  }
}
