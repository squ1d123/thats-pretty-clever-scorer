import 'package:flutter/material.dart';

enum GameVersion {
  all('all', 'All Versions'),
  v1('v1', 'Ganz Schön Clever'),
  v2('v2', 'Twice as Clever');

  final String id;
  final String displayName;

  const GameVersion(this.id, this.displayName);

  static GameVersion fromId(String? id) {
    if (id == 'v2') return GameVersion.v2;
    if (id == 'v1') return GameVersion.v1;
    return GameVersion.all;
  }

  List<Color> get colors {
    switch (this) {
      case GameVersion.all:
      case GameVersion.v1:
        return const [
          Color(0xFFFFD700),
          Color(0xFF2196F3),
          Color(0xFF4CAF50),
          Color(0xFFFF9800),
          Color(0xFF9C27B0),
        ];
      case GameVersion.v2:
        return const [
          Color(0xFF9E9E9E),
          Color(0xFFFFEB3B),
          Color(0xFF2196F3),
          Color(0xFF4CAF50),
          Color(0xFFE91E63),
        ];
    }
  }

  List<String> get colorNames {
    switch (this) {
      case GameVersion.all:
      case GameVersion.v1:
        return ['Yellow', 'Blue', 'Green', 'Orange', 'Purple'];
      case GameVersion.v2:
        return ['Silver', 'Yellow', 'Blue', 'Green', 'Pink'];
    }
  }
}
