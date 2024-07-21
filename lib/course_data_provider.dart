import 'package:flutter/cupertino.dart';
import 'package:scorecard_app/database_helper.dart';

class CourseDataProvider extends ChangeNotifier {
  List<int> _par = [];
  List<int> get par => _par;
  List<int> _mensHcap = [];
  List<int> get mensHcap => _mensHcap;
  List<int> _womensHcap = [];
  List<int> get womensHcap => _womensHcap;
  int _playerCount = 1;
  int get playerCount => _playerCount;

  String _selectedCourse = 'Default Course';
  String get selectedCourse => _selectedCourse;
  String _selectedTees = 'Default Tees';
  String get selectedTees => _selectedTees;

  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<void> setSelectedCourse(String courseName, String tees) async {
    _selectedCourse = courseName;
    _selectedTees = tees;
    await dbHelper.insertRecentCourse(courseName, tees);
    notifyListeners();
  }

  Future<void> loadRecentCourse() async {
    final recentCourse = await dbHelper.getRecentCourse();
    _selectedCourse = recentCourse['courseName'] ?? 'Shaughnessy G&CC';
    _selectedTees = recentCourse['tees'] ?? 'Whites';
    notifyListeners();
  }

  void updateCourseData({
    required List<int> newPar,
    required List<int> newMensHcap,
    required List<int> newWomensHcap,
  }) {
    _par = newPar;
    _mensHcap = newMensHcap;
    _womensHcap = newWomensHcap;
    notifyListeners();
  }

  void updatePlayerCount(int newPlayerCount) {
    _playerCount = newPlayerCount;
    notifyListeners();
  }
}
