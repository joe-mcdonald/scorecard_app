// ignore_for_file: use_build_context_synchronously, avoid_print
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/course_data_provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';
import 'package:scorecard_app/widgets/course_action_sheet.dart';
import 'package:scorecard_app/widgets/match_play_press_row.dart';
import 'package:scorecard_app/widgets/match_play_results_row.dart';
import 'package:scorecard_app/widgets/match_play_results_row_9.dart';
import 'package:scorecard_app/widgets/player_row.dart';
import 'package:scorecard_app/widgets/putts_row.dart';
import 'package:scorecard_app/widgets/settings_page.dart';
import 'package:scorecard_app/widgets/skins_row.dart';
import 'package:scorecard_app/widgets/team_match_play_results_row.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;

  final dbHelper = DatabaseHelper();
  final List<List<TextEditingController>> playersControllers = [
    List.generate(18, (index) => TextEditingController())
  ];
  final List<List<TextEditingController>> puttsControllers = [
    List.generate(18, (index) => TextEditingController())
  ];

  List<int> fairwaysHit = List.generate(18, (index) => 0);
  List<int> greensHit = List.generate(18, (index) => 0);

  List<List<int>> score =
      List.generate(4, (index) => List.generate(18, (index) => 0));
  List<int> par = [5, 4, 3, 4, 5, 4, 5, 3, 4, 4, 5, 3, 4, 4, 5, 4, 3, 4];
  List<List<FocusNode>> playersFocusNodes =
      List.generate(4, (index) => List.generate(18, (index) => FocusNode()));

  List<FocusNode> puttsFocusNodes = List.generate(18, (index) => FocusNode());

  List<String> tees = [];
  List<int> mensHcap = List.generate(18, (index) => 0);
  List<int> womensHcap = List.generate(18, (index) => 0);
  String selectedTee = 'Whites';
  String selectedCourse = 'shaughnessyg&cc';
  Map<String, List<int>> yardages = {};
  Map<String, List<int>> pars = {
    'Whites': [5, 4, 3, 4, 5, 4, 5, 3, 4, 4, 5, 3, 4, 4, 5, 4, 3, 4]
  };

  bool showFairwayGreen = false;
  bool mensHandicap = true;
  bool showPutterRow = false;
  bool matchPlayMode = false;
  bool teamMatchPlayMode = false;
  bool addRowForBack9 = false;
  String matchPlayFormat = 'Four Ball';
  ScrollController scrollController = ScrollController();
  bool hasSeenMatchPlayWinDialog = false;

  List<int> matchPlayResults = List.generate(18, (index) => 0);
  List<int> matchPlayResultsBack9 = List.generate(9, (index) => 0);
  List<int> matchPlayResultsPair1 = List.generate(18, (index) => 0);
  List<int> matchPlayResultsPair2 = List.generate(18, (index) => 0);
  List<int> matchPlayResultsPair1Back9 = List.generate(9, (index) => 0);
  List<int> matchPlayResultsPair2Back9 = List.generate(9, (index) => 0);

  List<int> pressStartHoles = [];
  List<List<int>> pressMatchPlayResults = [];
  Map<int, List<int>> presses = {};

  bool skinsMode = false;
  int skinValue = 2;
  List<int> skinsArray = List.generate(18, (index) => 2);
  List<int> skinsWon = [0, 0, 0, 0];
  List<List<bool>> skinsWonByHole =
      List.generate(4, (_) => List.filled(18, false));

  Future<void> _startPress(int holeIndex) async {
    final prefs = await SharedPreferences.getInstance();

    if (!presses.containsKey(holeIndex)) {
      setState(() {
        presses[holeIndex] =
            _calculatePressMatchPlay(holeIndex, teamMatchPlayMode);
      });

      // Save updated presses list to SharedPreferences
      await prefs.setStringList(
          'presses', presses.keys.map((e) => e.toString()).toList());
    }
  }

  Future<void> _loadPressData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPresses = prefs.getStringList('presses') ?? [];

    setState(() {
      presses.clear();
      for (String hole in storedPresses) {
        int startHole = int.parse(hole);
        presses[startHole] =
            _calculatePressMatchPlay(startHole, teamMatchPlayMode);
      }
    });
  }

  void _removePress(int startHole) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      presses.remove(startHole);
    });

    // Save the updated presses list to SharedPreferences
    await prefs.setStringList(
        'presses', presses.keys.map((e) => e.toString()).toList());
  }

  List<int> _calculatePressMatchPlay(int startHole, bool? teamFormat) {
    List<int> pressResults = List.generate(18, (index) => 0); // Initialize

    for (int i = startHole; i < 18; i++) {
      final prevPressScore = (i == startHole) ? 0 : pressResults[i - 1];

      final holeResult;
      if (teamFormat == true) {
        holeResult = matchPlayResults[i] - matchPlayResults[i - 1];
      } else {
        holeResult = matchPlayResultsPair1[i] - matchPlayResultsPair1[i - 1];
      }

      if (holeResult < 0) {
        pressResults[i] = prevPressScore - 1; // Player 1 wins the hole in press
      } else if (holeResult > 0) {
        pressResults[i] = prevPressScore + 1; // Player 2 wins the hole in press
      } else {
        pressResults[i] = prevPressScore; // Tie, no change
      }
    }

    // trim the list to only include the holes that are relevant to the press
    pressResults = pressResults.sublist(startHole);
    return pressResults;
  }

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _loadCourseData(selectedCourse);
    _loadRecentCourse();
    _loadSettings();
    _loadStats();
    _calculateMatchPlayScores();
    _loadPressData();
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (var focusNode in puttsFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNodes in playersFocusNodes) {
      for (var focusNode in focusNodes) {
        focusNode.dispose();
      }
    }
    for (var playerControllers in playersControllers) {
      for (var controller in playerControllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'fairwaysHit', fairwaysHit.map((e) => e.toString()).toList());
    prefs.setStringList(
        'greensHit', greensHit.map((e) => e.toString()).toList());
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? fairwayStrings = prefs.getStringList('fairwaysHit');
    List<String>? greenStrings = prefs.getStringList('greensHit');

    setState(() {
      fairwaysHit = fairwayStrings?.map(int.parse).toList() ??
          List.generate(18, (index) => 0);
      greensHit = greenStrings?.map(int.parse).toList() ??
          List.generate(18, (index) => 0);
    });
  }

  Future<void> _loadRecentCourse() async {
    await Provider.of<CourseDataProvider>(context, listen: false)
        .loadRecentCourse();
    selectedCourse =
        Provider.of<CourseDataProvider>(context, listen: false).selectedCourse;
    selectedTee =
        Provider.of<CourseDataProvider>(context, listen: false).selectedTees;
  }

  Future<void> _loadPlayers() async {
    final scores = await dbHelper.getScores();
    if (scores.isNotEmpty) {
      // setState(() {
      int maxPlayerIndex = scores
          .map((e) => e['playerIndex'] as int)
          .reduce((a, b) => a > b ? a : b);
      playersControllers.clear();
      for (int i = 0; i <= maxPlayerIndex; i++) {
        playersControllers
            .add(List.generate(18, (index) => TextEditingController()));
      }
      // });

      // Load scores into the controllers
      for (var score in scores) {
        int playerIndex = score['playerIndex'];
        int holeIndex = score['holeIndex'];
        int scoreValue = score['score'];
        // playersControllers[playerIndex][holeIndex].text = scoreValue.toString();
        playersControllers[playerIndex][holeIndex].text =
            scoreValue == 0 ? '' : scoreValue.toString();
      }
    }
    Provider.of<CourseDataProvider>(context, listen: false)
        .updatePlayerCount(playersControllers.length);
  }

  Future<void> _loadCourseData(String course) async {
    Map<String, String?> recentCourseData = await dbHelper.getRecentCourse();
    String recentCourse = recentCourseData['courseName'] ?? '';

    recentCourse = recentCourse.toLowerCase().replaceAll(' ', '');

    final rawData =
        await rootBundle.loadString('assets/$recentCourse - Sheet1.csv');
    List<List<dynamic>> csvData = const CsvToListConverter().convert(rawData);
    // setState(() {
    mensHcap = csvData[3].sublist(1).map((e) => e as int).toList();
    // womensHcap = csvData[4].sublist(1).map((e) => e as int).toList(); // temp remove
    womensHcap = csvData[3].sublist(1).map((e) => e as int).toList();

    tees = csvData.map((row) => row[0].toString()).skip(5).toList();
    for (var row in csvData.skip(5)) {
      String teeName = row[0];
      List<int> yardage = row.sublist(1).map((e) => e as int).toList();
      List<int> par = row.sublist(19).map((e) => e as int).toList();
      yardages[teeName] = yardage;
      pars[teeName] = par;
    }
    // par = csvData[2].sublist(1).map((e) => e as int).toList();
    selectedTee = tees[0];
    isLoading = false;
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CourseDataProvider>(context, listen: false)
            .updateCourseData(
          newPar: pars[selectedTee]!,
          newMensHcap: mensHcap,
          // newWomensHcap: womensHcap,
          newWomensHcap: mensHcap,
        );
      }
    });
    // dbHelper.insertRecentCourse(course, selectedTee);
  }

  void _addPlayer() {
    setState(() {
      int newPlayerIndex = playersControllers.length;
      // Add new player controller
      playersControllers
          .add(List.generate(18, (index) => TextEditingController()));
      // Clear the controllers for the new player
      for (var controller in playersControllers[newPlayerIndex]) {
        controller.clear();
      }
      // Insert new player details in the database
      dbHelper.insertPlayerDetails(newPlayerIndex, '', 0);
      // Ensure the new player's scores are initialized correctly
      for (int holeIndex = 0; holeIndex < 18; holeIndex++) {
        dbHelper.insertScore(newPlayerIndex, holeIndex, 0);
      }
      Provider.of<CourseDataProvider>(context, listen: false)
          .updatePlayerCount(playersControllers.length);
    });
  }

  void _removePlayer(int index) async {
    // Remove player controllers and update UI
    setState(() {
      playersControllers.removeAt(index);
      dbHelper.deletePlayerScores(index);
      dbHelper.removePlayerDetails(index);
      Provider.of<CourseDataProvider>(context, listen: false)
          .updatePlayerCount(playersControllers.length);
    });

    await dbHelper.removePlayerDetails(index);

    // Update player indices in the database
    await dbHelper.updatePlayerIndices(index);

    // Reload players to refresh the UI
    await _loadPlayers();

    // Check if the transition from team match play to regular match play is needed
    if (playersControllers.length == 2 && teamMatchPlayMode && matchPlayMode) {
      teamMatchPlayMode = false;
      await _calculateMatchPlay12(); // Calculate match play scores for player 1 and 2
    }
  }

  void _resetValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Clear the list of player controllers and scores except for the first player
      playersControllers.removeRange(1, playersControllers.length);
      // focusNodes.removeRange(1, focusNodes.length);

      // clear the number of players in course data provider
      Provider.of<CourseDataProvider>(context, listen: false)
          .updatePlayerCount(1);

      // Reset the first player
      playersControllers[0] =
          List.generate(18, (index) => TextEditingController());

      // Clear the controllers
      for (var controller in playersControllers[0]) {
        controller.clear();
      }

      int numberOfHoles = 18;
      if (selectedCourse == 'Cordova Bay Ridge Course') {
        numberOfHoles = 9;
      }

      fairwaysHit = List.generate(18, (index) => 0);
      score = List.generate(4, (index) => List.generate(18, (index) => 0));
      greensHit = List.generate(18, (index) => 0);
      matchPlayResults = List.generate(18, (index) => 0);
      matchPlayResultsBack9 = List.generate(9, (index) => 0);
      matchPlayResultsPair1 = List.generate(18, (index) => 0);
      matchPlayResultsPair2 = List.generate(18, (index) => 0);
      matchPlayResultsPair1Back9 = List.generate(9, (index) => 0);
      matchPlayResultsPair2Back9 = List.generate(9, (index) => 0);
      hasSeenMatchPlayWinDialog = false;

      // Update course and tee selection
      selectedTee = tees.isNotEmpty ? tees[0] : 'Whites';
      selectedCourse = ''; // or the default course

      presses.clear();
    });

    // Clear the database
    await dbHelper.deleteScores();
    await dbHelper.deletePutts();
    await dbHelper.clearPlayerDetails();

    // Reset the first player's details
    await dbHelper.setPlayerName(0, '');
    await dbHelper.setHandicap(0, 0);

    // Initialize scores for the first player
    for (int holeIndex = 0; holeIndex < 18; holeIndex++) {
      await dbHelper.insertScore(0, holeIndex, 0);
    }

    // Save the updated state
    // _saveScores();
    // _saveState();

    await prefs.remove('presses');
  }

  Future<void> _shareRoundDetails() async {
    String details = await _formatRoundDetails();
    Share.share(details, subject: 'Golf Round Details');
  }

  Future<String> _formatRoundDetails() async {
    StringBuffer details = StringBuffer();

    details.writeln('Golf Round Details:');
    details.writeln('Course: $selectedCourse');
    details.writeln('Tee: $selectedTee');
    details.writeln('');

    for (int playerIndex = 0;
        playerIndex < playersControllers.length;
        playerIndex++) {
      String? playerName = await dbHelper.getPlayerName(playerIndex) ??
          'Player ${playerIndex + 1}';
      int totalScore = 0;
      int frontScore = 0;
      int backScore = 0;
      for (int holeIndex = 0; holeIndex < 18; holeIndex++) {
        int score = await dbHelper.getScoreForHole(playerIndex, holeIndex);
        if (holeIndex >= 0 && holeIndex <= 8) {
          frontScore += score;
        }
        if (holeIndex >= 9 && holeIndex <= 17) {
          backScore += score;
        }
        totalScore += score;
      }
      // String scoresString =
      //     scores.map((score) => score == 0 ? '' : score.toString()).join(', ');

      details.writeln('Player: $playerName');
      details.writeln('Front: $frontScore');
      details.writeln('Back: $backScore');
      details.writeln('Score: $totalScore');
      details.writeln('');
    }

    // if (showPutterRow) {
    //   int totalPutts = 0;
    //   for (int holeIndex = 0; holeIndex < 18; holeIndex++) {
    //     totalPutts += await dbHelper.getPuttsForHole(holeIndex);
    //   }
    //   details.writeln('Putts: $totalPutts');
    //   details.writeln('');
    // }

    // print(details.toString());
    return details.toString();
  }

  bool isHandicapHole(int index, int handicapDifference) {
    return mensHcap[index] <= handicapDifference.abs();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    matchPlayMode = prefs.getBool('matchPlayMode') ?? false;
    showFairwayGreen = prefs.getBool('showFairwayGreen') ?? false;
    showPutterRow = prefs.getBool('showPuttsPerHole') ?? false;
    mensHandicap = true;
    teamMatchPlayMode = prefs.getBool('teamMatchPlayMode') ?? true;
    addRowForBack9 = prefs.getBool('addRowForFront9') ?? false;
    matchPlayFormat = prefs.getString('matchPlayFormat') ?? 'Four Ball';
    skinsMode = prefs.getBool('skinsMode') ?? false;
    skinValue = prefs.getInt('skinValue') ?? 2;
  }

  void _showSettingsPage(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
      (route) => false,
    );
  }

  Future<void> _calculateMatchPlay12() async {
    if (matchPlayMode == false && skinsMode == true) {
      await _calculateSkins();
      return;
    }
    final playerCount = await dbHelper.getPlayerCount();
    if (playerCount < 1) return;

    //if negative, player 2 gets strokes, if positive, player 1 gets strokes
    int player1Handicap = (await dbHelper.getHandicap(0)) ?? 0;
    int player2Handicap = (await dbHelper.getHandicap(1)) ?? 0;
    int netStrokes = player1Handicap - player2Handicap;

    matchPlayResultsPair1 = List.generate(18, (index) => 0);
    matchPlayResultsPair1Back9 = List.generate(9, (index) => 0);

    for (int i = 0; i < 18; i++) {
      final player1Score = await dbHelper.getScoreForHole(0, i);
      final player2Score = await dbHelper.getScoreForHole(1, i);
      if (player1Score == 0 || player2Score == 0) {
        for (int j = i; j < 9; j++) {
          matchPlayResultsPair1Back9[j] = 0;
        }
        break;
      }

      bool isHandicapHole = false;
      isHandicapHole = mensHcap[i] <= netStrokes.abs();

      if (player1Score != 0 && player2Score != 0) {
        if (isHandicapHole) {
          if (netStrokes > 0) {
            //player 1 gets extra stroke
            if ((player1Score < player2Score + 1)) {
              //playerindex 0 holeindex i < playerindex 1 holeindex i + 1
              if (i == 0) {
                matchPlayResultsPair1[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResultsPair1[i] = matchPlayResultsPair1[i - 1] - 1;
              }
            } else if (player1Score > (player2Score) + 1) {
              //playerindex 0 holeindex i > playerindex 1 holeindex i + 1
              if (i == 0) {
                matchPlayResultsPair1[i] = 1; //positive  == player 2 lead
              } else {
                matchPlayResultsPair1[i] = matchPlayResultsPair1[i - 1] + 1;
              }
            } else {
              if (i == 0) {
                matchPlayResultsPair1[i] = 0; //tie == nothing changes
              } else {
                matchPlayResultsPair1[i] = matchPlayResultsPair1[i - 1];
              }
            }
          } else if (netStrokes < 0) {
            if (((player1Score) + 1 < (player2Score))) {
              //playerindex 0 holeindex i  + 1 < playerindex 1 holeindex i
              if (i == 0) {
                matchPlayResultsPair1[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResultsPair1[i] = matchPlayResultsPair1[i - 1] - 1;
              }
            } else if ((player1Score) + 1 > (player2Score)) {
              //playerindex 0 holeindex i + 1 > playerindex 1 holeindex i
              if (i == 0) {
                matchPlayResultsPair1[i] = 1; //positive  == player 2 lead
              } else {
                matchPlayResultsPair1[i] = matchPlayResultsPair1[i - 1] + 1;
              }
            } else {
              if (i == 0) {
                matchPlayResultsPair1[i] = 0; //tie == nothing changes
              } else {
                matchPlayResultsPair1[i] = matchPlayResultsPair1[i - 1];
              }
            }
          }
        } else {
          if ((player1Score < player2Score)) {
            //playerindex 0 holeindex i < playerindex 1 holeindex i
            if (i == 0) {
              matchPlayResultsPair1[i] = -1; //negative == player 1 lead
            } else {
              matchPlayResultsPair1[i] = matchPlayResultsPair1[i - 1] - 1;
            }
          } else if (player1Score > player2Score) {
            //playerindex 0 holeindex i > playerindex 1 holeindex i
            if (i == 0) {
              matchPlayResultsPair1[i] = 1; //positive  == player 2 lead
            } else {
              matchPlayResultsPair1[i] = matchPlayResultsPair1[i - 1] + 1;
            }
          } else {
            if (i == 0) {
              matchPlayResultsPair1[i] = 0; //tie == nothing changes
            } else {
              matchPlayResultsPair1[i] = matchPlayResultsPair1[i - 1];
            }
          }
        }
      } else {
        matchPlayResultsPair1[i] = 0;
      }
    }

    for (int i = 0; i < 9; i++) {
      final player1Score = await dbHelper.getScoreForHole(0, i + 9);
      final player2Score = await dbHelper.getScoreForHole(1, i + 9);
      if (player1Score == 0 || player2Score == 0) {
        for (int j = i; j < 9; j++) {
          matchPlayResultsPair1Back9[j] = 0;
        }
        break;
      }

      bool isHandicapHole = false;
      isHandicapHole = mensHcap[i + 9] <= netStrokes.abs();

      if (player1Score != 0 && player2Score != 0) {
        if (isHandicapHole) {
          if (netStrokes > 0) {
            //player 1 gets extra stroke
            if ((player1Score < player2Score + 1)) {
              //playerindex 0 holeindex i < playerindex 1 holeindex i + 1
              if (i == 0) {
                matchPlayResultsPair1Back9[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResultsPair1Back9[i] =
                    matchPlayResultsPair1Back9[i - 1] - 1;
              }
            } else if (player1Score > (player2Score) + 1) {
              //playerindex 0 holeindex i > playerindex 1 holeindex i + 1
              if (i == 0) {
                matchPlayResultsPair1Back9[i] = 1; //positive  == player 2 lead
              } else {
                matchPlayResultsPair1Back9[i] =
                    matchPlayResultsPair1Back9[i - 1] + 1;
              }
            } else {
              if (i == 0) {
                matchPlayResultsPair1Back9[i] = 0; //tie == nothing changes
              } else {
                matchPlayResultsPair1Back9[i] =
                    matchPlayResultsPair1Back9[i - 1];
              }
            }
          } else if (netStrokes < 0) {
            if (((player1Score) + 1 < (player2Score))) {
              //playerindex 0 holeindex i  + 1 < playerindex 1 holeindex i
              if (i == 0) {
                matchPlayResultsPair1Back9[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResultsPair1Back9[i] =
                    matchPlayResultsPair1Back9[i - 1] - 1;
              }
            } else if ((player1Score) + 1 > (player2Score)) {
              //playerindex 0 holeindex i + 1 > playerindex 1 holeindex i
              if (i == 0) {
                matchPlayResultsPair1Back9[i] = 1; //positive  == player 2 lead
              } else {
                matchPlayResultsPair1Back9[i] =
                    matchPlayResultsPair1Back9[i - 1] + 1;
              }
            } else {
              if (i == 0) {
                matchPlayResultsPair1Back9[i] = 0; //tie == nothing changes
              } else {
                matchPlayResultsPair1Back9[i] =
                    matchPlayResultsPair1Back9[i - 1];
              }
            }
          }
        } else {
          if ((player1Score < player2Score)) {
            //playerindex 0 holeindex i < playerindex 1 holeindex i
            if (i == 0) {
              matchPlayResultsPair1Back9[i] = -1; //negative == player 1 lead
            } else {
              matchPlayResultsPair1Back9[i] =
                  matchPlayResultsPair1Back9[i - 1] - 1;
            }
          } else if (player1Score > player2Score) {
            //playerindex 0 holeindex i > playerindex 1 holeindex i
            if (i == 0) {
              matchPlayResultsPair1Back9[i] = 1; //positive  == player 2 lead
            } else {
              matchPlayResultsPair1Back9[i] =
                  matchPlayResultsPair1Back9[i - 1] + 1;
            }
          } else {
            if (i == 0) {
              matchPlayResultsPair1Back9[i] = 0; //tie == nothing changes
            } else {
              matchPlayResultsPair1Back9[i] = matchPlayResultsPair1Back9[i - 1];
            }
          }
        }
      } else {
        matchPlayResultsPair1Back9[i] = 0;
      }

      // if ((player1Score < player2Score)) {
      //   //playerindex 0 holeindex i < playerindex 1 holeindex i
      //   if (i == 0) {
      //     matchPlayResultsPair1Back9[i] = -1; //negative == player 1 lead
      //   } else {
      //     matchPlayResultsPair1Back9[i] = matchPlayResultsPair1Back9[i - 1] - 1;
      //   }
      // } else if (player1Score > (player2Score)) {
      //   //playerindex 0 holeindex i > playerindex 1 holeindex i
      //   if (i == 0) {
      //     matchPlayResultsPair1Back9[i] = 1; //positive  == player 2 lead
      //   } else {
      //     matchPlayResultsPair1Back9[i] = matchPlayResultsPair1Back9[i - 1] + 1;
      //   }
      // } else {
      //   if (i == 0) {
      //     matchPlayResultsPair1Back9[i] = 0; //tie == nothing changes
      //   } else {
      //     matchPlayResultsPair1Back9[i] = matchPlayResultsPair1Back9[i - 1];
      //   }
      // }
    }

    // Trigger a rebuild to display the results
    if (presses.isNotEmpty) {
      for (int startHole in pressStartHoles) {
        pressMatchPlayResults[pressStartHoles.indexOf(startHole)] =
            _calculatePressMatchPlay(startHole, false);
      }
    }
    setState(() {});
  }

  Future<void> _calculateMatchPlay34() async {
    if (matchPlayMode == false && skinsMode == true) {
      await _calculateSkins();
      return;
    }
    final playerCount = await dbHelper.getPlayerCount();
    if (playerCount < 1) return;

    //if negative, player 2 gets strokes, if positive, player 1 gets strokes
    int player3Handicap = (await dbHelper.getHandicap(2)) ?? 0;
    int player4Handicap = (await dbHelper.getHandicap(3)) ?? 0;
    int netStrokes = player3Handicap - player4Handicap;

    matchPlayResultsPair2 = List.generate(18, (index) => 0);
    matchPlayResultsPair2Back9 = List.generate(9, (index) => 0);

    for (int i = 0; i < 18; i++) {
      final player3Score = await dbHelper.getScoreForHole(2, i);
      final player4Score = await dbHelper.getScoreForHole(3, i);
      if (player3Score == 0 || player4Score == 0) {
        for (int j = i; j < 9; j++) {
          matchPlayResultsPair2Back9[j] = 0;
        }
        break;
      }

      bool isHandicapHole = false;
      isHandicapHole = mensHcap[i] <= netStrokes.abs();

      if (player3Score != 0 && player4Score != 0) {
        if (isHandicapHole) {
          if (netStrokes > 0) {
            //player 3 gets extra stroke
            if ((player3Score < player4Score + 1)) {
              //playerindex 0 holeindex i < playerindex 1 holeindex i + 1
              if (i == 0) {
                matchPlayResultsPair2[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] - 1;
              }
            } else if (player3Score > (player4Score) + 1) {
              //playerindex 0 holeindex i > playerindex 1 holeindex i + 1
              if (i == 0) {
                matchPlayResultsPair2[i] = 1; //positive  == player 2 lead
              } else {
                matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] + 1;
              }
            } else {
              if (i == 0) {
                matchPlayResultsPair2[i] = 0; //tie == nothing changes
              } else {
                matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1];
              }
            }
          } else if (netStrokes < 0) {
            if (((player3Score) + 1 < (player4Score))) {
              //playerindex 0 holeindex i  + 1 < playerindex 1 holeindex i
              if (i == 0) {
                matchPlayResultsPair2[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] - 1;
              }
            } else if ((player3Score) + 1 > (player4Score)) {
              //playerindex 0 holeindex i + 1 > playerindex 1 holeindex i
              if (i == 0) {
                matchPlayResultsPair2[i] = 1; //positive  == player 2 lead
              } else {
                matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] + 1;
              }
            } else {
              if (i == 0) {
                matchPlayResultsPair2[i] = 0; //tie == nothing changes
              } else {
                matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1];
              }
            }
          }
        } else {
          if (player3Score < player4Score) {
            //playerindex 0 holeindex i < playerindex 1 holeindex i
            if (i == 0) {
              matchPlayResultsPair2[i] = -1; //negative == player 1 lead
            } else {
              matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] - 1;
            }
          } else if (player3Score > player4Score) {
            //playerindex 0 holeindex i > playerindex 1 holeindex i
            if (i == 0) {
              matchPlayResultsPair2[i] = 1; //positive  == player 2 lead
            } else {
              matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] + 1;
            }
          } else {
            if (i == 0) {
              matchPlayResultsPair2[i] = 0; //tie == nothing changes
            } else {
              matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1];
            }
          }
        }
      } else {
        matchPlayResultsPair2[i] = 0;
      }
    }

    for (int i = 0; i < 9; i++) {
      final player3Score = await dbHelper.getScoreForHole(2, i + 9);
      final player4Score = await dbHelper.getScoreForHole(3, i + 9);

      if (player3Score == 0 || player4Score == 0) {
        for (int j = i; j < 9; j++) {
          matchPlayResultsPair2Back9[j] = 0;
        }
        break;
      }

      bool isHandicapHole = false;
      isHandicapHole = mensHcap[i + 9] <= netStrokes.abs();

      if (player3Score != 0 && player4Score != 0) {
        if (isHandicapHole) {
          if (netStrokes > 0) {
            //player 1 gets extra stroke
            if ((player3Score < player4Score + 1)) {
              //playerindex 0 holeindex i < playerindex 1 holeindex i + 1
              if (i == 0) {
                matchPlayResultsPair2Back9[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResultsPair2Back9[i] =
                    matchPlayResultsPair2Back9[i - 1] - 1;
              }
            } else if (player3Score > (player4Score) + 1) {
              //playerindex 0 holeindex i > playerindex 1 holeindex i + 1
              if (i == 0) {
                matchPlayResultsPair2Back9[i] = 1; //positive  == player 2 lead
              } else {
                matchPlayResultsPair2Back9[i] =
                    matchPlayResultsPair2Back9[i - 1] + 1;
              }
            } else {
              if (i == 0) {
                matchPlayResultsPair2Back9[i] = 0; //tie == nothing changes
              } else {
                matchPlayResultsPair2Back9[i] =
                    matchPlayResultsPair2Back9[i - 1];
              }
            }
          } else if (netStrokes < 0) {
            if (((player3Score) + 1 < (player4Score))) {
              //playerindex 0 holeindex i  + 1 < playerindex 1 holeindex i
              if (i == 0) {
                matchPlayResultsPair2Back9[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResultsPair2Back9[i] =
                    matchPlayResultsPair2Back9[i - 1] - 1;
              }
            } else if ((player3Score) + 1 > (player4Score)) {
              //playerindex 0 holeindex i + 1 > playerindex 1 holeindex i
              if (i == 0) {
                matchPlayResultsPair2Back9[i] = 1; //positive  == player 2 lead
              } else {
                matchPlayResultsPair2Back9[i] =
                    matchPlayResultsPair2Back9[i - 1] + 1;
              }
            } else {
              if (i == 0) {
                matchPlayResultsPair2Back9[i] = 0; //tie == nothing changes
              } else {
                matchPlayResultsPair2Back9[i] =
                    matchPlayResultsPair2Back9[i - 1];
              }
            }
          }
        } else {
          if ((player3Score < player4Score)) {
            //playerindex 0 holeindex i < playerindex 1 holeindex i
            if (i == 0) {
              matchPlayResultsPair2Back9[i] = -1; //negative == player 1 lead
            } else {
              matchPlayResultsPair2Back9[i] =
                  matchPlayResultsPair2Back9[i - 1] - 1;
            }
          } else if (player3Score > player4Score) {
            //playerindex 0 holeindex i > playerindex 1 holeindex i
            if (i == 0) {
              matchPlayResultsPair2Back9[i] = 1; //positive  == player 2 lead
            } else {
              matchPlayResultsPair2Back9[i] =
                  matchPlayResultsPair2Back9[i - 1] + 1;
            }
          } else {
            if (i == 0) {
              matchPlayResultsPair2Back9[i] = 0; //tie == nothing changes
            } else {
              matchPlayResultsPair2Back9[i] = matchPlayResultsPair2Back9[i - 1];
            }
          }
        }
      } else {
        matchPlayResultsPair2Back9[i] = 0;
      }
    }

    // Trigger a rebuild to display the results
    if (presses.isNotEmpty) {
      for (int startHole in pressStartHoles) {
        pressMatchPlayResults[pressStartHoles.indexOf(startHole)] =
            _calculatePressMatchPlay(startHole, false);
      }
    }
    setState(() {});

    // if (matchPlayMode == false && skinsMode == true) {
    //   await _calculateSkins();
    //   return;
    // }
    // final playerCount = await dbHelper.getPlayerCount();
    // if (playerCount < 1) return;

    // //if negative, player 2 gets strokes, if positive, player 1 gets strokes
    // int player3Handicap = (await dbHelper.getHandicap(2)) ?? 0;
    // int player4Handicap = (await dbHelper.getHandicap(3)) ?? 0;
    // int netStrokes = player3Handicap - player4Handicap;

    // matchPlayResultsPair2 = List.generate(18, (index) => 0);

    // for (int i = 0; i < 18; i++) {
    //   final player3Score = await dbHelper.getScoreForHole(2, i);
    //   final player4Score = await dbHelper.getScoreForHole(3, i);
    //   if (player3Score == 0 || player4Score == 0) {
    //     matchPlayResultsPair2[i] = 0;
    //     setState(() {});
    //     return;
    //   }

    //   final isHandicapHole = mensHcap[i] <= netStrokes.abs();

    //   if (player3Score != 0 && player4Score != 0) {
    //     if (isHandicapHole) {
    //       if (netStrokes > 0) {
    //         //player 1 gets extra stroke
    //         if ((player3Score < player4Score + 1)) {
    //           if (i == 0 || i == 9) {
    //             matchPlayResultsPair2[i] = -1; //negative == player 1 lead
    //           } else {
    //             matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] - 1;
    //           }
    //         } else if (player3Score > (player4Score) + 1) {
    //           if (i == 0 || i == 9) {
    //             matchPlayResultsPair2[i] = 1; //positive  == player 2 lead
    //           } else {
    //             matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] + 1;
    //           }
    //         } else {
    //           if (i == 0 || i == 9) {
    //             matchPlayResultsPair2[i] = 0; //tie == nothing changes
    //           } else {
    //             matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1];
    //           }
    //         }
    //       } else if (netStrokes < 0) {
    //         if (((player3Score) + 1 < (player4Score))) {
    //           if (i == 0 || i == 9) {
    //             matchPlayResultsPair2[i] = -1; //negative == player 1 lead
    //           } else {
    //             matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] - 1;
    //           }
    //         } else if ((player3Score) + 1 > (player4Score)) {
    //           if (i == 0 || i == 9) {
    //             matchPlayResultsPair2[i] = 1; //positive  == player 2 lead
    //           } else {
    //             matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] + 1;
    //           }
    //         } else {
    //           if (i == 0 || i == 9) {
    //             matchPlayResultsPair2[i] = 0; //tie == nothing changes
    //           } else {
    //             matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1];
    //           }
    //         }
    //       }
    //     } else {
    //       if ((player3Score < (player4Score))) {
    //         if (i == 0 || i == 9) {
    //           matchPlayResultsPair2[i] = -1; //negative == player 1 lead
    //         } else {
    //           matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] - 1;
    //         }
    //       } else if (player3Score > (player4Score)) {
    //         if (i == 0 || i == 9) {
    //           matchPlayResultsPair2[i] = 1; //positive  == player 2 lead
    //         } else {
    //           matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] + 1;
    //         }
    //       } else {
    //         if (i == 0 || i == 9) {
    //           matchPlayResultsPair2[i] = 0; //tie == nothing changes
    //         } else {
    //           matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1];
    //         }
    //       }
    //     }
    //   } else {
    //     matchPlayResultsPair2[i] = 0;
    //   }
    // }
    // // Trigger a rebuild to display the results
    // if (presses.isNotEmpty) {
    //   for (int startHole in pressStartHoles) {
    //     pressMatchPlayResults[pressStartHoles.indexOf(startHole)] =
    //         _calculatePressMatchPlay(startHole, false);
    //   }
    // }
    // setState(() {});
  }

  // void _showWinDialog(String title, String message) {
  //   showCupertinoDialog(
  //     context: context,
  //     builder: (BuildContext context) => CupertinoAlertDialog(
  //       title: Text(title),
  //       content: Text(message),
  //       actions: <CupertinoDialogAction>[
  //         CupertinoDialogAction(
  //           child: const Text('OK'),
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  //   hasSeenMatchPlayWinDialog = true;
  // }

  Future<void> _calculateTeamMatchPlayFourBall() async {
    final playerCount = await dbHelper.getPlayerCount();
    if (playerCount < 4) return;

    // if (await dbHelper.getPlayerCount() as int < 2) return;

    int player1Handicap = (await dbHelper.getHandicap(0)) ?? 0;
    int player2Handicap = (await dbHelper.getHandicap(1)) ?? 0;
    int player3Handicap = (await dbHelper.getHandicap(2)) ?? 0;
    int player4Handicap = (await dbHelper.getHandicap(3)) ?? 0;

    int lowerstHandicap = [
      player1Handicap,
      player2Handicap,
      player3Handicap,
      player4Handicap
    ].reduce((a, b) => a < b ? a : b);

    int netStrokesPlayer1 = player1Handicap - lowerstHandicap;
    int netStrokesPlayer2 = player2Handicap - lowerstHandicap;
    int netStrokesPlayer3 = player3Handicap - lowerstHandicap;
    int netStrokesPlayer4 = player4Handicap - lowerstHandicap;

    matchPlayResults = List.generate(18, (index) => 0);
    matchPlayResultsBack9 = List.generate(9, (index) => 0);

    for (int i = 0; i < 18; i++) {
      final player1Score = await dbHelper.getScoreForHole(0, i);
      final player2Score = await dbHelper.getScoreForHole(1, i);
      final player3Score = await dbHelper.getScoreForHole(2, i);
      final player4Score = await dbHelper.getScoreForHole(3, i);

      // Check if any of the scores are missing
      if (player1Score == 0 ||
          player2Score == 0 ||
          player3Score == 0 ||
          player4Score == 0) {
        for (int j = i; j < 18; j++) {
          matchPlayResults[j] = 0;
        }
        break;
      }

      // Determine if the current hole is a handicap hole
      final isHandicapHole = mensHandicap ? mensHcap[i] : womensHcap[i];

      final netScorePlayer1 =
          player1Score - (netStrokesPlayer1 >= isHandicapHole ? 1 : 0);
      final netScorePlayer2 =
          player2Score - (netStrokesPlayer2 >= isHandicapHole ? 1 : 0);
      final netScorePlayer3 =
          player3Score - (netStrokesPlayer3 >= isHandicapHole ? 1 : 0);
      final netScorePlayer4 =
          player4Score - (netStrokesPlayer4 >= isHandicapHole ? 1 : 0);

      // Best ball for Team 1
      final bestBallTeam1 =
          [netScorePlayer1, netScorePlayer2].reduce((a, b) => a < b ? a : b);
      // Best ball for Team 2
      final bestBallTeam2 =
          [netScorePlayer3, netScorePlayer4].reduce((a, b) => a < b ? a : b);

      // Determine the result for the hole
      if (bestBallTeam1 < bestBallTeam2) {
        if (i == 0) {
          matchPlayResults[i] = -1; // Team 1 wins the hole
        } else {
          matchPlayResults[i] = matchPlayResults[i - 1] - 1;
        }
        // matchPlayResults[i] = -1; // Team 1 wins the hole
      } else if (bestBallTeam1 > bestBallTeam2) {
        if (i == 0) {
          matchPlayResults[i] = 1; // Team 2 wins the hole
        } else {
          matchPlayResults[i] = matchPlayResults[i - 1] + 1;
        }
        // matchPlayResults[i] = 1; // Team 2 wins the hole
      } else {
        if (i == 0) {
          matchPlayResults[i] = 0; // The hole is tied
        } else {
          matchPlayResults[i] = matchPlayResults[i - 1];
        }
        // matchPlayResults[i] = 0; // The hole is tied
      }

      // Check for early match win
      // if (!hasSeenMatchPlayWinDialog && i > 8) {
      //   int team1Wins = matchPlayResults.where((result) => result == -1).length;
      //   int team2Wins = matchPlayResults.where((result) => result == 1).length;

      //   if (team1Wins >= 10) {
      //     _showWinDialog('Team 1 Wins!', 'Team 1 has won the match play.');
      //     break;
      //   } else if (team2Wins >= 10) {
      //     _showWinDialog('Team 2 Wins!', 'Team 2 has won the match play.');
      //     break;
      //   }
      // }
    }

    for (int i = 0; i < 9; i++) {
      final player1Score = await dbHelper.getScoreForHole(0, i + 9);
      final player2Score = await dbHelper.getScoreForHole(1, i + 9);
      final player3Score = await dbHelper.getScoreForHole(2, i + 9);
      final player4Score = await dbHelper.getScoreForHole(3, i + 9);

      // Check if any of the scores are missing
      if (player1Score == 0 ||
          player2Score == 0 ||
          player3Score == 0 ||
          player4Score == 0) {
        for (int j = i; j < 9; j++) {
          matchPlayResultsBack9[j] = 0;
        }
        break;
      }

      // Determine if the current hole is a handicap hole
      final isHandicapHole = mensHandicap ? mensHcap[i + 9] : womensHcap[i + 9];

      final netScorePlayer1 =
          player1Score - (netStrokesPlayer1 >= isHandicapHole ? 1 : 0);
      final netScorePlayer2 =
          player2Score - (netStrokesPlayer2 >= isHandicapHole ? 1 : 0);
      final netScorePlayer3 =
          player3Score - (netStrokesPlayer3 >= isHandicapHole ? 1 : 0);
      final netScorePlayer4 =
          player4Score - (netStrokesPlayer4 >= isHandicapHole ? 1 : 0);

      // Best ball for Team 1
      final bestBallTeam1 =
          [netScorePlayer1, netScorePlayer2].reduce((a, b) => a < b ? a : b);
      // Best ball for Team 2
      final bestBallTeam2 =
          [netScorePlayer3, netScorePlayer4].reduce((a, b) => a < b ? a : b);

      // Determine the result for the hole
      if (bestBallTeam1 < bestBallTeam2) {
        if (i == 0) {
          matchPlayResultsBack9[i] = -1; // Team 1 wins the hole
        } else {
          matchPlayResultsBack9[i] = matchPlayResultsBack9[i - 1] - 1;
        }
        // matchPlayResults[i] = -1; // Team 1 wins the hole
      } else if (bestBallTeam1 > bestBallTeam2) {
        if (i == 0) {
          matchPlayResultsBack9[i] = 1; // Team 2 wins the hole
        } else {
          matchPlayResultsBack9[i] = matchPlayResultsBack9[i - 1] + 1;
        }
        // matchPlayResults[i] = 1; // Team 2 wins the hole
      } else {
        if (i == 0) {
          matchPlayResultsBack9[i] = 0; // The hole is tied
        } else {
          matchPlayResultsBack9[i] = matchPlayResultsBack9[i - 1];
        }
        // matchPlayResults[i] = 0; // The hole is tied
      }
    }

    // Trigger a rebuild to display the results
    setState(() {});
  }

  // Future<void> _calculateTeamMatchPlayAlternateShot() async {
  //   final playerCount = await dbHelper.getPlayerCount();
  //   if (playerCount < 4) return;
  //   int player1Handicap = (await dbHelper.getHandicap(0)) ?? 0;
  //   int player2Handicap = (await dbHelper.getHandicap(1)) ?? 0;
  //   int player3Handicap = (await dbHelper.getHandicap(2)) ?? 0;
  //   int player4Handicap = (await dbHelper.getHandicap(3)) ?? 0;
  //   // Find the lowest handicap among all players
  //   int lowestHandicap = [
  //     player1Handicap,
  //     player2Handicap,
  //     player3Handicap,
  //     player4Handicap
  //   ].reduce((a, b) => a < b ? a : b);
  //   // Calculate the strokes each player receives
  //   int netStrokesPlayer1 = player1Handicap - lowestHandicap;
  //   int netStrokesPlayer2 = player2Handicap - lowestHandicap;
  //   int netStrokesPlayer3 = player3Handicap - lowestHandicap;
  //   int netStrokesPlayer4 = player4Handicap - lowestHandicap;
  //   matchPlayResults = List.generate(18, (index) => 0);
  //   for (int i = 0; i < 18; i++) {
  //     final player1Score = await dbHelper.getScoreForHole(0, i);
  //     final player2Score = await dbHelper.getScoreForHole(1, i);
  //     final player3Score = await dbHelper.getScoreForHole(2, i);
  //     final player4Score = await dbHelper.getScoreForHole(3, i);
  //     // Check if any of the scores are missing
  //     if (player1Score == 0 &&
  //         player2Score == 0 &&
  //         player3Score == 0 &&
  //         player4Score == 0) {
  //       matchPlayResults[i] = 0;
  //       continue;
  //     }
  //     // Determine if the current hole is a handicap hole
  //     // final isHandicapHole = mensHandicap ? mensHcap[i] : womensHcap[i];
  //     final isHandicapHole = mensHcap[i];
  //     // Calculate the net scores considering the alternate shot format
  //     final netScoreTeam1 = (i % 2 == 0)
  //         ? player1Score - (netStrokesPlayer1 >= isHandicapHole ? 1 : 0)
  //         : player2Score - (netStrokesPlayer2 >= isHandicapHole ? 1 : 0);
  //     final netScoreTeam2 = (i % 2 == 0)
  //         ? player3Score - (netStrokesPlayer3 >= isHandicapHole ? 1 : 0)
  //         : player4Score - (netStrokesPlayer4 >= isHandicapHole ? 1 : 0);
  //     // Determine the result for the hole
  //     if (netScoreTeam1 < netScoreTeam2) {
  //       matchPlayResults[i] = (i == 0) ? -1 : matchPlayResults[i - 1] - 1;
  //     } else if (netScoreTeam1 > netScoreTeam2) {
  //       matchPlayResults[i] = (i == 0) ? 1 : matchPlayResults[i - 1] + 1;
  //     } else {
  //       matchPlayResults[i] = (i == 0) ? 0 : matchPlayResults[i - 1];
  //     }
  //     // Check for early match win
  //     if (!hasSeenMatchPlayWinDialog && i > 8) {
  //       int team1Wins = matchPlayResults.where((result) => result < 0).length;
  //       int team2Wins = matchPlayResults.where((result) => result > 0).length;
  //       if (team1Wins >= 10) {
  //         _showWinDialog('Team 1 Wins!', 'Team 1 has won the match play.');
  //         break;
  //       } else if (team2Wins >= 10) {
  //         _showWinDialog('Team 2 Wins!', 'Team 2 has won the match play.');
  //         break;
  //       }
  //     }
  //   }
  //   // Trigger a rebuild to display the results
  //   setState(() {});
  // }

  Future<bool> isStrokeHole(int hole, int playerIndex) async {
    // if playercount is 1 return false
    if (Provider.of<CourseDataProvider>(context).playerCount == 1) {
      return false;
    }

    // if there are 2 players, use the 1v1 matchplay. the player with the lower handicap gets the strokes (stroke difference)
    if (Provider.of<CourseDataProvider>(context).playerCount == 2 ||
        (Provider.of<CourseDataProvider>(context).playerCount == 3 &&
            (playerIndex == 0 || playerIndex == 1))) {
      if (playerIndex == 0) {
        // if player 1
        int player1Handicap = await dbHelper.getHandicap(0) ?? 0;
        int player2Handicap = await dbHelper.getHandicap(1) ?? 0;
        int handicapDifference = player1Handicap - player2Handicap;
        // if (mensHandicap) {
        return mensHcap[hole] <= handicapDifference;
        // } else {
        //   return womensHcap[hole] <= handicapDifference;
        // }
      } else if (playerIndex == 1) {
        // if player 2
        int player1Handicap = await dbHelper.getHandicap(0) ?? 0;
        int player2Handicap = await dbHelper.getHandicap(1) ?? 0;
        int handicapDifference = player2Handicap - player1Handicap;
        // if (mensHandicap) {
        return mensHcap[hole] <= handicapDifference;
        // } else {
        //   return womensHcap[hole] <= handicapDifference;
        // }
      } else {
        return false; // if there are 3 players, the 3rd player isnt involved so return false
      }
    }

    int playerHandicap = await dbHelper.getHandicap(playerIndex) ?? 0;
    int lowestHandicap = 999;
    for (int i = 0; i < 4; i++) {
      int handicap = await dbHelper.getHandicap(i) ?? 0;
      if (handicap < lowestHandicap) {
        lowestHandicap = handicap;
      }
    }
    int handicapDifference = playerHandicap - lowestHandicap;
    // if (mensHandicap) {
    return mensHcap[hole] <= handicapDifference.abs();
    // } else {
    //   return womensHcap[hole] <= handicapDifference.abs();
    // }
  }

  void _toggleFairway(int index) async {
    setState(() {
      fairwaysHit[index] = fairwaysHit[index] == 0 ? 1 : 0;
    });
    await _saveStats();
  }

  void _toggleGreen(int index) async {
    setState(() {
      greensHit[index] = greensHit[index] == 0 ? 1 : 0;
    });
    await _saveStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateMatchPlayScores();
  }

  Future<void> _calculateMatchPlayScores() async {
    if (matchPlayMode) {
      int playerCount = Provider.of<CourseDataProvider>(context).playerCount;
      if (teamMatchPlayMode) {
        await _calculateTeamMatchPlayFourBall();
      } else {
        if (playerCount == 2 || playerCount == 3 || playerCount == 4) {
          await _calculateMatchPlay12();
          if (Provider.of<CourseDataProvider>(context, listen: false)
                  .playerCount ==
              4) {
            await _calculateMatchPlay34();
          }
        }
      }
    }
    setState(() {});
  }

  Future<void> _calculateSkins() async {
    final prefs = await SharedPreferences.getInstance();
    final playerCount = await dbHelper.getPlayerCount();

    List<int> player1Score = List.generate(18, (index) => 0);
    List<int> player2Score = List.generate(18, (index) => 0);
    List<int> player3Score = List.generate(18, (index) => 0);
    List<int> player4Score = List.generate(18, (index) => 0);

    int carryOver = prefs.getInt('skinValue') ?? 2; // Default $2 per skin
    int skinValue = prefs.getInt('skinValue') ?? 2; // Default $2 per skin

    // Initialize skinsArray globally (if not already initialized)
    skinsArray = List.generate(18, (index) => skinValue);
    skinsWon = [0, 0, 0, 0];
    skinsWonByHole =
        List.generate(4, (index) => List.generate(18, (index) => false));

    if (playerCount == 2) {
      int player1Handicap = await dbHelper.getHandicap(0) ?? 0;
      int player2Handicap = await dbHelper.getHandicap(1) ?? 0;
      int netStrokes = player1Handicap - player2Handicap;

      // Get scores for both players
      for (int i = 0; i < 18; i++) {
        player1Score[i] = await dbHelper.getScoreForHole(0, i);
        player2Score[i] = await dbHelper.getScoreForHole(1, i);
      }

      // Loop through each hole and determine who wins or if it's a tie
      for (int i = 0; i < 18; i++) {
        if (player1Score[i] == 0 || player2Score[i] == 0) {
          continue; // Skip unplayed holes
        }

        // Apply net strokes if necessary
        bool isHandicapHole = false;
        isHandicapHole = mensHcap[i] <= netStrokes.abs();
        int p1NetScore = player1Score[i];
        int p2NetScore = player2Score[i];
        if (isHandicapHole) {
          p1NetScore = player1Score[i] - (netStrokes > 0 ? 1 : 0);
          p2NetScore = player2Score[i] - (netStrokes < 0 ? 1 : 0);
        }

        if (p1NetScore < p2NetScore) {
          // Player 1 wins, claim skins
          skinsArray[i] = carryOver;
          skinsWon[0] = skinsArray[i];
          carryOver = skinValue; // Reset carryOver for the next hole
          skinsWonByHole[0][i] = true;
        } else if (p2NetScore < p1NetScore) {
          // Player 2 wins, claim skins
          skinsArray[i] = carryOver;
          skinsWon[1] = skinsArray[i];
          carryOver = skinValue; // Reset carryOver for the next hole
          skinsWonByHole[1][i] = true;
        } else {
          // Tie: add the current carryOver to the next hole
          skinsArray[i] = carryOver;
          carryOver += skinValue;
        }
      }
    }

    // Handle cases where there are 3 or 4 players
    if (playerCount >= 3) {
      List<List<int>> scores = [player1Score, player2Score];
      List<int> handicaps = [
        await dbHelper.getHandicap(0) ?? 0,
        await dbHelper.getHandicap(1) ?? 0
      ];

      if (playerCount >= 3) {
        scores.add(player3Score);
        handicaps.add(await dbHelper.getHandicap(2) ?? 0);
      }
      if (playerCount == 4) {
        scores.add(player4Score);
        handicaps.add(await dbHelper.getHandicap(3) ?? 0);
      }

      // Get scores for all players
      for (int i = 0; i < 18; i++) {
        for (int p = 0; p < playerCount; p++) {
          scores[p][i] = await dbHelper.getScoreForHole(p, i);
        }
      }

      for (int i = 0; i < 18; i++) {
        if (scores.any((scoreList) => scoreList[i] == 0)) {
          continue; // Skip unplayed holes
        }

        // Determine the net scores for each player
        // List<int> netScores = List.generate(playerCount, (p) => scores[p][i]);

        int lowestHandicap = handicaps.reduce((a, b) => a < b ? a : b);

        List<int> netScores = List.generate(playerCount, (p) {
          int handicapDifference = handicaps[p] - lowestHandicap;
          bool getsStroke = mensHcap[i] <= handicapDifference.abs();
          return scores[p][i] - (getsStroke ? 1 : 0);
        });

        // Find the minimum score
        int minScore = netScores.reduce((a, b) => a < b ? a : b);

        // Check if there is a tie for the minimum score
        int minScoreCount =
            netScores.where((score) => score == minScore).length;

        if (minScoreCount == 1) {
          // Only one player has the minimum score, they win the skins
          int winnerIndex = netScores.indexOf(minScore);
          skinsArray[i] = carryOver;
          skinsWon[winnerIndex] += skinsArray[i];
          carryOver = skinValue; // Reset carryOver for the next hole
          if (i < 17) skinsArray[i + 1] = skinValue;
          skinsWonByHole[winnerIndex][i] = true;
        } else {
          // Tie: add the current carryOver to the next hole
          skinsArray[i] = carryOver;
          carryOver += skinValue;
        }
        if (i < 17) {
          for (int j = i + 2; j < 18; j++) {
            skinsArray[j] = skinsArray[j - 1] + skinValue;
          }
        }
      }
    }
    setState(() {});
  }

  OverlayEntry? _skinsOverlay;

  void _showSkinsOverlay(BuildContext context) async {
    final overlay = Overlay.of(context);

    _skinsOverlay = OverlayEntry(
      builder: (context) => FutureBuilder<List<String>>(
        future: _fetchPlayerNames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final playerNames = snapshot.data ?? [];
            return Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 300,
                    child: Material(
                      color: Colors.white,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Skins Results',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  playerNames[0],
                                  style: const TextStyle(fontSize: 20),
                                ),
                                Text(
                                  '\$${skinsWon[0]}',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  playerNames[1],
                                  style: const TextStyle(fontSize: 20),
                                ),
                                Text(
                                  '\$${skinsWon[1]}',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                            if (playersControllers.length >= 3)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    playerNames[2],
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  Text(
                                    '\$${skinsWon[2]}',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            if (playersControllers.length >= 4)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    playerNames[3],
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  Text(
                                    '\$${skinsWon[3]}',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );

    overlay.insert(_skinsOverlay!);
  }

  Future<List<String>> _fetchPlayerNames() async {
    List<String> playerNames = await Future.wait([
      dbHelper.getPlayerName(0).then((value) => value ?? ''),
      dbHelper.getPlayerName(1).then((value) => value ?? ''),
      if (playersControllers.length >= 3)
        dbHelper.getPlayerName(2).then((value) => value ?? ''),
      if (playersControllers.length >= 4)
        dbHelper.getPlayerName(3).then((value) => value ?? ''),
    ]);
    return playerNames;
  }

  void _hideSkinsOverlay() {
    _skinsOverlay?.remove();
    _skinsOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = Provider.of<ScaleFactorProvider>(context).scaleFactor;
    pars.isEmpty ? _loadCourseData('') : null;

    int numberOfHoles = 18;
    if (selectedCourse == 'Cordova Bay Ridge Course') {
      numberOfHoles = 9;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 120, 79),
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _showSettingsPage(context),
        ),
        title: ElevatedButton(
          onPressed: () async {
            showCupertinoModalPopup<void>(
              context: context,
              builder: (BuildContext context) => CourseActionSheet(
                onCourseSelected: (course, tee) {
                  // setState(() {
                  selectedCourse = course;
                  selectedTee = tee;
                  dbHelper.insertRecentCourse(course, tee);
                  // });
                },
                onCourseDataLoaded: (loadedPars,
                    loadedMensHcap,
                    loadedWomensHcap,
                    loadedTees,
                    loadedYardages,
                    loadedSelectedTee) {
                  // setState(() {
                  pars = loadedPars;
                  mensHcap = loadedMensHcap;
                  womensHcap = loadedWomensHcap;
                  tees = loadedTees;
                  yardages = loadedYardages;
                  selectedTee = loadedSelectedTee;
                  isLoading = false;
                  // });
                },
                pars: pars,
                mensHcap: mensHcap,
                womensHcap: womensHcap,
                tees: tees,
                yardages: yardages,
                selectedTee: selectedTee,
                isLoading: isLoading,
              ),
            );
            // setState(() {});
          },
          style: ElevatedButton.styleFrom(
            elevation: 8.0,
            backgroundColor: const Color.fromARGB(255, 0, 120, 79),
            shadowColor: Colors.black,
          ),
          child: AutoSizeText(
            selectedCourse.isEmpty ? 'Select Course' : selectedCourse,
            style: const TextStyle(color: Colors.white),
            maxFontSize: 26,
            minFontSize: 16,
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              selectedTee,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            onPressed: () {
              showCupertinoModalPopup<void>(
                context: context,
                builder: (BuildContext context) => SizedBox(
                  height: 400,
                  child: CupertinoActionSheet(
                    title: const Text('Tees', style: TextStyle(fontSize: 25)),
                    message: const Text(
                      'Select a tee.',
                      style: TextStyle(fontSize: 20),
                    ),
                    actions: tees.map((tee) {
                      return CupertinoActionSheetAction(
                        onPressed: () {
                          setState(() {
                            selectedTee = tee;
                            dbHelper.insertRecentCourse(selectedCourse, tee);
                          });
                          Provider.of<CourseDataProvider>(context,
                                  listen: false)
                              .updateCourseData(
                            newPar: pars[selectedTee]!,
                            newMensHcap: mensHcap,
                            newWomensHcap: womensHcap,
                          );

                          Navigator.pop(context);
                        },
                        child: Text(
                          tee,
                          style: const TextStyle(fontSize: 20),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: const Color.fromRGBO(225, 225, 225, 1),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 20 * scaleFactor),
                  child: Row(
                    children: List.generate(
                      numberOfHoles,
                      (index) {
                        return IgnorePointer(
                          ignoring: false,
                          child: Container(
                            width: 100 * scaleFactor,
                            height: 110 * scaleFactor,
                            margin: EdgeInsets.all(2 * scaleFactor),
                            // color: Colors.white,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              // handicapHole ? Colors.grey : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: index == 0
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                                topRight: index == 17
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                                bottomLeft: index == 0
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                                bottomRight: index == 17
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                // handicapHole ? Colors.grey : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: index == 0
                                      ? const Radius.circular(12)
                                      : Radius.zero,
                                  topRight: index == 17
                                      ? const Radius.circular(12)
                                      : Radius.zero,
                                  bottomLeft: index == 0
                                      ? const Radius.circular(12)
                                      : Radius.zero,
                                  bottomRight: index == 17
                                      ? const Radius.circular(12)
                                      : Radius.zero,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 5),
                                    Text(
                                      'Hole ${index + 1}',
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                    Text(
                                      'Par ${pars[selectedTee]?[index]}',
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 16),
                                    ),
                                    Text(
                                      '${yardages[selectedTee]?[index] ?? 0} yards',
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 16),
                                    ),
                                    if (mensHandicap == true)
                                      Text(
                                        'HCap: ${mensHcap[index]}',
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 16),
                                      ),
                                    if (mensHandicap == false)
                                      Text(
                                        'HCap: ${womensHcap[index]}',
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 16),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                if (teamMatchPlayMode &&
                    matchPlayMode &&
                    Provider.of<CourseDataProvider>(context).playerCount == 4)
                  if (matchPlayFormat == 'Four Ball')
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ...playersControllers.asMap().entries.map((entry) {
                              int playerIndex = entry.key;
                              List<TextEditingController> controllers =
                                  entry.value;
                              List<FocusNode> focusNodes =
                                  playersFocusNodes[playerIndex];
                              return PlayerRow(
                                playerIndex: playerIndex,
                                tee: selectedTee,
                                coursePars: pars[selectedTee]!.toList(),
                                fairwaysHit: fairwaysHit,
                                greensHit: greensHit,
                                par: par,
                                score: score[playerIndex],
                                focusNodes: focusNodes,
                                controllers: controllers,
                                nameController: TextEditingController(),
                                hcapController: TextEditingController(),
                                scrollController: scrollController,
                                removePlayer: _removePlayer,
                                onScoreChanged: _calculateTeamMatchPlayFourBall,
                                playerTeamColor: playerIndex < 2
                                    ? const Color.fromRGBO(255, 139, 139, 1)
                                    : const Color.fromRGBO(171, 178, 255, 1),
                                isStrokeHole: isStrokeHole,
                                skinsWonByHole: skinsWonByHole[playerIndex],
                              );
                            }),
                            FutureBuilder<List<String?>>(
                              future: Future.wait([
                                dbHelper.getPlayerName(0),
                                dbHelper.getPlayerName(1),
                                dbHelper.getPlayerName(2),
                                dbHelper.getPlayerName(3),
                              ]),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return const Text(
                                      'Error loading player names');
                                } else {
                                  final playerNames = snapshot.data!;
                                  String team1Name = '';
                                  if (playerNames[0] == "" ||
                                      playerNames[1] == "") {
                                    team1Name = 'Team 1';
                                  } else {
                                    team1Name =
                                        '${playerNames[0]!.substring(0, 1)}+${playerNames[1]!.substring(0, 1)}';
                                  }
                                  String team2Name = '';
                                  if (playerNames[2] == "" ||
                                      playerNames[3] == "") {
                                    team2Name = 'Team 2';
                                  } else {
                                    team2Name =
                                        '${playerNames[2]!.substring(0, 1)}+${playerNames[3]!.substring(0, 1)}';
                                  }
                                  return Column(
                                    children: [
                                      if (addRowForBack9) // TODO: fix back 9 row
                                        MatchPlayResultsRow9(
                                          matchPlayResults:
                                              matchPlayResultsBack9,
                                          playerNames: [team1Name, team2Name],
                                        ),
                                      TeamMatchPlayResultsRow(
                                        matchPlayResults: matchPlayResults,
                                        teamNames: [team1Name, team2Name],
                                        onLongPress: _startPress,
                                      ),
                                      for (var entry in presses.entries)
                                        MatchPlayPressRow(
                                          startHole: entry.key,
                                          pressResults:
                                              _calculatePressMatchPlay(
                                                  entry.key, true),
                                          playerNames: [
                                            team1Name ?? 'Team 1',
                                            team2Name ?? 'Team 2',
                                          ],
                                          pressLabel: '${entry.key + 1}',
                                          onLongPress: _removePress,
                                        ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                if (!matchPlayMode ||
                    !teamMatchPlayMode ||
                    (teamMatchPlayMode &&
                        Provider.of<CourseDataProvider>(context).playerCount !=
                            4) ||
                    (matchPlayMode &&
                        Provider.of<CourseDataProvider>(context).playerCount <
                            4))
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...playersControllers.asMap().entries.map((entry) {
                            int playerIndex = entry.key;
                            List<TextEditingController> controllers =
                                entry.value;
                            List<FocusNode> focusNodes =
                                playersFocusNodes[playerIndex];
                            if (playerIndex == 0 || playerIndex == 1) {
                              return PlayerRow(
                                //TODO SKINS HIGHLIGHTS
                                playerIndex: playerIndex,
                                tee: selectedTee,
                                coursePars: pars[selectedTee]!.toList(),
                                fairwaysHit: fairwaysHit,
                                greensHit: greensHit,
                                par: par,
                                score: score[playerIndex],
                                focusNodes: focusNodes,
                                controllers: controllers,
                                nameController: TextEditingController(),
                                hcapController: TextEditingController(),
                                scrollController: scrollController,
                                removePlayer: _removePlayer,
                                onScoreChanged: _calculateMatchPlay12,
                                isStrokeHole: isStrokeHole,
                                skinsWonByHole: skinsWonByHole[playerIndex],
                              );
                            } else {
                              return Container();
                            }
                          }),
                          if (matchPlayMode &&
                              (Provider.of<CourseDataProvider>(context)
                                          .playerCount ==
                                      2 ||
                                  Provider.of<CourseDataProvider>(context)
                                          .playerCount ==
                                      3 ||
                                  Provider.of<CourseDataProvider>(context)
                                          .playerCount ==
                                      4))
                            FutureBuilder<List<String?>>(
                              future: Future.wait([
                                dbHelper.getPlayerName(0),
                                dbHelper.getPlayerName(1),
                              ]),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return const Text(
                                      'Error loading player names');
                                } else {
                                  final playerNames = snapshot.data!;
                                  return Column(
                                    children: [
                                      if (addRowForBack9)
                                        MatchPlayResultsRow9(
                                          matchPlayResults:
                                              matchPlayResultsPair1Back9,
                                          playerNames: [
                                            playerNames[0] ?? 'Player 1',
                                            playerNames[1] ?? 'Player 2',
                                          ],
                                        ),
                                      MatchPlayResultsRow(
                                        matchPlayResults: matchPlayResultsPair1,
                                        playerNames: [
                                          playerNames[0] ?? 'Player 1',
                                          playerNames[1] ?? 'Player 2',
                                        ],
                                        onLongPress: _startPress,
                                      ),
                                      for (var entry in presses.entries)
                                        MatchPlayPressRow(
                                          startHole: entry.key,
                                          pressResults:
                                              _calculatePressMatchPlay(
                                                  entry.key, false),
                                          playerNames: [
                                            playerNames[0] ?? 'Player 1',
                                            playerNames[1] ?? 'Player 2',
                                          ],
                                          pressLabel: '${entry.key + 1}',
                                          onLongPress: _removePress,
                                        ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ...playersControllers.asMap().entries.map((entry) {
                            int playerIndex = entry.key;
                            List<TextEditingController> controllers =
                                entry.value;
                            List<FocusNode> focusNodes =
                                playersFocusNodes[playerIndex];
                            if (playerIndex == 2 || playerIndex == 3) {
                              return PlayerRow(
                                playerIndex: playerIndex,
                                tee: selectedTee,
                                coursePars: pars[selectedTee]!.toList(),
                                fairwaysHit: fairwaysHit,
                                greensHit: greensHit,
                                par: par,
                                score: score[playerIndex],
                                focusNodes: focusNodes,
                                controllers: controllers,
                                nameController: TextEditingController(),
                                hcapController: TextEditingController(),
                                scrollController: scrollController,
                                removePlayer: _removePlayer,
                                onScoreChanged: _calculateMatchPlay34,
                                isStrokeHole: isStrokeHole,
                                skinsWonByHole: skinsWonByHole[playerIndex],
                              );
                            } else {
                              return Container();
                            }
                          }),
                          if (matchPlayMode &&
                              (Provider.of<CourseDataProvider>(context)
                                      .playerCount ==
                                  4))
                            FutureBuilder<List<String?>>(
                              future: Future.wait([
                                dbHelper.getPlayerName(2),
                                dbHelper.getPlayerName(3),
                              ]),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return const Text(
                                      'Error loading player names');
                                } else {
                                  final playerNames = snapshot.data!;
                                  return Column(
                                    children: [
                                      if (addRowForBack9)
                                        MatchPlayResultsRow9(
                                          matchPlayResults:
                                              matchPlayResultsPair2Back9,
                                          playerNames: [
                                            playerNames[0] ?? 'Player 3',
                                            playerNames[1] ?? 'Player 4',
                                          ],
                                        ),
                                      MatchPlayResultsRow(
                                        matchPlayResults: matchPlayResultsPair2,
                                        playerNames: [
                                          playerNames[0] ?? 'Player 3',
                                          playerNames[1] ?? 'Player 4'
                                        ],
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          if (skinsMode &&
                              Provider.of<CourseDataProvider>(context)
                                      .playerCount >=
                                  2)
                            SkinsRow(
                              holeNumber: 1,
                              skinValue: skinsArray,
                            ),
                          if (showPutterRow)
                            Padding(
                              padding: EdgeInsets.only(left: 0 * scaleFactor),
                              child: PuttsRow(
                                playerIndex: 0,
                                scrollController: scrollController,
                                controllers: puttsControllers.isEmpty
                                    ? []
                                    : puttsControllers[0],
                                focusNodes: puttsFocusNodes,
                              ),
                            ),
                          if (showFairwayGreen)
                            Padding(
                              padding:
                                  EdgeInsets.only(right: 20.0 * scaleFactor),
                              child: Row(
                                children: List.generate(
                                  18,
                                  (index) {
                                    return Container(
                                      width: 100 * scaleFactor,
                                      height: 70 * scaleFactor,
                                      margin: EdgeInsets.all(2 * scaleFactor),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: index == 0
                                              ? const Radius.circular(12)
                                              : Radius.zero,
                                          topRight: index == 17
                                              ? const Radius.circular(12)
                                              : Radius.zero,
                                          bottomLeft: index == 0
                                              ? const Radius.circular(12)
                                              : Radius.zero,
                                          bottomRight: index == 17
                                              ? const Radius.circular(12)
                                              : Radius.zero,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          if (pars[selectedTee]?[index] == 4 ||
                                              pars[selectedTee]?[index] == 5)
                                            SizedBox(
                                              height: 35 * scaleFactor,
                                              child: TextButton(
                                                onPressed: () =>
                                                    _toggleFairway(index),
                                                child: Text(
                                                  'Fairway',
                                                  style: TextStyle(
                                                    fontSize: 13 * scaleFactor,
                                                    color:
                                                        fairwaysHit[index] == 1
                                                            ? Colors.green
                                                            : Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (pars[selectedTee]?[index] == 4 ||
                                              pars[selectedTee]?[index] == 5)
                                            SizedBox(
                                              height: 35 * scaleFactor,
                                              child: TextButton(
                                                onPressed: () =>
                                                    _toggleGreen(index),
                                                child: Text(
                                                  'Green',
                                                  style: TextStyle(
                                                    fontSize: 13 * scaleFactor,
                                                    color: greensHit[index] == 1
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (pars[selectedTee]?[index] == 3)
                                            SizedBox(
                                              height: 70 * scaleFactor,
                                              child: TextButton(
                                                onPressed: () =>
                                                    _toggleGreen(index),
                                                child: Text(
                                                  'Green',
                                                  style: TextStyle(
                                                    fontSize: 13 * scaleFactor,
                                                    color: greensHit[index] == 1
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                // box that shows the skins won be each player
                // if (skinsMode && playersControllers.length >= 2)
                //   Column(
                //     children: [
                //       Text('Player 1 Skins won: ${skinsWon[0]}'),
                //       Text('Player 2 Skins won: ${skinsWon[1]}'),
                //       if (playersControllers.length >= 3)
                //         Text('Player 3 Skins won: ${skinsWon[2]}'),
                //       if (playersControllers.length >= 4)
                //         Text('Player 4 Skins won: ${skinsWon[3]}'),
                //     ],
                //   ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 80,
        child: SizedBox(
          height: 80,
          child: Row(
            children: <Widget>[
              if (playersControllers.length < 4)
                GestureDetector(
                  onTap: () {
                    _addPlayer();
                  },
                  child: const Row(
                    children: [
                      SizedBox(width: 8),
                      Icon(Icons.add),
                    ],
                  ),
                ),

              // if (showFairwayGreen)
              //   Padding(
              //     padding: const EdgeInsets.only(
              //         left: 12.0), // Padding to push it closer to the left edg
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Text(
              //           'Fairways Hit: ${_countFairwaysHit()}/${pars[selectedTee]?.where((p) => p == 4 || p == 5).length}',
              //           style: const TextStyle(fontSize: 11),
              //         ),
              //         Text(
              //           'Greens Hit: ${_countGreensHit()}/18',
              //           style: const TextStyle(fontSize: 11),
              //         ),
              //       ],
              //     ),
              //   ),
              if (skinsMode) const SizedBox(width: 25),
              if (skinsMode)
                GestureDetector(
                  onLongPress: () =>
                      _showSkinsOverlay(context), // Show overlay on hold
                  onLongPressUp:
                      _hideSkinsOverlay, // Hide overlay when released
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Skins\nResults',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ), // Eye icon for skins results
                ),

              const Spacer(), // Pushes the settings button to the right
              IconButton(
                onPressed: () {
                  _shareRoundDetails();
                },
                color: CupertinoColors.activeBlue,
                iconSize: 24,
                icon: const Icon(
                  CupertinoIcons.share_up,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              TextButton(
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (BuildContext context) => CupertinoAlertDialog(
                      // title: Text(
                      //   'Reset',
                      //   style: TextStyle(fontSize: 20 * scaleFactor),
                      // ),
                      content: const Text(
                        'Are you sure you want to reset the scores?',
                        style: TextStyle(fontSize: 18),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () {
                            _resetValues();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 20,
                              color: CupertinoColors.destructiveRed,
                            ),
                          ),
                        ),
                        CupertinoDialogAction(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                                fontSize: 20,
                                color: CupertinoColors.activeBlue),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Reset',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 20,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
