import 'package:flutter/material.dart';
import '../../models/game_version.dart';

class VersionFilterDropdown extends StatelessWidget {
  final GameVersion? selectedVersion;
  final ValueChanged<GameVersion?> onChanged;

  const VersionFilterDropdown({
    super.key,
    required this.selectedVersion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<GameVersion?>(
      initialValue: selectedVersion,
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: GameVersion.all,
          child: Text(selectedVersion == GameVersion.all
              ? '✓ All Versions'
              : 'All Versions'),
        ),
        ...GameVersion.values
            .where((v) => v != GameVersion.all)
            .map((v) => PopupMenuItem(
                  value: v,
                  child: Text(selectedVersion == v
                      ? '✓ ${v.displayName}'
                      : v.displayName),
                ))
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.videogame_asset),
            const SizedBox(width: 8),
            Text(selectedVersion == GameVersion.all
                ? 'All Versions'
                : selectedVersion!.displayName),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class VersionFilterFormField extends StatelessWidget {
  final GameVersion? value;
  final ValueChanged<GameVersion?> onChanged;

  const VersionFilterFormField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<GameVersion?>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Filter by version',
        border: OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: GameVersion.all,
          child: Text(
              value == GameVersion.all ? '✓ All Versions' : 'All Versions'),
        ),
        ...GameVersion.values
            .where((v) => v != GameVersion.all)
            .map((v) => DropdownMenuItem(
                  value: v,
                  child:
                      Text(value == v ? '✓ ${v.displayName}' : v.displayName),
                )),
      ],
      onChanged: onChanged,
    );
  }
}
