import 'package:scorecard_app/database_helper.dart';

class PairMatchResult {
  const PairMatchResult({
    required this.overall,
    required this.backNine,
  });

  final List<int> overall;
  final List<int> backNine;
}

class TeamMatchResult {
  const TeamMatchResult({
    required this.overall,
    required this.backNine,
  });

  final List<int> overall;
  final List<int> backNine;
}

class MatchPlayService {
  MatchPlayService({required this.dbHelper});

  final DatabaseHelper dbHelper;

  Future<PairMatchResult> calculatePairMatch({
    required int playerAIndex,
    required int playerBIndex,
    required List<int> mensHandicap,
  }) async {
    final int playerAHandicap = await dbHelper.getHandicap(playerAIndex) ?? 0;
    final int playerBHandicap = await dbHelper.getHandicap(playerBIndex) ?? 0;
    final int netStrokes = playerAHandicap - playerBHandicap;

    final List<int> overall = List.generate(18, (_) => 0);
    final List<int> backNine = List.generate(9, (_) => 0);

    for (int holeIndex = 0; holeIndex < 18; holeIndex++) {
      final int playerAScore =
          await dbHelper.getScoreForHole(playerAIndex, holeIndex);
      final int playerBScore =
          await dbHelper.getScoreForHole(playerBIndex, holeIndex);

      if (playerAScore == 0 || playerBScore == 0) {
        if (holeIndex < 9) {
          for (int j = holeIndex; j < 9; j++) {
            backNine[j] = 0;
          }
        }
        break;
      }

      final bool isHandicapHole = mensHandicap[holeIndex] <= netStrokes.abs();
      overall[holeIndex] = _updateMatchScore(
        holeIndex: holeIndex,
        previousScores: overall,
        playerAScore: playerAScore,
        playerBScore: playerBScore,
        netStrokes: netStrokes,
        isHandicapHole: isHandicapHole,
      );
    }

    for (int index = 0; index < 9; index++) {
      final int holeIndex = index + 9;
      final int playerAScore =
          await dbHelper.getScoreForHole(playerAIndex, holeIndex);
      final int playerBScore =
          await dbHelper.getScoreForHole(playerBIndex, holeIndex);

      if (playerAScore == 0 || playerBScore == 0) {
        for (int j = index; j < 9; j++) {
          backNine[j] = 0;
        }
        break;
      }

      final bool isHandicapHole = mensHandicap[holeIndex] <= netStrokes.abs();
      backNine[index] = _updateMatchScore(
        holeIndex: index,
        previousScores: backNine,
        playerAScore: playerAScore,
        playerBScore: playerBScore,
        netStrokes: netStrokes,
        isHandicapHole: isHandicapHole,
      );
    }

    return PairMatchResult(
      overall: overall,
      backNine: backNine,
    );
  }

  int _updateMatchScore({
    required int holeIndex,
    required List<int> previousScores,
    required int playerAScore,
    required int playerBScore,
    required int netStrokes,
    required bool isHandicapHole,
  }) {
    final int comparison = _compareScores(
      playerAScore: playerAScore,
      playerBScore: playerBScore,
      netStrokes: netStrokes,
      isHandicapHole: isHandicapHole,
    );

    final int previousValue =
        holeIndex == 0 ? 0 : previousScores[holeIndex - 1];

    if (comparison < 0) {
      return previousValue - 1;
    } else if (comparison > 0) {
      return previousValue + 1;
    }
    return previousValue;
  }

  int _compareScores({
    required int playerAScore,
    required int playerBScore,
    required int netStrokes,
    required bool isHandicapHole,
  }) {
    int adjustedPlayerAScore = playerAScore;
    int adjustedPlayerBScore = playerBScore;

    if (isHandicapHole) {
      if (netStrokes > 0) {
        adjustedPlayerAScore -= 1;
      } else if (netStrokes < 0) {
        adjustedPlayerBScore -= 1;
      }
    }

    if (adjustedPlayerAScore < adjustedPlayerBScore) {
      return -1;
    } else if (adjustedPlayerAScore > adjustedPlayerBScore) {
      return 1;
    }
    return 0;
  }

