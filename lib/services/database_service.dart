import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/game_version.dart';
import 'dart:io';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'games.db';
  static const String _customDbPathKey = 'custom_database_path';

  static String? _dbPath;
  static String? _customDbPath;

  static String get dbPath => _dbPath ?? '';

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _customDbPath = prefs.getString(_customDbPathKey);
  }

  static Future<void> setCustomDbPath(String path) async {
    final oldPath = _customDbPath;
    _customDbPath = path.isEmpty ? null : path;
    final prefs = await SharedPreferences.getInstance();
    if (_customDbPath != null) {
      await prefs.setString(_customDbPathKey, _customDbPath!);
    } else {
      await prefs.remove(_customDbPathKey);
    }
    if (_database != null && oldPath != _customDbPath) {
      await _database!.close();
      _database = null;
      _dbPath = null;
    }
  }

  static String? get customDbPath => _customDbPath;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;
    if (_customDbPath != null && _customDbPath!.isNotEmpty) {
      final isDirectory = await FileSystemEntity.isDirectory(_customDbPath!);
      if (isDirectory) {
        path = p.join(_customDbPath!, _dbName);
      } else {
        path = _customDbPath!;
      }
      final dbDir = Directory(p.dirname(path));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
    } else {
      final directory = await getApplicationDocumentsDirectory();
      path = directory.path;
      final dbDir = Directory(path);
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      path = p.join(path, _dbName);
    }
    _dbPath = path;
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE games ADD COLUMN game_version TEXT DEFAULT "v1"');
    }
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
    GameVersion? gameVersion,
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

    if (gameVersion != null) {
      conditions.add('g.game_version = ?');
      args.add(gameVersion.id);
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

    return _buildGameSession(db, gameId, gameMap);
  }

  Future<GameSession?> getGameDetailsById(int dbId) async {
    final db = await database;

    final games = await db.query(
      'games',
      where: 'id = ?',
      whereArgs: [dbId],
    );

    if (games.isEmpty) return null;

    final gameMap = games.first;
    final gameId = gameMap['id'] as int;

    return _buildGameSession(db, gameId, gameMap);
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

  Future<GameSession?> _buildGameSession(
      Database db, int gameId, Map<String, dynamic> gameMap) async {
    final players = await db.query(
      'players',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );

    final gameSession = GameSession(
      id: gameMap['uuid'] as String?,
      createdAt: _parseDateTime(gameMap['created_at']),
      completedAt: _parseDateTime(gameMap['completed_at']),
      notes: gameMap['notes'] as String? ?? '',
      gameVersion: GameVersion.fromId(gameMap['game_version'] as String?),
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

  Future<List<HighScore>> getHighScores(
      {int limit = 10, GameVersion? gameVersion}) async {
    final db = await database;

    String sql =
        'SELECT hs.* FROM high_scores hs JOIN games g ON hs.game_id = g.id';
    List<dynamic> args = [];

    if (gameVersion != null) {
      sql += ' WHERE g.game_version = ?';
      args.add(gameVersion.id);
    }

    sql += ' ORDER BY hs.score DESC LIMIT ?';
    args.add(limit);

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);

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

  Future<int> getTotalGamesCount({GameVersion? gameVersion}) async {
    final db = await database;
    String sql = 'SELECT COUNT(*) as count FROM games';
    List<dynamic> args = [];
    if (gameVersion != null) {
      sql += ' WHERE game_version = ?';
      args.add(gameVersion.id);
    }
    final result = await db.rawQuery(sql, args);
    return _firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getDatabaseStats({GameVersion? gameVersion}) async {
    final gamesCount = await getTotalGamesCount(gameVersion: gameVersion);
    final playersCount = await getTotalPlayersCount(gameVersion: gameVersion);

    final db = await database;
    String hsSql = 'SELECT MAX(score) as max FROM high_scores';
    List<dynamic> hsArgs = [];
    if (gameVersion != null) {
      hsSql =
          'SELECT MAX(hs.score) as max FROM high_scores hs JOIN games g ON hs.game_id = g.id WHERE g.game_version = ?';
      hsArgs.add(gameVersion.id);
    }
    final highScoreResult = await db.rawQuery(hsSql, hsArgs);
    final highestScore = _firstIntValue(highScoreResult) ?? 0;

    return {
      'games': gamesCount,
      'players': playersCount,
      'highest_score': highestScore,
    };
  }

  Future<int> getTotalPlayersCount({GameVersion? gameVersion}) async {
    final db = await database;
    String sql = 'SELECT COUNT(DISTINCT name) as count FROM players';
    List<dynamic> args = [];
    if (gameVersion != null) {
      sql =
          'SELECT COUNT(DISTINCT p.name) as count FROM players p JOIN games g ON p.game_id = g.id WHERE g.game_version = ?';
      args.add(gameVersion.id);
    }
    final result = await db.rawQuery(sql, args);
    return _firstIntValue(result) ?? 0;
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

  Future<String> exportToCsv() async {
    final db = await database;
    final games = await db.query('games');
    final players = await db.query('players');

    final buffer = StringBuffer();

    buffer.writeln('Games:');
    buffer.writeln(
        'id,uuid,created_at,completed_at,player_count,winner_name,winner_score,notes');
    for (var game in games) {
      buffer.writeln(
          '${game['id']},"${game['uuid']}","${game['created_at']}","${game['completed_at']}",${game['player_count']},"${game['winner_name']}",${game['winner_score']},"${game['notes']}"');
    }

    buffer.writeln('\nPlayers:');
    buffer.writeln(
        'id,game_id,name,final_score,yellow_total,green_total,orange_total,purple_total,blue_total,fox_count,bonus,winner');
    for (var player in players) {
      buffer.writeln(
          '${player['id']},${player['game_id']},"${player['name']}",${player['final_score']},${player['yellow_total']},${player['green_total']},${player['orange_total']},${player['purple_total']},${player['blue_total']},${player['fox_count']},${player['bonus']},${player['winner']}');
    }

    return buffer.toString();
  }

  Future<String> exportToSqlite() async {
    return dbPath;
  }

  Future<void> importFromCsv(String csvContent) async {
    final db = await database;
    final lines = csvContent.split('\n');

    bool inGames = false;
    bool inPlayers = false;

    for (var line in lines) {
      if (line.startsWith('Games:')) {
        inGames = true;
        inPlayers = false;
        continue;
      }
      if (line.startsWith('Players:')) {
        inPlayers = true;
        continue;
      }
      if (line.trim().isEmpty) continue;

      if (inGames && !line.contains('id,uuid')) {
        final parts = _parseCsvLine(line);
        if (parts.length >= 8) {
          await db.insert('games', {
            'uuid': parts[1],
            'created_at': parts[2],
            'completed_at': parts[3],
            'player_count': int.tryParse(parts[4]) ?? 0,
            'winner_name': parts[5],
            'winner_score': int.tryParse(parts[6]) ?? 0,
            'notes': parts[7],
          });
        }
      }

      if (inPlayers && !line.contains('id,game_id')) {
        final parts = _parseCsvLine(line);
        if (parts.length >= 12) {
          await db.insert('players', {
            'game_id': int.tryParse(parts[1]) ?? 0,
            'name': parts[2],
            'final_score': int.tryParse(parts[3]) ?? 0,
            'yellow_total': int.tryParse(parts[4]) ?? 0,
            'green_total': int.tryParse(parts[5]) ?? 0,
            'orange_total': int.tryParse(parts[6]) ?? 0,
            'purple_total': int.tryParse(parts[7]) ?? 0,
            'blue_total': int.tryParse(parts[8]) ?? 0,
            'fox_count': int.tryParse(parts[9]) ?? 0,
            'bonus': int.tryParse(parts[10]) ?? 0,
            'winner': int.tryParse(parts[11]) ?? 0,
          });
        }
      }
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString());
    return result;
  }

  Future<void> importFromSqlite(String importedDbPath) async {
    final currentDb = await database;

    await currentDb.close();

    final backupPath = '$dbPath.bak';

    final backupFile = File(backupPath);
    if (await backupFile.exists()) {
      await backupFile.delete();
    }

    final currentFile = File(dbPath);
    if (await currentFile.exists()) {
      await currentFile.rename(backupPath);
    }

    final importedFile = File(importedDbPath);
    if (await importedFile.exists()) {
      await importedFile.rename(dbPath);
    }

    DatabaseService._database = null;
    await database;
  }

  Future<void> clearHighScores() async {
    final db = await database;
    await db.delete('high_scores');
  }

  Future<List<Map<String, dynamic>>> getGamesPerMonth({int? months}) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> args = [];
    if (months != null) {
      whereClause = "AND created_at >= datetime('now', '-$months months')";
    }

    // Extract date from the non-standard format (takes first 19 chars: "YYYY-MM-DD HH:MM:SS")
    final query = '''
      SELECT 
        strftime('%Y-%m', substr(created_at, 1, 19)) as month,
        COUNT(*) as count
      FROM games
      WHERE 1=1 $whereClause
      GROUP BY strftime('%Y-%m', substr(created_at, 1, 19))
      ORDER BY month ASC
    ''';
    print('Query: $query');
    final results = await db.rawQuery(query, args);
    print('Results: $results');
    return results;
  }

  Future<List<Map<String, dynamic>>> getAverageScoresByPlayerCount(
      {int? months}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> args = [];
    if (months != null) {
      whereClause = "AND created_at >= datetime('now', '-$months months')";
    }
    final query = '''
      SELECT 
        player_count,
        AVG(winner_score) as avg_score,
        MAX(winner_score) as max_score,
        COUNT(*) as games
      FROM games
      WHERE 1=1 $whereClause
      GROUP BY player_count
      ORDER BY player_count ASC
    ''';
    return await db.rawQuery(query, args);
  }

  Future<List<Map<String, dynamic>>> getTopPlayers(
      {int limit = 10, int? months}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> args = [];
    if (months != null) {
      whereClause = "AND g.created_at >= date('now', '-$months months')";
    }
    final result = await db.rawQuery('''
      SELECT 
        p.name,
        COUNT(p.game_id) as games_played,
        AVG(p.final_score) as avg_score,
        MAX(p.final_score) as max_score
      FROM players p
      JOIN games g ON p.game_id = g.id
      WHERE 1=1 $whereClause
      GROUP BY p.name
      ORDER BY avg_score DESC
      LIMIT ?
    ''', [...args, limit]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getAverageScoreByPlayerPosition(
      {int? months}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> args = [];
    if (months != null) {
      whereClause = "AND g.created_at >= date('now', '-$months months')";
    }
    final result = await db.rawQuery('''
      SELECT 
        p.name,
        AVG(p.final_score) as avg_score,
        MAX(p.final_score) as max_score,
        COUNT(DISTINCT p.game_id) as games_played
      FROM players p
      JOIN games g ON p.game_id = g.id
      WHERE 1=1 $whereClause
      GROUP BY p.name
      HAVING COUNT(DISTINCT p.game_id) >= 2
      ORDER BY avg_score DESC
      LIMIT 10
    ''', args);
    return result;
  }

  Future<List<Map<String, dynamic>>> getWinPercentageByPlayer(
      {int? months}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> args = [];
    if (months != null) {
      whereClause = "AND g.created_at >= date('now', '-$months months')";
    }
    final result = await db.rawQuery('''
      SELECT 
        p.name,
        COUNT(p.game_id) as games_played,
        (
          SELECT COUNT(*) FROM players p2 
          JOIN games g2 ON p2.game_id = g2.id
          WHERE p2.name = p.name AND p2.final_score = (
            SELECT MAX(final_score) FROM players WHERE game_id = p2.game_id
          )
          AND (1=1 $whereClause)
        ) as wins
      FROM players p
      JOIN games g ON p.game_id = g.id
      WHERE 1=1 $whereClause
      GROUP BY p.name
      HAVING COUNT(DISTINCT p.game_id) >= 2
    ''', args);

    final processed = <Map<String, dynamic>>[];
    for (var row in result) {
      final games = (row['games_played'] as int?) ?? 0;
      final wins = (row['wins'] as int?) ?? 0;
      final winPct = games > 0 ? (wins / games * 100) : 0.0;
      processed.add({
        'name': row['name'],
        'games_played': games,
        'wins': wins,
        'win_percentage': winPct,
      });
    }

    processed.sort((a, b) => ((b['win_percentage'] as num?) ?? 0.0)
        .compareTo((a['win_percentage'] as num?) ?? 0.0));

    return processed.take(10).toList();
  }

  Future<List<Map<String, dynamic>>> getScoreDistribution({int? months}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> args = [];
    if (months != null) {
      whereClause = "AND g.created_at >= date('now', '-$months months')";
    }
    final result = await db.rawQuery('''
      SELECT 
        CASE 
          WHEN p.final_score < 50 THEN '0-49'
          WHEN p.final_score < 100 THEN '50-99'
          WHEN p.final_score < 150 THEN '100-149'
          WHEN p.final_score < 200 THEN '150-199'
          WHEN p.final_score < 250 THEN '200-249'
          WHEN p.final_score < 300 THEN '250-299'
          ELSE '300+'
        END as range,
        COUNT(*) as count
      FROM players p
      JOIN games g ON p.game_id = g.id
      WHERE 1=1 $whereClause
      GROUP BY range
      ORDER BY 
        CASE range
          WHEN '0-49' THEN 1
          WHEN '50-99' THEN 2
          WHEN '100-149' THEN 3
          WHEN '150-199' THEN 4
          WHEN '200-249' THEN 5
          WHEN '250-299' THEN 6
          ELSE 7
        END
    ''', args);
    return result;
  }
}
