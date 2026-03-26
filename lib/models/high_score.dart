class HighScore {
  int? id;
  int? gameId;
  String playerName;
  int score;
  DateTime achievedAt;

  HighScore({
    this.id,
    this.gameId,
    required this.playerName,
    required this.score,
    DateTime? achievedAt,
  }) : achievedAt = achievedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'game_id': gameId,
      'player_name': playerName,
      'score': score,
      'achieved_at': achievedAt.toIso8601String(),
    };
  }

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

  factory HighScore.fromMap(Map<String, dynamic> map) {
    return HighScore(
      id: map['id'] as int?,
      gameId: map['game_id'] as int?,
      playerName: map['player_name'] as String,
      score: map['score'] as int,
      achievedAt: _parseDateTime(map['achieved_at']) ?? DateTime.now(),
    );
  }
}
