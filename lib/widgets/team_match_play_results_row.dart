import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';

class TeamMatchPlayResultsRow extends StatelessWidget {
  final List<int> matchPlayResults;
  final List<String> teamNames;

  const TeamMatchPlayResultsRow({
    super.key,
    required this.matchPlayResults,
    required this.teamNames,
  });

  @override
  Widget build(BuildContext context) {
    final scaleFactor = Provider.of<ScaleFactorProvider>(context).scaleFactor;
    String? frontNineWinner;
    String? backNineWinner;
    String? fullEighteenWinner;
    // set frontNineWinner if every index in matchPlayResults is not empty
    if (matchPlayResults.every((element) => element != null)) {
      int frontNineWinnerScore = matchPlayResults[8];
      if (frontNineWinnerScore < 0) {
        frontNineWinner = teamNames[0];
      } else if (frontNineWinnerScore > 0) {
        frontNineWinner = teamNames[1];
      } else {
        frontNineWinner = 'Tie';
      }
      // the back nine winner score is the difference between the 18th hole and the 9th hole
      int backNineWinnerScore = matchPlayResults[17] - matchPlayResults[8];
      if (matchPlayResults[17] < 0) {
        backNineWinner = teamNames[0];
      } else if (backNineWinnerScore > 0) {
        backNineWinner = teamNames[1];
      } else {
        backNineWinner = 'Tie';
      }
      int fullEighteenWinnerScore = matchPlayResults[17];
      if (fullEighteenWinnerScore < 0) {
        fullEighteenWinner = teamNames[0];
      } else if (fullEighteenWinnerScore > 0) {
        fullEighteenWinner = teamNames[1];
      } else {
        fullEighteenWinner = 'Tie';
      }
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.only(right: 0 * scaleFactor),
          margin: EdgeInsets.all(2 * scaleFactor),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Row(
              children: [
                SizedBox(
                  width: 80 * scaleFactor,
                  height: scaleFactor * 70,
                  child: const Center(
                    child: Text(
                      'Match\nPlay',
                      style: TextStyle(color: Colors.black, fontSize: 23),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...List.generate(18, (index) {
          return Container(
            width: 100 * scaleFactor,
            height: 80 * scaleFactor,
            margin: EdgeInsets.all(2 * scaleFactor),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: index == 0 ? const Radius.circular(12) : Radius.zero,
                bottomLeft:
                    index == 0 ? const Radius.circular(12) : Radius.zero,
              ),
            ),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        matchPlayResults[index].abs().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          // color: matchPlayResults[index] < 0
                          //     ? Colors.red
                          //     : matchPlayResults[index] > 0
                          //         ? const Color.fromARGB(198, 0, 0, 255)
                          //         : Colors.black,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        matchPlayResults[index] < 0
                            ? teamNames[0]
                            : matchPlayResults[index] > 0
                                ? teamNames[1]
                                : 'Tie',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          // color: matchPlayResults[index] < 0
                          //     ? Colors.red
                          //     : matchPlayResults[index] > 0
                          //         ? const Color.fromARGB(198, 0, 0, 255)
                          //         : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        Container(
          width: 100 * scaleFactor,
          height: 80 * scaleFactor,
          margin: EdgeInsets.all(2 * scaleFactor),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              Spacer(),
              Text(
                'Front: ${frontNineWinner ?? ''}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                ),
              ),
              Text(
                'Back: ${backNineWinner ?? ''}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                ),
              ),
              Text(
                'Full 18: ${fullEighteenWinner ?? ''}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}
