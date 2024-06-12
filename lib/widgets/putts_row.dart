import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PutterRow extends StatefulWidget {
  final List<int> score;
  final List<int> par;
  final List<FocusNode> focusNodes;
  final List<TextEditingController> controllers;
  final ScrollController scrollController;

  const PutterRow({
    super.key,
    required this.score,
    required this.par,
    required this.focusNodes,
    required this.controllers,
    required this.scrollController,
  });

  @override
  State<PutterRow> createState() => _PutterRowState();
}

class _PutterRowState extends State<PutterRow> {
  Future<void> _saveScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('score', jsonEncode(widget.score));
  }

  Widget _buildTextField(int index) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(10), // Adjust padding as needed
          child: GestureDetector(
            onTap: () {
              setState(() {
                widget.focusNodes[index].requestFocus();
                widget.controllers[index].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: widget.controllers[index].text.length,
                );

                // Calculate the target scroll position
                double screenWidth = MediaQuery.of(context).size.width;
                double targetScrollPosition = (index * 105.0 + 10) -
                    (screenWidth / 2 -
                        100); // Assuming each item is 100 wide plus margin

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

                  // Calculate the target scroll position
                  double screenWidth = MediaQuery.of(context).size.width;
                  double targetScrollPosition = (index * 105.0 + 10) -
                      (screenWidth / 2 -
                          100); // Assuming each item is 100 wide plus margin

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
                hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 30), // Adjust font size as needed
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero, // Remove default padding
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 30), // Adjust font size as needed
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
          child: Center(
            child: Text(
              'Putts',
              style: const TextStyle(color: Colors.black, fontSize: 20),
            ),
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
