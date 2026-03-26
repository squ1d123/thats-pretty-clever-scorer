import 'score_sheet.dart';

class Player {
  String name;
  ScoreSheet scoreSheet;
  bool isActive;

  Player({required this.name})
      : scoreSheet = ScoreSheet(),
        isActive = false;

  int get totalScore => scoreSheet.totalScore;

  String get scoreText => '$name: $totalScore points';

  Map<String, dynamic> toMap(int gameId) {
    return {
      'game_id': gameId,
      'name': name,
      'final_score': totalScore,
      'yellow_total': scoreSheet.yellow.total,
      'green_total': scoreSheet.green.total,
      'orange_total': scoreSheet.orange.total,
      'purple_total': scoreSheet.purple.total,
      'blue_total': scoreSheet.blue.total,
      'fox_count': scoreSheet.bonus.foxCount,
      'bonus': scoreSheet.bonus.total,
    };
  }
}
