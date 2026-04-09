import 'game_version.dart';

class GameSummary {
  String? id;
  int? dbId;
  DateTime? createdAt;
  int playerCount;
  String winnerName;
  int winnerScore;
  GameVersion gameVersion;

  GameSummary({
    this.id,
    this.dbId,
    this.createdAt,
    required this.playerCount,
    required this.winnerName,
    required this.winnerScore,
    this.gameVersion = GameVersion.v1,
  });

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    final cleaned = str.replaceAll(RegExp(r'\s+m=\+\d+\.\d+'), '');
    try {
      return DateTime.parse(cleaned);
    } catch (_) {
      try {
        return DateTime.parse(str.split(' ').take(2).join(' '));
      } catch (_) {
        return null;
      }
    }
  }

  factory GameSummary.fromMap(Map<String, dynamic> map) {
    return GameSummary(
      id: map['uuid'] as String?,
      dbId: map['id'] as int?,
      createdAt: _parseDateTime(map['created_at']),
      playerCount: map['player_count'] as int? ?? 0,
      winnerName: map['winner_name'] as String? ?? '',
      winnerScore: map['winner_score'] as int? ?? 0,
      gameVersion: GameVersion.fromId(map['game_version'] as String?),
    );
  }
}
