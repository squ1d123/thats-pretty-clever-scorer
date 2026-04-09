import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../providers/game_providers.dart';
import '../services/database_service.dart';

class CleanupScreen extends ConsumerWidget {
  const CleanupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(databaseStatsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (stats) => _buildContent(context, ref, stats),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, Map<String, int> stats) {
    final customPath = DatabaseService.customDbPath;
    final isUsingCustom = customPath != null && customPath.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Database Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _StatRow(label: 'Total Games', value: stats['games'] ?? 0),
                  _StatRow(
                      label: 'Unique Players', value: stats['players'] ?? 0),
                  _StatRow(
                      label: 'Highest Score Ever',
                      value: stats['highest_score'] ?? 0),
                  const Divider(),
                  Text(
                    isUsingCustom ? 'Custom Path' : 'Default Path',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUsingCustom ? customPath : 'Internal storage',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.delete_sweep,
            title: 'Delete All Games',
            description: 'Remove all game history and player data',
            color: Colors.red,
            onTap: () => _confirmDeleteAllGames(context, ref),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.emoji_events,
            title: 'Clear High Scores',
            description: 'Remove all high score records',
            color: Colors.orange,
            onTap: () => _confirmClearHighScores(context, ref),
          ),
          const SizedBox(height: 24),
          const Text(
            'Import / Export',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.file_download,
            title: 'Export as CSV',
            description: 'Export all data to a CSV file',
            color: Colors.blue,
            onTap: () => _exportCsv(context, ref),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.storage,
            title: 'Export as SQLite',
            description: 'Export database as SQLite file',
            color: Colors.blue,
            onTap: () => _exportSqlite(context, ref),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.file_upload,
            title: 'Import from CSV',
            description: 'Import data from a CSV file',
            color: Colors.green,
            onTap: () => _importCsv(context, ref),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.folder_open,
            title: 'Import from SQLite',
            description: 'Replace database with SQLite file',
            color: Colors.green,
            onTap: () => _importSqlite(context, ref),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.link,
            title: 'Load from Custom Path',
            description: 'Load database from alternate location',
            color: Colors.purple,
            onTap: () => _loadFromCustomPath(context, ref),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.link_off,
            title: 'Reset to Default Path',
            description: 'Use internal app storage',
            color: Colors.grey,
            onTap: () => _resetToDefaultPath(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllGames(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Games?'),
        content: const Text(
            'This will permanently delete all game history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final db = ref.read(databaseServiceProvider);
              await db.deleteAllGames();
              ref.invalidate(databaseStatsProvider);
              ref.invalidate(gameHistoryProvider(GameHistoryFilter()));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All games deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClearHighScores(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear High Scores?'),
        content: const Text(
            'This will remove all high score records. Games will still be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final db = ref.read(databaseServiceProvider);
              await db.clearHighScores();
              ref.invalidate(highScoresProvider);
              ref.invalidate(databaseStatsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('High scores cleared')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

void _refreshProviders(WidgetRef ref) {
  Future.microtask(() {
    ref.invalidate(databaseStatsProvider);
    ref.invalidate(gameHistoryProvider(GameHistoryFilter()));
    ref.invalidate(highScoresProvider);
  });
}

void _exportCsv(BuildContext context, WidgetRef ref) async {
  try {
    final db = ref.read(databaseServiceProvider);
    final csvContent = await db.exportToCsv();

    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/ganz_clever_export.csv');
    await file.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Ganz Schön Clever Data Export',
    );

    _showSnackBar(context, 'CSV exported successfully');
  } catch (e) {
    _showSnackBar(context, 'Failed to export CSV: $e');
  }
}

void _exportSqlite(BuildContext context, WidgetRef ref) async {
  try {
    final db = ref.read(databaseServiceProvider);
    final dbPath = await db.exportToSqlite();

    await Share.shareXFiles(
      [XFile(dbPath)],
      subject: 'Ganz Schön Clever Database Export',
    );

    _showSnackBar(context, 'SQLite exported successfully');
  } catch (e) {
    _showSnackBar(context, 'Failed to export SQLite: $e');
  }
}

void _importCsv(BuildContext context, WidgetRef ref) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final csvContent = await file.readAsString();

    final db = ref.read(databaseServiceProvider);
    await db.importFromCsv(csvContent);

    _refreshProviders(ref);
    _showSnackBar(context, 'CSV imported successfully');
  } catch (e) {
    _showSnackBar(context, 'Failed to import CSV: $e');
  }
}

void _importSqlite(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Import SQLite Database?'),
      content: const Text(
        'This will replace your current database with the imported file. '
        'Your current data will be backed up. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Import'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    final db = ref.read(databaseServiceProvider);
    await db.importFromSqlite(result.files.single.path!);

    _refreshProviders(ref);
    _showSnackBar(context, 'SQLite imported successfully');
  } catch (e) {
    _showSnackBar(context, 'Failed to import SQLite: $e');
  }
}

void _loadFromCustomPath(BuildContext context, WidgetRef ref) async {
  try {
    final storagePermission = await Permission.storage.request();
    if (!storagePermission.isGranted) {
      final managePermission = await Permission.manageExternalStorage.request();
      if (!managePermission.isGranted && managePermission.isPermanentlyDenied) {
        _showSnackBar(context, 'Storage permission required');
        await openAppSettings();
        return;
      }
    }

    final result = await FilePicker.platform.getDirectoryPath();

    if (result == null) return;

    final customPath = result;
    final dbPath = p.join(customPath, 'ganz-schon-clever-games.db');
    await DatabaseService.setCustomDbPath(dbPath);

    _refreshProviders(ref);
    _showSnackBar(context, 'Custom database path set to: $customPath');
  } catch (e) {
    _showSnackBar(context, 'Failed to set custom path: $e');
  }
}

void _resetToDefaultPath(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset to Default Path?'),
      content: const Text(
        'This will reset the database to use internal app storage. '
        'Any data in a custom path will not be affected.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Reset'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await DatabaseService.setCustomDbPath('');
    _refreshProviders(ref);
    _showSnackBar(context, 'Database path reset to default');
  } catch (e) {
    _showSnackBar(context, 'Failed to reset path: $e');
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
