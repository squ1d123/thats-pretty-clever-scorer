class GameSummary {
  String? id;
  int? dbId;
  DateTime? createdAt;
  int playerCount;
  String winnerName;
  int winnerScore;

  GameSummary({
    this.id,
    this.dbId,
    this.createdAt,
    required this.playerCount,
    required this.winnerName,
    required this.winnerScore,
  });

  factory GameSummary.fromMap(Map<String, dynamic> map) {
    return GameSummary(
      id: map['uuid'] as String?,
      dbId: map['id'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      playerCount: map['player_count'] as int? ?? 0,
      winnerName: map['winner_name'] as String? ?? '',
      winnerScore: map['winner_score'] as int? ?? 0,
    );
  }
}
