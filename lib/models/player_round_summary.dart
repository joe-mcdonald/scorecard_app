class PlayerRoundSummary {
  const PlayerRoundSummary({
    required this.name,
    required this.frontScore,
    required this.backScore,
    required this.totalScore,
  });

  final String name;
  final int frontScore;
  final int backScore;
  final int totalScore;
}
