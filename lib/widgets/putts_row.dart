import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/database_helper.dart';
import 'package:scorecard_app/scale_factor_provider.dart';

class PuttsRow extends StatefulWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final int playerIndex;
  final ScrollController scrollController;

  const PuttsRow({
    Key? key,
    required this.controllers,
    required this.focusNodes,
    required this.playerIndex,
    required this.scrollController,
  }) : super(key: key);

  @override
  _PuttsRowState createState() => _PuttsRowState();
}

class _PuttsRowState extends State<PuttsRow> {
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadPutts();
  }

  Future<void> _loadPutts() async {
    for (int i = 0; i < widget.controllers.length; i++) {
      final putts = await dbHelper.getPuttsForHole(i);
      setState(() {
        widget.controllers[i].text = putts?.toString() ?? '';
      });
    }
  }

  Future<void> _savePutts(int holeIndex, int putts) async {
    await dbHelper.insertPutts(holeIndex, putts);
  }

  Widget _buildTextField(int index) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
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
                _savePutts(index, value ?? 0);
              });
            },
            decoration: const InputDecoration(
              hintText: '2',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 33),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(color: Colors.black, fontSize: 33),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double scaleFactor = Provider.of<ScaleFactorProvider>(context).scaleFactor;

    return Row(
      children: [
        Container(
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
          child: const Center(
            child: Text(
              'Putts',
              style: TextStyle(
                color: Colors.black,
                fontSize: 30,
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
                child: _buildTextField(index),
              ),
            ),
          );
        }),
        SizedBox(width: 104.0 * scaleFactor),
      ],
    );
  }
}
