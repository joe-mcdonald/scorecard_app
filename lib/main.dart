import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/course_data_provider.dart';
import 'package:scorecard_app/database_helper.dart';
import 'package:scorecard_app/home_screen.dart';
import 'package:scorecard_app/scale_factor_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) async {
    await DatabaseHelper().database; // Initialize database
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => CourseDataProvider()),
          ChangeNotifierProvider(create: (context) => ScaleFactorProvider()),
        ],
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scaleFactorProvider = Provider.of<ScaleFactorProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scaleFactorProvider.scaleFactor),
            boldText: false,
          ),
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
