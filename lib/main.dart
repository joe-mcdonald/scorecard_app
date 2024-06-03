import 'package:flutter/material.dart';
import 'package:scorecard_app/home_screen.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
  });
}
