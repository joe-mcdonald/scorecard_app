import 'package:scorecard_app/database_helper.dart';

class SkinsResult {
  const SkinsResult({
    required this.skinsArray,
    required this.skinsWon,
    required this.skinsWonByHole,
  });

  final List<int> skinsArray;
  final List<int> skinsWon;
  final List<List<bool>> skinsWonByHole;
}

class SkinsService {
  SkinsService({required this.dbHelper});

  final DatabaseHelper dbHelper;

  Future<SkinsResult> calculateSkins({
    required List<int> mensHandicap,
    required int skinValue,
  }) async {
    final playerCount = await dbHelper.getPlayerCount();

    final List<int> player1Score = List.generate(18, (index) => 0);
    final List<int> player2Score = List.generate(18, (index) => 0);
    final List<int> player3Score = List.generate(18, (index) => 0);
    final List<int> player4Score = List.generate(18, (index) => 0);

    int carryOver = skinValue;

    final List<int> skinsArray = List.generate(18, (index) => skinValue);
    final List<int> skinsWon = [0, 0, 0, 0];
    final List<List<bool>> skinsWonByHole =
        List.generate(4, (index) => List.generate(18, (index) => false));

    if (playerCount == 2) {
      final int player1Handicap = await dbHelper.getHandicap(0) ?? 0;
      final int player2Handicap = await dbHelper.getHandicap(1) ?? 0;
      final int netStrokes = player1Handicap - player2Handicap;

      for (int i = 0; i < 18; i++) {
        player1Score[i] = await dbHelper.getScoreForHole(0, i);
        player2Score[i] = await dbHelper.getScoreForHole(1, i);
      }

      for (int i = 0; i < 18; i++) {
        if (player1Score[i] == 0 || player2Score[i] == 0) {
          continue;
        }

        final bool isHandicapHole = mensHandicap[i] <= netStrokes.abs();
        int p1NetScore = player1Score[i];
        int p2NetScore = player2Score[i];
        if (isHandicapHole) {
          p1NetScore = player1Score[i] - (netStrokes > 0 ? 1 : 0);
          p2NetScore = player2Score[i] - (netStrokes < 0 ? 1 : 0);
        }

        if (p1NetScore < p2NetScore) {
          skinsArray[i] = carryOver;
          skinsWon[0] = skinsArray[i];
          carryOver = skinValue;
          skinsWonByHole[0][i] = true;
        } else if (p2NetScore < p1NetScore) {
          skinsArray[i] = carryOver;
          skinsWon[1] = skinsArray[i];
          carryOver = skinValue;
          skinsWonByHole[1][i] = true;
        } else {
          skinsArray[i] = carryOver;
          carryOver += skinValue;
        }
      }
    }

    if (playerCount >= 3) {
      final List<List<int>> scores = [player1Score, player2Score];
      final List<int> handicaps = [
        await dbHelper.getHandicap(0) ?? 0,
        await dbHelper.getHandicap(1) ?? 0,
      ];

      if (playerCount >= 3) {
        scores.add(player3Score);
        handicaps.add(await dbHelper.getHandicap(2) ?? 0);
      }
      if (playerCount == 4) {
        scores.add(player4Score);
        handicaps.add(await dbHelper.getHandicap(3) ?? 0);
      }

      for (int i = 0; i < 18; i++) {
        for (int p = 0; p < playerCount; p++) {
          scores[p][i] = await dbHelper.getScoreForHole(p, i);
        }
      }

      for (int i = 0; i < 18; i++) {
        if (scores.any((scoreList) => scoreList[i] == 0)) {
          continue;
        }

        final int lowestHandicap = handicaps.reduce((a, b) => a < b ? a : b);

        final List<int> netScores = List.generate(playerCount, (p) {
          final int handicapDifference = handicaps[p] - lowestHandicap;
          final bool getsStroke = mensHandicap[i] <= handicapDifference.abs();
          return scores[p][i] - (getsStroke ? 1 : 0);
        });

        final int minScore = netScores.reduce((a, b) => a < b ? a : b);
        final int minScoreCount =
            netScores.where((score) => score == minScore).length;

        if (minScoreCount == 1) {
          final int winnerIndex = netScores.indexOf(minScore);
          skinsArray[i] = carryOver;
          skinsWon[winnerIndex] += skinsArray[i];
          carryOver = skinValue;
          if (i < 17) skinsArray[i + 1] = skinValue;
          skinsWonByHole[winnerIndex][i] = true;
        } else {
          skinsArray[i] = carryOver;
          carryOver += skinValue;
        }
        if (i < 17) {
          for (int j = i + 2; j < 18; j++) {
            skinsArray[j] = skinsArray[j - 1] + skinValue;
          }
        }
      }
    }

    return SkinsResult(
      skinsArray: skinsArray,
      skinsWon: List<int>.from(skinsWon),
      skinsWonByHole: skinsWonByHole
          .map((playerSkins) => List<bool>.from(playerSkins))
          .toList(),
    );
  }
}
