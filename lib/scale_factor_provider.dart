import 'package:flutter/material.dart';

class ScaleFactorProvider with ChangeNotifier {
  double _scaleFactor = 0.7;

  double get scaleFactor => _scaleFactor;

  void setScaleFactor(double scaleFactor) {
    _scaleFactor = scaleFactor;
    notifyListeners();
  }
}
