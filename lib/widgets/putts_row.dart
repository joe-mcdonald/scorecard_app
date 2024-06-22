import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PutterRow extends StatefulWidget {
  final List<int> putts;
  final List<int> par;
  final List<FocusNode> focusNodes;
  final List<TextEditingController> controllers;
  final ScrollController scrollController;

  const PutterRow({
    super.key,
    required this.putts,
    required this.par,
    required this.focusNodes,
    required this.controllers,
    required this.scrollController,
  });

  @override
  State<PutterRow> createState() => _PutterRowState();
}

class _PutterRowState extends State<PutterRow> {
  Future<void> _savePutts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('putts', jsonEncode(widget.putts));
  }

  Widget _buildTextField(int index, double scaleFactor) {
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
                  // double screenWidth = MediaQuery.of(context).size.width;
                  // double targetScrollPosition =
                  //     (index * 105.0 + 10) - (screenWidth / 2 - 100);

                  // widget.scrollController.animateTo(
                  //   targetScrollPosition,
                  //   duration: const Duration(milliseconds: 10),
                  //   curve: Curves.easeInOut,
                  // );
                });
              },
              focusNode: widget.focusNodes[index],
              controller: widget.controllers[index],
              onChanged: (text) {
                int? value = int.tryParse(text);
                if (value != null) {
                  setState(() {
                    widget.putts[index] = value;
                    _savePutts();
                  });
                } else {
                  setState(() {
                    widget.putts[index] = 0;
                    _savePutts();
                  });
                }
              },
              decoration: InputDecoration(
                hintText: '2',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 30 * scaleFactor,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 30 * scaleFactor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = Provider.of<ScaleFactorProvider>(context).scaleFactor;
    return Row(
      children: [
        Container(
          width: 80 * scaleFactor,
          padding: EdgeInsets.only(right: 10 * scaleFactor),
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
            child: Text(
              'Putts',
              style: TextStyle(color: Colors.black, fontSize: 20 * scaleFactor),
              textAlign: TextAlign.center,
              // textScaler: TextScaler.linear(scaleFactor),
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

        // TODO: turn this column into a 'average putts per hole' column

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [],
          ),
        ),
      ],
    );
  }
}
