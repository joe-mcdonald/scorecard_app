import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/course_data_provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scorecard_app/database_helper.dart';
import 'package:scorecard_app/home_screen.dart';

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
  final Color? playerTeamColor;
  final Future<bool> Function(int index, int playerIndex)? isStrokeHole;
  final List<bool> skinsWonByHole;

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
    this.playerTeamColor,
    this.isStrokeHole,
    required this.skinsWonByHole,
  });

  @override
  State<PlayerRow> createState() => _PlayerRowState();
}

class _PlayerRowState extends State<PlayerRow> {
  final dbHelper = DatabaseHelper();
  late List<FocusNode> allFocusNodes;

  @override
  void initState() {
    super.initState();
    // _initializeFocusListeners();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final scores = await dbHelper.getScores();
    for (var score in scores) {
      if (score['playerIndex'] == widget.playerIndex) {
        // setState(() {
        widget.score[score['holeIndex']] = score['score'];
        widget.controllers[score['holeIndex']].text =
            score['score'] == 0 ? '' : score['score'].toString();
        // });
      }
    }

    final playerHandicap = await dbHelper.getHandicap(widget.playerIndex);
    widget.hcapController.text = playerHandicap.toString();

    _loadPlayerDetails();
    setState(() {});
  }

  Future<void> _loadPlayerDetails() async {
    final playerName = await dbHelper.getPlayerName(widget.playerIndex);
    final playerHandicap = await dbHelper.getHandicap(widget.playerIndex);
    // setState(() {
    widget.nameController.text = playerName ?? '';
    widget.hcapController.text = playerHandicap?.toString() ?? '';
    // });
  }

  Future<void> _saveScore(int holeIndex, int score) async {
    await dbHelper.insertScore(widget.playerIndex, holeIndex, score);
  }

  Widget _buildTextField(int index, double scaleFactor, bool isStrokeHole) {
    List<int> tempPar = Provider.of<CourseDataProvider>(context).par;
    Color textColor = Colors.black;

    int? score = int.tryParse(widget.controllers[index].text);

    return FutureBuilder<bool>(
      future: widget.isStrokeHole?.call(index, widget.playerIndex),
      builder: (context, snapshot) {
        bool isStrokeHole = snapshot.data ?? false;
        return Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(10 * scaleFactor),
              child: GestureDetector(
                onTap: () {
                  for (FocusNode focusNode in widget.focusNodes) {
                    focusNode.nextFocus();
                  }
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
                },
                child: Center(
                  child: TextField(
                    focusNode: widget.focusNodes[index],
                    controller: widget.controllers[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onTap: () {
                      widget.focusNodes[index].requestFocus();
                      widget.controllers[index].selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: widget.controllers[index].text.length,
                      );
                      // });
                    },
                    onEditingComplete: () {
                      if (index < 17) {
                        widget.focusNodes[index + 1].requestFocus();
                      } else {
                        widget.focusNodes[index].unfocus();
                      }
                    },
                    onChanged: (text) async {
                      int? value = int.tryParse(text);
                      widget.score[index] = value ?? 0;
                      await _saveScore(index, value ?? 0);
                      widget.onScoreChanged();
                    },
                    decoration: InputDecoration(
                      hintText: '${tempPar.isEmpty ? 4 : tempPar[index]}',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 33,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 33,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
            if (isStrokeHole)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ShapePainter(
                    tempPar.isEmpty ? 4 : tempPar[index],
                    score,
                    isStrokeHole,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = Provider.of<ScaleFactorProvider>(context).scaleFactor;

    int length = 18;
    if (widget.coursePars.contains(0)) {
      length = 9;
    }

    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            await _loadPlayerDetails();
            int playerCount = await dbHelper.getPlayerCount();
            showCupertinoDialog(
              // ignore: use_build_context_synchronously
              context: context,
              builder: (context) => CupertinoAlertDialog(
                content: Column(
                  children: [
                    CupertinoTextField(
                      controller: widget.nameController,
                      keyboardType: TextInputType.text,
                      enableSuggestions: false,
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
            decoration: BoxDecoration(
              color: widget.playerTeamColor ?? Colors.white,
              borderRadius: const BorderRadius.only(
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
                  final playerName = snapshot.data;
                  return AutoSizeText(
                    playerName?.isNotEmpty == true ? playerName! : 'Name',
                    style: TextStyle(
                      color: playerName?.isNotEmpty == true
                          ? Colors.black
                          : Colors.grey,
                      fontSize: 30,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        ...List.generate((length), (index) {
          return FutureBuilder<bool>(
              future: widget.isStrokeHole?.call(index, widget.playerIndex),
              builder: (context, snapshot) {
                bool isStrokeHole = snapshot.data ?? false;
                return Container(
                  width: 100 * scaleFactor,
                  height: 80 * scaleFactor,
                  margin: EdgeInsets.all(2 * scaleFactor),
                  decoration: BoxDecoration(
                    color: widget.skinsWonByHole[index]
                        ? Colors.yellow
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:
                          index == 0 ? const Radius.circular(12) : Radius.zero,
                      bottomLeft:
                          index == 0 ? const Radius.circular(12) : Radius.zero,
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildTextField(
                        index,
                        scaleFactor,
                        isStrokeHole,
                      ),
                    ),
                  ),
                );
              });
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
              if (length == 18)
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
              if (length == 18)
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
              if (length == 18)
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
              if (length == 9)
                AutoSizeText(
                  'T: ${widget.score.sublist(0, 9).reduce((a, b) => a + b) - widget.coursePars.reduce((a, b) => a + b) >= 0 ? "+" : ""}${widget.score.sublist(0, 9).reduce((a, b) => a + b) - widget.coursePars.reduce((a, b) => a + b)}/${widget.score.sublist(0, 9).reduce((a, b) => a + b)}',
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
  final bool? isStrokeHole;

  _ShapePainter(this.par, this.score, this.isStrokeHole);

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
    final radius = size.width / 3;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < count; i++) {
      final offset = Offset(
        center.dx + (i - (count - 1) / 2) * radius * 0,
        center.dy,
      );
      canvas.drawCircle(
        offset,
        radius - i * 8,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }
  }

  void _drawSquares(Canvas canvas, Size size, int count) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (int i = 0; i < count; i++) {
      final halfSize = size.width / 5 * (1 - 0.3 * i);
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
