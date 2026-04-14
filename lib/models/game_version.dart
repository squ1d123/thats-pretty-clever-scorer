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
          Color(0xFF4CAF50),
          Color(0xFFFF9800),
          Color(0xFF9C27B0),
          Color(0xFF2196F3),
        ];
      case GameVersion.v2:
        return const [
          Color(0xFFE91E63),
          Color(0xFF4CAF50),
          Color(0xFF2196F3),
          Color(0xFFFFEB3B),
          Color(0xFF9E9E9E),
        ];
    }
  }

  List<String> get colorNames {
    switch (this) {
      case GameVersion.all:
      case GameVersion.v1:
        return ['Yellow', 'Green', 'Orange', 'Purple', 'Blue'];
      case GameVersion.v2:
        return ['Pink', 'Green', 'Blue', 'Yellow', 'Silver'];
    }
  }
}
