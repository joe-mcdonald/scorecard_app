import 'package:scorecard_app/database_helper.dart';
import 'package:scorecard_app/models/player_round_summary.dart';

class RoundShareService {
  RoundShareService({required this.dbHelper});

  final DatabaseHelper dbHelper;

  Future<String> buildRoundSummary({
    required String course,
    required String tee,
    required int playerCount,
  }) async {
    final buffer = StringBuffer()
      ..writeln('Golf Round Details:')
      ..writeln('Course: $course')
      ..writeln('Tee: $tee')
      ..writeln('');

    final summaries = await Future.wait(
      List.generate(playerCount, (index) => _playerSummary(index)),
    );

    for (final summary in summaries) {
      buffer
        ..writeln('Player: ${summary.name}')
        ..writeln('Front: ${summary.frontScore}')
        ..writeln('Back: ${summary.backScore}')
        ..writeln('Score: ${summary.totalScore}')
        ..writeln('');
    }

    return buffer.toString();
  }

  Future<PlayerRoundSummary> _playerSummary(int playerIndex) async {
    final name = await dbHelper.getPlayerName(playerIndex) ??
        'Player ${playerIndex + 1}';
    int frontScore = 0;
    int backScore = 0;

    for (int holeIndex = 0; holeIndex < 18; holeIndex++) {
      final score = await dbHelper.getScoreForHole(playerIndex, holeIndex);
      if (holeIndex < 9) {
        frontScore += score;
      } else {
        backScore += score;
      }
    }

    return PlayerRoundSummary(
      name: name,
      frontScore: frontScore,
      backScore: backScore,
      totalScore: frontScore + backScore,
    );
  }
}
