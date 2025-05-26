import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';

class MatchPlayResultsRow9 extends StatelessWidget {
  final List<int> matchPlayResults;
  final List<String> playerNames;
  final Function(int)? onLongPress; //callback function

  const MatchPlayResultsRow9({
    super.key,
    required this.matchPlayResults,
    required this.playerNames,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scaleFactor =
        Provider.of<ScaleFactorProvider>(context, listen: false).scaleFactor;

    String frontWinnerName = '';
    String backWinnerName = '';
    String totalWinnerName = '';
    if (matchPlayResults[8] - matchPlayResults[0] > 0) {
      backWinnerName = playerNames[1];
    } else if (matchPlayResults[8] - matchPlayResults[0] < 0) {
      backWinnerName = playerNames[0];
    } else {
      backWinnerName = 'Tie';
    }
    // if (((matchPlayResults[17] - matchPlayResults[9]) +
    //         (matchPlayResults[8] - matchPlayResults[0])) >
    //     0) {
    //   totalWinnerName = playerNames[1];
    // } else if (((matchPlayResults[17] - matchPlayResults[9]) +
    //         (matchPlayResults[8] - matchPlayResults[0])) <
    //     0) {
    //   totalWinnerName = playerNames[0];
    // } else {
    //   totalWinnerName = 'Tie';
    // }

    return Row(
      children: [
        ...List.generate(
          9,
          (index) {
            return Container(
              width: 100 * scaleFactor,
              height: 80 * scaleFactor,
              margin: EdgeInsets.all(2 * scaleFactor),
              child: const Center(
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Container(
          padding: EdgeInsets.only(right: 0 * scaleFactor),
          margin: EdgeInsets.all(2 * scaleFactor),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 243, 243, 243),
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
                      'Back\n9',
                      style: TextStyle(color: Colors.black, fontSize: 23),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...List.generate(9, (index) {
          return GestureDetector(
            onLongPress: () {
              if (onLongPress != null && index != 0) {
                onLongPress!(index);
              }
            },
            child: Container(
              width: 100 * scaleFactor,
              height: 80 * scaleFactor,
              margin: EdgeInsets.all(2 * scaleFactor),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 243, 243, 243),
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
                        const SizedBox(height: 4),
                        Text(
                          matchPlayResults[index].abs().toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          matchPlayResults[index] < 0
                              ? playerNames[0] == ''
                                  ? 'Player 1'
                                  : playerNames[0]
                              : matchPlayResults[index] > 0
                                  ? playerNames[1] == ''
                                      ? 'Player 2'
                                      : playerNames[1]
                                  : 'Tie',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        Container(
          width: 100 * scaleFactor,
          height: 81 * scaleFactor,
          margin: EdgeInsets.all(2 * scaleFactor),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 243, 243, 243),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                'Back:\n$backWinnerName',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 23,
                  overflow: TextOverflow.ellipsis,
                ),
                minFontSize: 12,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
