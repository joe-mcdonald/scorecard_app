import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';

class MatchPlayResultsRow extends StatelessWidget {
  final List<int> matchPlayResults;
  final List<String> playerNames;
  final Function(int)? onLongPress; //callback function

  const MatchPlayResultsRow({
    super.key,
    required this.matchPlayResults,
    required this.playerNames,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scaleFactor =
        Provider.of<ScaleFactorProvider>(context, listen: false).scaleFactor;

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
                        const SizedBox(height: 4),
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
            ),
          );
        }),
        Container(
          width: 100 * scaleFactor,
          height: 80 * scaleFactor,
          margin: EdgeInsets.all(2 * scaleFactor),
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: const Column(),
        ),
      ],
    );
  }
}
