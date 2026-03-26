class ScoreSheet {
  YellowScoreArea yellow;
  GreenScoreArea green;
  OrangeScoreArea orange;
  PurpleScoreArea purple;
  BlueScoreArea blue;
  BonusArea bonus;

  ScoreSheet()
      : yellow = YellowScoreArea(),
        green = GreenScoreArea(),
        orange = OrangeScoreArea(),
        purple = PurpleScoreArea(),
        blue = BlueScoreArea(),
        bonus = BonusArea();

  int get totalScore =>
      yellow.total +
      green.total +
      orange.total +
      purple.total +
      blue.total +
      bonus.total;

  void calculateBonus() {
    List<int> sections = [
      yellow.total,
      green.total,
      orange.total,
      purple.total,
      blue.total
    ];

    int lowest = 0;
    for (int section in sections) {
      if (section > 0 && (lowest == 0 || section < lowest)) {
        lowest = section;
      }
    }

    bonus.total = lowest * bonus.foxCount;
  }

  Map<String, dynamic> toMap() {
    return {
      'yellow_total': yellow.total,
      'green_total': green.total,
      'orange_total': orange.total,
      'purple_total': purple.total,
      'blue_total': blue.total,
      'fox_count': bonus.foxCount,
      'bonus': bonus.total,
    };
  }
}

class YellowScoreArea {
  int total;
  List<List<bool>> columns;

  YellowScoreArea()
      : total = 0,
        columns = List.generate(6, (_) => List.filled(6, false));

  int calculateScore() {
    int score = 0;
    for (int col = 0; col < 6; col++) {
      bool columnComplete = true;
      for (int row = 0; row < 6; row++) {
        if (!columns[col][row]) {
          columnComplete = false;
          break;
        }
      }
      if (columnComplete) {
        score += (col + 1) * (col + 1);
      }
    }
    total = score;
    return score;
  }
}

class GreenScoreArea {
  int total;
  List<bool> numbers;

  GreenScoreArea()
      : total = 0,
        numbers = List.filled(11, false);

  int calculateScore() {
    int score = 0;
    int consecutiveCount = 0;

    for (int i = 0; i < numbers.length; i++) {
      if (numbers[i]) {
        consecutiveCount++;
      } else {
        if (consecutiveCount > 0) {
          score += consecutiveCount * consecutiveCount;
        }
        consecutiveCount = 0;
      }
    }

    if (consecutiveCount > 0) {
      score += consecutiveCount * consecutiveCount;
    }

    total = score;
    return score;
  }
}

class OrangeScoreArea {
  int total;
  List<int> numbers;

  OrangeScoreArea()
      : total = 0,
        numbers = List.filled(11, 0);

  int calculateScore() {
    int score = 0;
    for (int num in numbers) {
      if (num > 0) {
        score += num;
      }
    }
    total = score;
    return score;
  }
}

class PurpleScoreArea {
  int total;
  List<bool> numbers;

  PurpleScoreArea()
      : total = 0,
        numbers = List.filled(11, false);

  int calculateScore() {
    int score = 0;
    for (int i = 0; i < numbers.length; i++) {
      if (numbers[i]) {
        if (i < 5) {
          score += i + 1;
        } else if (i == 5) {
          score += 6;
        } else {
          score += i + 1;
        }
      }
    }
    total = score;
    return score;
  }
}

class BlueScoreArea {
  int total;
  List<bool> numbers;

  BlueScoreArea()
      : total = 0,
        numbers = List.filled(11, false);

  int calculateScore() {
    int markedCount = 0;
    for (bool marked in numbers) {
      if (marked) markedCount++;
    }

    int score;
    switch (markedCount) {
      case 1:
        score = 1;
        break;
      case 2:
        score = 3;
        break;
      case 3:
        score = 6;
        break;
      case 4:
        score = 10;
        break;
      case 5:
        score = 15;
        break;
      case 6:
        score = 21;
        break;
      case 7:
        score = 28;
        break;
      case 8:
        score = 36;
        break;
      case 9:
        score = 45;
        break;
      case 10:
        score = 55;
        break;
      case 11:
        score = 66;
        break;
      default:
        score = 0;
    }

    total = score;
    return score;
  }
}

class BonusArea {
  int total;
  int foxCount;

  BonusArea()
      : total = 0,
        foxCount = 0;
}
