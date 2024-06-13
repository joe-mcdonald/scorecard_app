import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerRow extends StatefulWidget {
  final List<int> score;
  final List<int> fairwaysHit;
  final List<int> greensHit;
  final List<int> par;
  final List<FocusNode> focusNodes;
  final List<TextEditingController> controllers;
  final TextEditingController nameController;
  final ScrollController scrollController;

  const PlayerRow({
    super.key,
    required this.score,
    required this.fairwaysHit,
    required this.greensHit,
    required this.par,
    required this.focusNodes,
    required this.controllers,
    required this.nameController,
    required this.scrollController,
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

  Widget _buildTextField(int index) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
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
                    (index * 105.0 + 10) - (screenWidth / 2 - 100);
                widget.scrollController.animateTo(
                  targetScrollPosition,
                  duration: const Duration(milliseconds: 50),
                  curve: Curves.easeInOut,
                );
              });
            },
            child: TextField(
              onTap: () {
                setState(() {
                  widget.focusNodes[index].requestFocus();
                  widget.controllers[index].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: widget.controllers[index].text.length,
                  );
                  double screenWidth = MediaQuery.of(context).size.width;
                  double targetScrollPosition =
                      (index * 105.0 + 10) - (screenWidth / 2 - 100);
                  widget.scrollController.animateTo(
                    targetScrollPosition,
                    duration: const Duration(milliseconds: 10),
                    curve: Curves.easeInOut,
                  );
                });
              },
              focusNode: widget.focusNodes[index],
              controller: widget.controllers[index],
              onChanged: (text) {
                int? value = int.tryParse(text);
                if (value != null) {
                  setState(() {
                    widget.score[index] = value;
                    _saveScores();
                  });
                } else {
                  setState(() {
                    widget.score[index] = 0;
                    _saveScores();
                  });
                }
              },
              decoration: InputDecoration(
                hintText: '${widget.par[index]}',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 30),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black, fontSize: 30),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ShapePainter(widget.par[index],
                  int.tryParse(widget.controllers[index].text)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 80,
          margin: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: TextField(
            controller: widget.nameController,
            maxLength: 5,
            decoration: const InputDecoration(
              counterText: '',
              hintText: 'Name',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
        ...List.generate(18, (index) {
          return Container(
            width: 100,
            height: 80,
            margin: const EdgeInsets.all(2),
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
                child: _buildTextField(index),
              ),
            ),
          );
        }),
        Container(
          width: 100,
          height: 80,
          margin: const EdgeInsets.all(2),
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
              Text(
                'F: ${widget.score.sublist(0, 9).reduce((a, b) => a + b)}',
                style: const TextStyle(color: Colors.black, fontSize: 16),
                textAlign: TextAlign.left,
              ),
              Text(
                'B: ${widget.score.sublist(9, 18).reduce((a, b) => a + b)}',
                style: const TextStyle(color: Colors.black, fontSize: 16),
                textAlign: TextAlign.left,
              ),
              Text(
                'T: ${widget.score.sublist(0, 9).reduce((a, b) => a + b) + widget.score.sublist(9, 18).reduce((a, b) => a + b)}',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
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
