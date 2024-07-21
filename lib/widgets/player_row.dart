import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/course_data_provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scorecard_app/database_helper.dart';

class PlayerRow extends StatefulWidget {
  final List<int> score;
  final String tee;
  final List<int> fairwaysHit;
  final List<int> greensHit;
  final List<int> par;
  final List<FocusNode> focusNodes;
  final List<TextEditingController> controllers;
  final int playerIndex;
  final ScrollController scrollController;
  final TextEditingController nameController;
  final TextEditingController hcapController;
  final List<int> coursePars;
  final Function(int) removePlayer;
  final VoidCallback onScoreChanged;

  const PlayerRow({
    super.key,
    required this.score,
    required this.tee,
    required this.fairwaysHit,
    required this.greensHit,
    required this.par,
    required this.focusNodes,
    required this.controllers,
    required this.playerIndex,
    required this.scrollController,
    required this.nameController,
    required this.hcapController,
    required this.coursePars,
    required this.removePlayer,
    required this.onScoreChanged,
  });

  @override
  State<PlayerRow> createState() => _PlayerRowState();
}

class _PlayerRowState extends State<PlayerRow> {
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadScores();
    // _loadPlayerDetails();
  }

  Future<void> _loadScores() async {
    final scores = await dbHelper.getScores();
    for (var score in scores) {
      if (score['playerIndex'] == widget.playerIndex) {
        setState(() {
          widget.score[score['holeIndex']] = score['score'];
          widget.controllers[score['holeIndex']].text =
              score['score'].toString();
        });
      }
    }

    final playerHandicap = await dbHelper.getHandicap(widget.playerIndex);
    setState(() {
      widget.hcapController.text = playerHandicap.toString();
    });

    _loadPlayerDetails();
  }

  Future<void> _loadPlayerDetails() async {
    final playerName = await dbHelper.getPlayerName(widget.playerIndex);
    final playerHandicap = await dbHelper.getHandicap(widget.playerIndex);
    setState(() {
      widget.nameController.text = playerName ?? 'Name';
      widget.hcapController.text = playerHandicap?.toString() ?? '';
    });
  }

  Future<void> _saveScore(int holeIndex, int score) async {
    await dbHelper.insertScore(widget.playerIndex, holeIndex, score);
  }

  Widget _buildTextField(int index, double scaleFactor) {
    List<int> tempPar = Provider.of<CourseDataProvider>(context).par;
    List<int> tempMensHcap = Provider.of<CourseDataProvider>(context).mensHcap;
    List<int> tempWomensHcap =
        Provider.of<CourseDataProvider>(context).womensHcap;
    Color textColor = Colors.black; // Default color
    // if (widget.matchPlayEnabled) {
    //   if (widget.index == 0) {
    //     textColor = Colors.red; // Player 1's color
    //   } else if (widget.index == 1) {
    //     textColor = const Color.fromARGB(198, 0, 0, 255); // Player 2's color
    //   }
    // }
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(10 * scaleFactor),
          child: GestureDetector(
            onTap: () {
              setState(() {
                widget.focusNodes[index].requestFocus();
                widget.controllers[index].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: widget.controllers[index].text.length,
                );
                double screenWidth = MediaQuery.of(context).size.width;
                double targetScrollPosition =
                    ((index * 105.0 + 10) - (screenWidth / 2 - 100));
                widget.scrollController.animateTo(
                  targetScrollPosition,
                  duration: const Duration(milliseconds: 50),
                  curve: Curves.easeInOut,
                );
              });
            },
            child: Center(
              child: TextField(
                focusNode: widget.focusNodes[index],
                controller: widget.controllers[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onTap: () {
                  setState(() {
                    widget.focusNodes[index].requestFocus();
                    widget.controllers[index].selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: widget.controllers[index].text.length,
                    );
                  });
                },
                onChanged: (text) {
                  int? value = int.tryParse(text);
                  setState(() {
                    widget.score[index] = value ?? 0;
                    _saveScore(index, widget.score[index]);
                    widget.onScoreChanged();
                  });
                },
                // onChanged: (text) {
                //   int? value = int.tryParse(text);
                //   if (value != null) {
                //     setState(() {
                //       widget.score[index] = value;
                //       _saveScores();
                //       widget
                //           .onScoreChanged(); // Call the callback when score changes
                //     });
                //   } else {
                //     setState(() {
                //       widget.score[index] = 0;
                //       _saveScores();
                //       widget
                //           .onScoreChanged(); // Call the callback when score changes
                //     });
                //   }
                // },
                decoration: InputDecoration(
                  // hintText: '${widget.par[index]}',
                  hintText: '${tempPar[index]}',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 33),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(color: textColor, fontSize: 33),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              // painter: _ShapePainter(widget.par[index],
              //     int.tryParse(widget.controllers[index].text)),
              painter: _ShapePainter(
                  tempPar[index], int.tryParse(widget.controllers[index].text)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double scaleFactor = ScaleFactorProvider().scaleFactor;

    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            await _loadPlayerDetails();
            int playerCount = await dbHelper.getPlayerCount();
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                content: Column(
                  children: [
                    CupertinoTextField(
                      controller: widget.nameController,
                      maxLength: 5,
                      placeholder: 'Name',
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.transparent),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                    ),
                    const SizedBox(height: 20),
                    CupertinoTextField(
                      controller: widget.hcapController,
                      placeholder: 'Handicap',
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: false,
                        decimal: true,
                      ),
                      maxLength: 5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.transparent),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                    ),
                  ],
                ),
                actions: [
                  if (playerCount > 1)
                    CupertinoDialogAction(
                      child: const Text(
                        'Remove Player',
                        style: TextStyle(color: CupertinoColors.systemRed),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        if (await dbHelper.getPlayerCount() > 1) {
                          widget.removePlayer(widget.playerIndex);
                        }

                        // Remove the player row
                      },
                    ),
                  CupertinoDialogAction(
                    child: const Text(
                      'OK',
                      style: TextStyle(color: CupertinoColors.activeBlue),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        widget.nameController.text = widget.nameController.text;
                        dbHelper.setPlayerName(
                            widget.playerIndex, widget.nameController.text);
                        widget.hcapController.text = widget.hcapController.text;
                        dbHelper.setHandicap(widget.playerIndex,
                            int.tryParse(widget.hcapController.text) ?? 0);
                        dbHelper.insertPlayerDetails(
                            widget.playerIndex,
                            widget.nameController.text,
                            int.tryParse(widget.hcapController.text) ?? 0);
                      });
                      // Save the name, display it on the row
                    },
                  ),
                ],
              ),
            );
          },
          child: Container(
            width: 80 * scaleFactor,
            height: 40 * scaleFactor,
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
              child: FutureBuilder<String?>(
                future: dbHelper.getPlayerName(widget.playerIndex),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return const Text('Error');
                  } else {
                    return AutoSizeText(
                      snapshot.data.toString() ?? 'Name',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                      ),
                    );
                  }
                },
              ),
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
                child: _buildTextField(index, scaleFactor),
              ),
            ),
          );
        }),
        Container(
          width: 100 * scaleFactor,
          height: 81 * scaleFactor,
          margin: EdgeInsets.all(2 * scaleFactor),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                'F: ${widget.score.sublist(0, 9).reduce((a, b) => a + b)}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  overflow: TextOverflow.ellipsis,
                ),
                minFontSize: 12,
                textAlign: TextAlign.left,
              ),
              AutoSizeText(
                'B: ${widget.score.sublist(9, 18).reduce((a, b) => a + b)}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  overflow: TextOverflow.ellipsis,
                ),
                minFontSize: 12,
                textAlign: TextAlign.left,
              ),
              AutoSizeText(
                'T: ${widget.score.sublist(0, 18).reduce((a, b) => a + b) - widget.coursePars.reduce((a, b) => a + b) >= 0 ? "+" : ""}${widget.score.sublist(0, 18).reduce((a, b) => a + b) - widget.coursePars.reduce((a, b) => a + b)}/${widget.score.sublist(0, 18).reduce((a, b) => a + b)}',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                minFontSize: 12,
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShapePainter extends CustomPainter {
  final int par;
  final int? score;

  _ShapePainter(this.par, this.score);

  @override
  void paint(Canvas canvas, Size size) {
    if (score == null) return;

    int difference = score! - par;
    if (difference <= -2) {
      _drawCircles(canvas, size, 2);
    } else if (difference == -1) {
      _drawCircles(canvas, size, 1);
    } else if (difference == 1) {
      _drawSquares(canvas, size, 1);
    } else if (difference >= 2) {
      _drawSquares(canvas, size, 2);
    }
  }

  void _drawCircles(Canvas canvas, Size size, int count) {
    final radius =
        size.width / 3; // Adjust radius to ensure circles are smaller
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < count; i++) {
      final offset = Offset(
        center.dx +
            (i - (count - 1) / 2) *
                radius *
                0, // Further reduce the offset to fully overlap circles
        center.dy,
      );
      canvas.drawCircle(
        offset,
        radius - i * 8, // Adjust size to create smaller inner circles
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0, // Ensure thickness matches squares
      );
    }
  }

  void _drawSquares(Canvas canvas, Size size, int count) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Make squares thicker

    for (int i = 0; i < count; i++) {
      final halfSize =
          size.width / 5 * (1 - 0.3 * i); // smaller size to fit within grid
      canvas.drawRect(
        Rect.fromCenter(
            center: center, width: halfSize * 3, height: halfSize * 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
