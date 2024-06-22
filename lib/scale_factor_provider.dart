import 'package:flutter/material.dart';

class ScaleFactorProvider with ChangeNotifier {
  double _scaleFactor = 1.0;

  double get scaleFactor => _scaleFactor;

  void setScaleFactor(double scaleFactor) {
    _scaleFactor = scaleFactor;
    notifyListeners();
  }
}
