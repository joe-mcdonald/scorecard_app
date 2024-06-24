import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scorecard_app/scale_factor_provider.dart';

class PlayerRow extends StatefulWidget {
  final int index;
  final List<int> score;
  final List<int> fairwaysHit;
  final List<int> greensHit;
  final Map<String, List<int>> par;
  final String tee;
  final List<FocusNode> focusNodes;
  final List<TextEditingController> controllers;
  final TextEditingController nameController;
  final TextEditingController hcapController;
  final ScrollController scrollController;
  final Function(int) removePlayer;
  final VoidCallback onScoreChanged;
  final bool matchPlayEnabled;

  const PlayerRow({
    super.key,
    required this.index,
    required this.score,
    required this.fairwaysHit,
    required this.greensHit,
    required this.par,
    required this.tee,
    required this.focusNodes,
    required this.controllers,
    required this.nameController,
    required this.hcapController,
    required this.scrollController,
    required this.removePlayer,
    required this.onScoreChanged,
    required this.matchPlayEnabled,
  });

  @override
  State<PlayerRow> createState() => _PlayerRowState();
}

class _PlayerRowState extends State<PlayerRow> {
  Future<void> _saveScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('score', jsonEncode(widget.score));
    await prefs.setString('fairwaysHit', jsonEncode(widget.fairwaysHit));
    await prefs.setString('greensHit', jsonEncode(widget.greensHit));
  }

  Widget _buildTextField(int index, double scaleFactor) {
    Color textColor = Colors.black; // Default color
    if (widget.matchPlayEnabled) {
      if (widget.index == 0) {
        textColor = Colors.red; // Player 1's color
      } else if (widget.index == 1) {
        textColor = const Color.fromARGB(198, 0, 0, 255); // Player 2's color
      }
    }
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
                  if (value != null) {
                    setState(() {
                      widget.score[index] = value;
                      _saveScores();
                      widget
                          .onScoreChanged(); // Call the callback when score changes
                    });
                  } else {
                    setState(() {
                      widget.score[index] = 0;
                      _saveScores();
                      widget
                          .onScoreChanged(); // Call the callback when score changes
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: '${widget.par[widget.tee]?[index]}',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 33),
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
              painter: _ShapePainter(widget.par[widget.tee]![index],
                  int.tryParse(widget.controllers[index].text)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double scaleFactor = Provider.of<ScaleFactorProvider>(context).scaleFactor;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
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
                  CupertinoDialogAction(
                    child: const Text(
                      'Remove Player',
                      style: TextStyle(color: CupertinoColors.systemRed),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.removePlayer(widget.index);
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
              child: AutoSizeText(
                (widget.nameController.text).isEmpty
                    ? 'Name'
                    : widget.nameController.text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                ),
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
                child: _buildTextField(
                  index,
                  scaleFactor,
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
                'T: ${widget.score.sublist(0, 9).reduce((a, b) => a + b) + widget.score.sublist(9, 18).reduce((a, b) => a + b)}',
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
