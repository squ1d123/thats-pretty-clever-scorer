import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'games.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        player_count INTEGER NOT NULL,
        winner_name TEXT,
        winner_score INTEGER,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        final_score INTEGER NOT NULL,
        winner BOOLEAN DEFAULT FALSE,
        yellow_total INTEGER DEFAULT 0,
        green_total INTEGER DEFAULT 0,
        orange_total INTEGER DEFAULT 0,
        purple_total INTEGER DEFAULT 0,
        blue_total INTEGER DEFAULT 0,
        fox_count INTEGER DEFAULT 0,
        bonus INTEGER DEFAULT 0,
        FOREIGN KEY (game_id) REFERENCES games(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS high_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        player_name TEXT NOT NULL,
        score INTEGER NOT NULL,
        achieved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (game_id) REFERENCES games(id)
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_games_date ON games(created_at DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_games_score ON games(winner_score DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_players_game ON players(game_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_high_scores ON high_scores(score DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_players_name ON players(name)');
  }

  Future<int> saveGame(GameSession session) async {
    final db = await database;

    session.id ??= DateTime.now().millisecondsSinceEpoch.toString();
    session.createdAt ??= DateTime.now();
    session.completedAt ??= DateTime.now();

    Player? winner = session.findWinner();
    session.winner = winner;

    final gameMap = session.toMap();
    gameMap['player_count'] = session.players.length;

    final gameId = await db.insert('games', gameMap);

    for (Player player in session.players) {
      final playerMap = player.toMap(gameId);
      playerMap['winner'] = (player == winner) ? 1 : 0;
      await db.insert('players', playerMap);

      final highScore = HighScore(
        gameId: gameId,
        playerName: player.name,
        score: player.totalScore,
      );
      await db.insert('high_scores', highScore.toMap());
    }

    return gameId;
  }

  Future<List<GameSummary>> getGames({
    String? query,
    String? playerName,
    String sortBy = 'date',
    String sortOrder = 'desc',
  }) async {
    final db = await database;

    String sql = 'SELECT DISTINCT g.* FROM games g';
    List<String> conditions = [];
    List<dynamic> args = [];

    if (playerName != null && playerName.isNotEmpty) {
      sql += ' JOIN players p ON g.id = p.game_id';
      conditions.add('p.name LIKE ?');
      args.add('%$playerName%');
    }

    if (query != null && query.isNotEmpty) {
      conditions.add('(g.winner_name LIKE ? OR g.notes LIKE ?)');
      args.add('%$query%');
      args.add('%$query%');
    }

    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }

    String orderColumn;
    switch (sortBy) {
      case 'score':
        orderColumn = 'g.winner_score';
        break;
      case 'player_count':
        orderColumn = 'g.player_count';
        break;
      default:
        orderColumn = 'g.created_at';
    }

    sql += ' ORDER BY $orderColumn ${sortOrder.toUpperCase()}';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);

    return maps.map((map) => GameSummary.fromMap(map)).toList();
  }

  Future<GameSession?> getGameDetails(String uuid) async {
    final db = await database;

    final games = await db.query(
      'games',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    if (games.isEmpty) return null;

    final gameMap = games.first;
    final gameId = gameMap['id'] as int;

    final players = await db.query(
      'players',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );

    final gameSession = GameSession(
      id: gameMap['uuid'] as String?,
      createdAt: DateTime.parse(gameMap['created_at'] as String),
      completedAt: DateTime.parse(gameMap['completed_at'] as String),
      notes: gameMap['notes'] as String? ?? '',
    );

    for (var playerMap in players) {
      final player = Player(name: playerMap['name'] as String);
      player.scoreSheet.yellow.total = playerMap['yellow_total'] as int;
      player.scoreSheet.green.total = playerMap['green_total'] as int;
      player.scoreSheet.orange.total = playerMap['orange_total'] as int;
      player.scoreSheet.purple.total = playerMap['purple_total'] as int;
      player.scoreSheet.blue.total = playerMap['blue_total'] as int;
      player.scoreSheet.bonus.foxCount = playerMap['fox_count'] as int;
      player.scoreSheet.bonus.total = playerMap['bonus'] as int;
      gameSession.players.add(player);
    }

    return gameSession;
  }

  Future<List<HighScore>> getHighScores({int limit = 10}) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'high_scores',
      orderBy: 'score DESC',
      limit: limit,
    );

    return maps.map((map) => HighScore.fromMap(map)).toList();
  }

  Future<List<String>> getRecentPlayerNames({int limit = 5}) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT name FROM players 
      ORDER BY (SELECT MAX(id) FROM players p2 WHERE p2.name = players.name) 
      DESC LIMIT ?
    ''', [limit]);

    return maps.map((m) => m['name'] as String).toList();
  }

  Future<List<String>> searchPlayerNames(String query, {int limit = 20}) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT name FROM players 
      WHERE name LIKE ? ORDER BY name LIMIT ?
    ''', ['%$query%', limit]);

    return maps.map((m) => m['name'] as String).toList();
  }

  int? _firstIntValue(List<Map<String, Object?>> list) {
    if (list.isNotEmpty) {
      final firstRow = list.first;
      if (firstRow.isNotEmpty) {
        return firstRow.values.first as int?;
      }
    }
    return null;
  }

  Future<int> getTotalGamesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM games');
    return _firstIntValue(result) ?? 0;
  }

  Future<int> getTotalPlayersCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(DISTINCT name) as count FROM players');
    return _firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final gamesCount = await getTotalGamesCount();
    final playersCount = await getTotalPlayersCount();

    final db = await database;
    final highScoreResult =
        await db.rawQuery('SELECT MAX(score) as max FROM high_scores');
    final highestScore = _firstIntValue(highScoreResult) ?? 0;

    return {
      'games': gamesCount,
      'players': playersCount,
      'highest_score': highestScore,
    };
  }

  Future<void> deleteGame(int gameId) async {
    final db = await database;
    await db.delete('players', where: 'game_id = ?', whereArgs: [gameId]);
    await db.delete('high_scores', where: 'game_id = ?', whereArgs: [gameId]);
    await db.delete('games', where: 'id = ?', whereArgs: [gameId]);
  }

  Future<void> deleteAllGames() async {
    final db = await database;
    await db.delete('players');
    await db.delete('high_scores');
    await db.delete('games');
  }

  Future<void> clearHighScores() async {
    final db = await database;
    await db.delete('high_scores');
  }
}
