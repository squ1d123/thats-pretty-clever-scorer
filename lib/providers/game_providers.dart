import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/models.dart';

enum StatsTimeRange {
  allTime('All Time', null),
  lastMonth('Last Month', 1),
  last3Months('Last 3 Months', 3),
  last6Months('Last 6 Months', 6),
  lastYear('Last Year', 12);

  final String label;
  final int? months;
  const StatsTimeRange(this.label, this.months);
}

final statsTimeRangeProvider =
    StateProvider<StatsTimeRange>((ref) => StatsTimeRange.allTime);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final gameSessionProvider =
    StateNotifierProvider<GameSessionNotifier, GameSession>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return GameSessionNotifier(db);
});

class GameSessionNotifier extends StateNotifier<GameSession> {
  final DatabaseService _db;

  GameSessionNotifier(this._db) : super(GameSession());

  void addPlayer(String name) {
    if (state.players.length >= 4) return;
    if (state.players.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      return;
    }
    state.players.add(Player(name: name));
    state = GameSession(
      id: state.id,
      createdAt: state.createdAt,
      completedAt: state.completedAt,
      players: List.from(state.players),
      winner: state.winner,
      notes: state.notes,
    );
  }

  void removePlayer(int index) {
    if (index < 0 || index >= state.players.length) return;
    state.players.removeAt(index);
    state = GameSession(
      id: state.id,
      createdAt: state.createdAt,
      completedAt: state.completedAt,
      players: List.from(state.players),
      winner: state.winner,
      notes: state.notes,
    );
  }

  void clearPlayers() {
    state = GameSession();
  }

  void calculateScores() {
    state.calculateScores();
    state = GameSession(
      id: state.id,
      createdAt: state.createdAt,
      completedAt: state.completedAt,
      players: List.from(state.players),
      winner: state.winner,
      notes: state.notes,
    );
  }

  void updatePlayerScore(String playerName, int yellow, int green, int orange,
      int purple, int blue, int foxCount) {
    for (var player in state.players) {
      if (player.name == playerName) {
        player.scoreSheet.yellow.total = yellow;
        player.scoreSheet.green.total = green;
        player.scoreSheet.orange.total = orange;
        player.scoreSheet.purple.total = purple;
        player.scoreSheet.blue.total = blue;
        player.scoreSheet.bonus.foxCount = foxCount;
        player.scoreSheet.calculateBonus();
        break;
      }
    }
    state = GameSession(
      id: state.id,
      createdAt: state.createdAt,
      completedAt: state.completedAt,
      players: List.from(state.players),
      winner: state.winner,
      notes: state.notes,
    );
  }

  Future<int> saveGame(String notes) async {
    state.notes = notes;
    state.completedAt = DateTime.now();
    return await _db.saveGame(state);
  }

  void reset() {
    state = GameSession();
  }
}

final recentPlayersProvider = FutureProvider<List<String>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return await db.getRecentPlayerNames();
});

final searchPlayersProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  final db = ref.watch(databaseServiceProvider);
  if (query.isEmpty) {
    return await db.getRecentPlayerNames();
  }
  return await db.searchPlayerNames(query);
});

final gameHistoryProvider =
    FutureProvider.family<List<GameSummary>, GameHistoryFilter>(
        (ref, filter) async {
  final db = ref.watch(databaseServiceProvider);
  return await db.getGames(
    query: filter.query,
    playerName: filter.playerName,
    sortBy: filter.sortBy,
    sortOrder: filter.sortOrder,
  );
});

class GameHistoryFilter {
  final String? query;
  final String? playerName;
  final String sortBy;
  final String sortOrder;

  GameHistoryFilter({
    this.query,
    this.playerName,
    this.sortBy = 'date',
    this.sortOrder = 'desc',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameHistoryFilter &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          playerName == other.playerName &&
          sortBy == other.sortBy &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      query.hashCode ^
      playerName.hashCode ^
      sortBy.hashCode ^
      sortOrder.hashCode;
}

final highScoresProvider = FutureProvider<List<HighScore>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return await db.getHighScores();
});

final databaseStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return await db.getDatabaseStats();
});

final gameDetailsProvider =
    FutureProvider.family<GameSession?, String>((ref, uuid) async {
  final db = ref.watch(databaseServiceProvider);
  return await db.getGameDetails(uuid);
});

final gameDetailsByIdProvider =
    FutureProvider.family<GameSession?, int>((ref, dbId) async {
  final db = ref.watch(databaseServiceProvider);
  return await db.getGameDetailsById(dbId);
});

final gamesPerMonthProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final timeRange = ref.watch(statsTimeRangeProvider);
  return await db.getGamesPerMonth(months: timeRange.months);
});

final averageScoresProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final timeRange = ref.watch(statsTimeRangeProvider);
  return await db.getAverageScoresByPlayerCount(months: timeRange.months);
});

final topPlayersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final timeRange = ref.watch(statsTimeRangeProvider);
  return await db.getTopPlayers(months: timeRange.months);
});

final scoreDistributionProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final timeRange = ref.watch(statsTimeRangeProvider);
  return await db.getScoreDistribution(months: timeRange.months);
});

final averageScoreByPositionProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final timeRange = ref.watch(statsTimeRangeProvider);
  return await db.getAverageScoreByPlayerPosition(months: timeRange.months);
});

final winPercentageByPlayerProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final timeRange = ref.watch(statsTimeRangeProvider);
  return await db.getWinPercentageByPlayer(months: timeRange.months);
});