  Future<TeamMatchResult> calculateTeamMatchPlayFourBall({
    required List<int> mensHandicap,
    required List<int> womensHandicap,
    required bool useMensHandicap,
  }) async {
    final int playerCount = await dbHelper.getPlayerCount();
    if (playerCount < 4) {
      return TeamMatchResult(
        overall: List<int>.filled(18, 0),
        backNine: List<int>.filled(9, 0),
      );
    }

    final int player1Handicap = await dbHelper.getHandicap(0) ?? 0;
    final int player2Handicap = await dbHelper.getHandicap(1) ?? 0;
    final int player3Handicap = await dbHelper.getHandicap(2) ?? 0;
    final int player4Handicap = await dbHelper.getHandicap(3) ?? 0;

    final int lowestHandicap = [
      player1Handicap,
      player2Handicap,
      player3Handicap,
      player4Handicap,
    ].reduce((a, b) => a < b ? a : b);

    final int netStrokesPlayer1 = player1Handicap - lowestHandicap;
    final int netStrokesPlayer2 = player2Handicap - lowestHandicap;
    final int netStrokesPlayer3 = player3Handicap - lowestHandicap;
    final int netStrokesPlayer4 = player4Handicap - lowestHandicap;

    final List<int> overall = List.generate(18, (_) => 0);
    final List<int> backNine = List.generate(9, (_) => 0);

    for (int holeIndex = 0; holeIndex < 18; holeIndex++) {
      final int player1Score = await dbHelper.getScoreForHole(0, holeIndex);
      final int player2Score = await dbHelper.getScoreForHole(1, holeIndex);
      final int player3Score = await dbHelper.getScoreForHole(2, holeIndex);
      final int player4Score = await dbHelper.getScoreForHole(3, holeIndex);

      if (player1Score == 0 ||
          player2Score == 0 ||
          player3Score == 0 ||
          player4Score == 0) {
        if (holeIndex >= 9) {
          final int backIndex = holeIndex - 9;
          for (int j = backIndex; j < 9; j++) {
            backNine[j] = 0;
          }
        }
        break;
      }

      final int holeHandicap =
          useMensHandicap ? mensHandicap[holeIndex] : womensHandicap[holeIndex];

      final int netScorePlayer1 = _applyStrokeAdjustment(
        player1Score,
        netStrokesPlayer1,
        holeHandicap,
      );
      final int netScorePlayer2 = _applyStrokeAdjustment(
        player2Score,
        netStrokesPlayer2,
        holeHandicap,
      );
      final int netScorePlayer3 = _applyStrokeAdjustment(
        player3Score,
        netStrokesPlayer3,
        holeHandicap,
      );
      final int netScorePlayer4 = _applyStrokeAdjustment(
        player4Score,
        netStrokesPlayer4,
        holeHandicap,
      );

      final int bestBallTeam1 =
          netScorePlayer1 < netScorePlayer2 ? netScorePlayer1 : netScorePlayer2;
      final int bestBallTeam2 =
          netScorePlayer3 < netScorePlayer4 ? netScorePlayer3 : netScorePlayer4;

      overall[holeIndex] = _updateTeamMatchScore(
        holeIndex: holeIndex,
        previousScores: overall,
        teamOneScore: bestBallTeam1,
        teamTwoScore: bestBallTeam2,
      );

      if (holeIndex >= 9) {
        final int backIndex = holeIndex - 9;
        backNine[backIndex] = _updateTeamMatchScore(
          holeIndex: backIndex,
          previousScores: backNine,
          teamOneScore: bestBallTeam1,
          teamTwoScore: bestBallTeam2,
        );
      }
    }

    return TeamMatchResult(overall: overall, backNine: backNine);
  }

  int _applyStrokeAdjustment(
    int score,
    int netStrokes,
    int holeHandicap,
  ) {
    if (netStrokes >= holeHandicap && holeHandicap > 0) {
      return score - 1;
    }
    return score;
  }

  int _updateTeamMatchScore({
    required int holeIndex,
    required List<int> previousScores,
    required int teamOneScore,
    required int teamTwoScore,
  }) {
    final int previousValue =
        holeIndex == 0 ? 0 : previousScores[holeIndex - 1];

    if (teamOneScore < teamTwoScore) {
      return previousValue - 1;
    } else if (teamOneScore > teamTwoScore) {
      return previousValue + 1;
    }
    return previousValue;
  }
}
