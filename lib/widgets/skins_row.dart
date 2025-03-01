import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';

class SkinsRow extends StatelessWidget {
  final int holeNumber;
  final List<int> skinValue;

  const SkinsRow({
    super.key,
    required this.holeNumber,
    required this.skinValue,
  });

  @override
  Widget build(BuildContext context) {
    double scaleFactor = Provider.of<ScaleFactorProvider>(context).scaleFactor;

    return Row(
      children: [
        SizedBox(
          width: 84 * scaleFactor,
          height: 40 * scaleFactor,
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
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      skinValue[index].toString(),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        SizedBox(width: 104.0 * scaleFactor),
      ],
    );
  }
}
