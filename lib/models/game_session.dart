import 'player.dart';
import 'game_version.dart';

class GameSession {
  String? id;
  DateTime? createdAt;
  DateTime? completedAt;
  List<Player> players;
  Player? winner;
  String notes;
  GameVersion gameVersion;

  GameSession({
    this.id,
    this.createdAt,
    this.completedAt,
    List<Player>? players,
    this.winner,
    this.notes = '',
    this.gameVersion = GameVersion.v1,
  }) : players = players ?? [];

  String get winnerName => winner?.name ?? '';
  int get winnerScore => winner?.totalScore ?? 0;

  Player? findWinner() {
    if (players.isEmpty) return null;

    Player? highestPlayer;
    int highestScore = -1;

    for (Player player in players) {
      if (player.totalScore > highestScore) {
        highestScore = player.totalScore;
        highestPlayer = player;
      }
    }

    return highestPlayer;
  }

  void calculateScores() {
    for (Player player in players) {
      player.scoreSheet.yellow.calculateScore();
      player.scoreSheet.green.calculateScore();
      player.scoreSheet.orange.calculateScore();
      player.scoreSheet.purple.calculateScore();
      player.scoreSheet.blue.calculateScore();
      player.scoreSheet.calculateBonus();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': id,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'player_count': players.length,
      'winner_name': winnerName,
      'winner_score': winnerScore,
      'notes': notes,
      'game_version': gameVersion.id,
    };
  }
}
