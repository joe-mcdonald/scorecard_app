// ignore_for_file: use_build_context_synchronously, avoid_print
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/course_data_provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';
import 'package:scorecard_app/widgets/course_action_sheet.dart';
import 'package:scorecard_app/widgets/match_play_results_row.dart';
import 'package:scorecard_app/widgets/player_row.dart';
import 'package:scorecard_app/widgets/putts_row.dart';
import 'package:scorecard_app/widgets/settings_page.dart';
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

  // List<FocusNode> focusNodes = List.generate(18, (index) => FocusNode());

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
  String matchPlayFormat = 'Four Ball';
  ScrollController scrollController = ScrollController();
  bool hasSeenMatchPlayWinDialog = false;

  List<int> matchPlayResults = List.generate(18, (index) => 0);
  List<int> matchPlayResultsPair1 = List.generate(18, (index) => 0);
  List<int> matchPlayResultsPair2 = List.generate(18, (index) => 0);

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _loadCourseData(selectedCourse);
    _loadRecentCourse();
    _loadSettings();
    _calculateMatchPlayScores();
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
    womensHcap = csvData[4].sublist(1).map((e) => e as int).toList();
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
          newWomensHcap: womensHcap,
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

      fairwaysHit = List.generate(18, (index) => 0);
      score = List.generate(4, (index) => List.generate(18, (index) => 0));
      greensHit = List.generate(18, (index) => 0);
      matchPlayResults = List.generate(18, (index) => 0);
      matchPlayResultsPair1 = List.generate(18, (index) => 0);
      matchPlayResultsPair2 = List.generate(18, (index) => 0);
      hasSeenMatchPlayWinDialog = false;

      // Update course and tee selection
      selectedTee = tees.isNotEmpty ? tees[0] : 'Whites';
      selectedCourse = ''; // or the default course
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
      for (int holeIndex = 0; holeIndex < 18; holeIndex++) {
        int score = await dbHelper.getScoreForHole(playerIndex, holeIndex);
        totalScore += score;
      }
      // String scoresString =
      //     scores.map((score) => score == 0 ? '' : score.toString()).join(', ');

      details.writeln('Player: $playerName');
      details.writeln('Score: $totalScore');
      details.writeln('');
    }

    if (showPutterRow) {
      int totalPutts = 0;
      for (int holeIndex = 0; holeIndex < 18; holeIndex++) {
        totalPutts += await dbHelper.getPuttsForHole(holeIndex);
      }
      details.writeln('Putts: $totalPutts');
      details.writeln('');
    }

    // print(details.toString());
    return details.toString();
  }

  bool isHandicapHole(int index, int handicapDifference) {
    if (mensHandicap) {
      return mensHcap[index] <= handicapDifference.abs();
    } else {
      return womensHcap[index] <= handicapDifference.abs();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // setState(() {
    matchPlayMode = prefs.getBool('matchPlayMode') ?? false;
    showFairwayGreen = prefs.getBool('showFairwayGreen') ?? false;
    showPutterRow = prefs.getBool('showPuttsPerHole') ?? false;
    mensHandicap = prefs.getBool('mensHandicap') ?? false;
    teamMatchPlayMode = prefs.getBool('teamMatchPlayMode') ?? true;
    matchPlayFormat = prefs.getString('matchPlayFormat') ?? 'Four Ball';
    // });
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
    final playerCount = await dbHelper.getPlayerCount();
    if (playerCount < 1) return;

    // if (await dbHelper.getPlayerCount() as int < 2) return;

    int player1Handicap = (await dbHelper.getHandicap(0)) ?? 0;
    int player2Handicap = (await dbHelper.getHandicap(1)) ?? 0;
    int netStrokes = player1Handicap -
        player2Handicap; //if negative, player 2 gets strokes, if positive, player 1 gets strokes
    matchPlayResultsPair1 = List.generate(18, (index) => 0);
    for (int i = 0; i < 18; i++) {
      final player1Score = await dbHelper.getScoreForHole(0, i);
      final player2Score = await dbHelper.getScoreForHole(1, i);
      if (player1Score == 0 || player2Score == 0) {
        matchPlayResultsPair1[i] = 0;
        setState(() {});
        return;
      }

      bool isHandicapHole = false;
      if (mensHandicap) {
        isHandicapHole = mensHcap[i] <= netStrokes.abs();
      } else {
        isHandicapHole = womensHcap[i] <= netStrokes;
      }

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
          if ((player1Score < (player2Score))) {
            //playerindex 0 holeindex i < playerindex 1 holeindex i
            if (i == 0) {
              matchPlayResultsPair1[i] = -1; //negative == player 1 lead
            } else {
              matchPlayResultsPair1[i] = matchPlayResultsPair1[i - 1] - 1;
            }
          } else if (player1Score > (player2Score)) {
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
      if (!hasSeenMatchPlayWinDialog &&
          ((i == 17 && matchPlayResultsPair1[17].abs() >= 1) ||
              (i == 16 && matchPlayResultsPair1[16].abs() >= 2) ||
              (i == 15 && matchPlayResultsPair1[15].abs() >= 3) ||
              (i == 14 && matchPlayResultsPair1[14].abs() >= 4) ||
              (i == 13 && matchPlayResultsPair1[13].abs() >= 5) ||
              (i == 12 && matchPlayResultsPair1[12].abs() >= 6) ||
              (i == 11 && matchPlayResultsPair1[11].abs() >= 7) ||
              (i == 10 && matchPlayResultsPair1[10].abs() >= 8))) {
        hasSeenMatchPlayWinDialog = true;
        if (matchPlayResultsPair1[i] < 0) {
          // Player 1 wins
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
              title: const Text('Player 1 Wins!'),
              content: const Text('Player 1 has won the match play.'),
              actions: <CupertinoDialogAction>[
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        } else if (matchPlayResultsPair1[i] > 0) {
          // Player 2 wins
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
              title: const Text('Player 2 Wins!'),
              content: const Text('Player 2 has won the match play.'),
              actions: <CupertinoDialogAction>[
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        }
      }
    }
    // Trigger a rebuild to display the results
    setState(() {});
  }

  Future<void> _calculateMatchPlay34() async {
    final playerCount = await dbHelper.getPlayerCount();
    if (playerCount < 1) return;

    // if (await dbHelper.getPlayerCount() as int < 2) return;

    int player3Handicap = (await dbHelper.getHandicap(2)) ?? 0;
    int player4Handicap = (await dbHelper.getHandicap(3)) ?? 0;
    int netStrokes = player3Handicap -
        player4Handicap; //if negative, player 2 gets strokes, if positive, player 1 gets strokes
    matchPlayResultsPair2 = List.generate(18, (index) => 0);
    for (int i = 0; i < 18; i++) {
      final player3Score = await dbHelper.getScoreForHole(2, i);
      final player4Score = await dbHelper.getScoreForHole(3, i);
      if (player3Score == 0 || player4Score == 0) {
        matchPlayResultsPair2[i] = 0;
        setState(() {});
        return;
      }

      final isHandicapHole = mensHandicap
          ? mensHcap[i] <= netStrokes.abs()
          : womensHcap[i] <= netStrokes;

      // ignore: unrelated_type_equality_checks
      if (player3Score != 0 && player4Score != 0) {
        if (isHandicapHole) {
          if (netStrokes > 0) {
            //player 1 gets extra stroke
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
          if ((player3Score < (player4Score))) {
            //playerindex 0 holeindex i < playerindex 1 holeindex i
            if (i == 0) {
              matchPlayResultsPair2[i] = -1; //negative == player 1 lead
            } else {
              matchPlayResultsPair2[i] = matchPlayResultsPair2[i - 1] - 1;
            }
          } else if (player3Score > (player4Score)) {
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
      if (!hasSeenMatchPlayWinDialog &&
          ((i == 17 && matchPlayResultsPair2[17].abs() >= 1) ||
              (i == 16 && matchPlayResultsPair2[16].abs() >= 2) ||
              (i == 15 && matchPlayResultsPair2[15].abs() >= 3) ||
              (i == 14 && matchPlayResultsPair2[14].abs() >= 4) ||
              (i == 13 && matchPlayResultsPair2[13].abs() >= 5) ||
              (i == 12 && matchPlayResultsPair2[12].abs() >= 6) ||
              (i == 11 && matchPlayResultsPair2[11].abs() >= 7) ||
              (i == 10 && matchPlayResultsPair2[10].abs() >= 8))) {
        hasSeenMatchPlayWinDialog = true;
        if (matchPlayResultsPair2[i] < 0) {
          // Player 1 wins
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
              title: const Text('Player 3 Wins!'),
              content: const Text('Player 3 has won the match play.'),
              actions: <CupertinoDialogAction>[
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        } else if (matchPlayResultsPair2[i] > 0) {
          // Player 2 wins
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
              title: const Text('Player 4 Wins!'),
              content: const Text('Player 4 has won the match play.'),
              actions: <CupertinoDialogAction>[
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        }
      }
    }
    // Trigger a rebuild to display the results
    setState(() {});
  }

  void _showWinDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
    hasSeenMatchPlayWinDialog = true;
  }

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

    for (int i = 0; i < 18; i++) {
      final player1Score = await dbHelper.getScoreForHole(0, i);
      final player2Score = await dbHelper.getScoreForHole(1, i);
      final player3Score = await dbHelper.getScoreForHole(2, i);
      final player4Score = await dbHelper.getScoreForHole(3, i);

      // Check if any of the scores are missing
      if (player1Score == 0 &&
          player2Score == 0 &&
          player3Score == 0 &&
          player4Score == 0) {
        matchPlayResults[i] = 0;
        continue;
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
      if (!hasSeenMatchPlayWinDialog && i > 8) {
        int team1Wins = matchPlayResults.where((result) => result == -1).length;
        int team2Wins = matchPlayResults.where((result) => result == 1).length;

        if (team1Wins >= 10) {
          _showWinDialog('Team 1 Wins!', 'Team 1 has won the match play.');
          break;
        } else if (team2Wins >= 10) {
          _showWinDialog('Team 2 Wins!', 'Team 2 has won the match play.');
          break;
        }
      }
    }
    // Trigger a rebuild to display the results
    setState(() {});
  }

  Future<void> _calculateTeamMatchPlayAlternateShot() async {
    final playerCount = await dbHelper.getPlayerCount();
    if (playerCount < 4) return;

    int player1Handicap = (await dbHelper.getHandicap(0)) ?? 0;
    int player2Handicap = (await dbHelper.getHandicap(1)) ?? 0;
    int player3Handicap = (await dbHelper.getHandicap(2)) ?? 0;
    int player4Handicap = (await dbHelper.getHandicap(3)) ?? 0;

    // Find the lowest handicap among all players
    int lowestHandicap = [
      player1Handicap,
      player2Handicap,
      player3Handicap,
      player4Handicap
    ].reduce((a, b) => a < b ? a : b);

    // Calculate the strokes each player receives
    int netStrokesPlayer1 = player1Handicap - lowestHandicap;
    int netStrokesPlayer2 = player2Handicap - lowestHandicap;
    int netStrokesPlayer3 = player3Handicap - lowestHandicap;
    int netStrokesPlayer4 = player4Handicap - lowestHandicap;

    matchPlayResults = List.generate(18, (index) => 0);

    for (int i = 0; i < 18; i++) {
      final player1Score = await dbHelper.getScoreForHole(0, i);
      final player2Score = await dbHelper.getScoreForHole(1, i);
      final player3Score = await dbHelper.getScoreForHole(2, i);
      final player4Score = await dbHelper.getScoreForHole(3, i);

      // Check if any of the scores are missing
      if (player1Score == 0 &&
          player2Score == 0 &&
          player3Score == 0 &&
          player4Score == 0) {
        matchPlayResults[i] = 0;
        continue;
      }

      // Determine if the current hole is a handicap hole
      final isHandicapHole = mensHandicap ? mensHcap[i] : womensHcap[i];

      // Calculate the net scores considering the alternate shot format
      final netScoreTeam1 = (i % 2 == 0)
          ? player1Score - (netStrokesPlayer1 >= isHandicapHole ? 1 : 0)
          : player2Score - (netStrokesPlayer2 >= isHandicapHole ? 1 : 0);

      final netScoreTeam2 = (i % 2 == 0)
          ? player3Score - (netStrokesPlayer3 >= isHandicapHole ? 1 : 0)
          : player4Score - (netStrokesPlayer4 >= isHandicapHole ? 1 : 0);

      // Determine the result for the hole
      if (netScoreTeam1 < netScoreTeam2) {
        matchPlayResults[i] = (i == 0) ? -1 : matchPlayResults[i - 1] - 1;
      } else if (netScoreTeam1 > netScoreTeam2) {
        matchPlayResults[i] = (i == 0) ? 1 : matchPlayResults[i - 1] + 1;
      } else {
        matchPlayResults[i] = (i == 0) ? 0 : matchPlayResults[i - 1];
      }

      // Check for early match win
      if (!hasSeenMatchPlayWinDialog && i > 8) {
        int team1Wins = matchPlayResults.where((result) => result < 0).length;
        int team2Wins = matchPlayResults.where((result) => result > 0).length;

        if (team1Wins >= 10) {
          _showWinDialog('Team 1 Wins!', 'Team 1 has won the match play.');
          break;
        } else if (team2Wins >= 10) {
          _showWinDialog('Team 2 Wins!', 'Team 2 has won the match play.');
          break;
        }
      }
    }

    // Trigger a rebuild to display the results
    setState(() {});
  }

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
        if (mensHandicap) {
          return mensHcap[hole] <= handicapDifference;
        } else {
          return womensHcap[hole] <= handicapDifference;
        }
      } else if (playerIndex == 1) {
        // if player 2
        int player1Handicap = await dbHelper.getHandicap(0) ?? 0;
        int player2Handicap = await dbHelper.getHandicap(1) ?? 0;
        int handicapDifference = player2Handicap - player1Handicap;
        if (mensHandicap) {
          return mensHcap[hole] <= handicapDifference;
        } else {
          return womensHcap[hole] <= handicapDifference;
        }
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
    if (mensHandicap) {
      return mensHcap[hole] <= handicapDifference.abs();
    } else {
      return womensHcap[hole] <= handicapDifference.abs();
    }
  }

  void _toggleFairway(int index) {
    setState(() {
      fairwaysHit[index] = fairwaysHit[index] == 0 ? 1 : 0;
      // _saveScores();
    });
  }

  void _toggleGreen(int index) {
    setState(() {
      greensHit[index] = greensHit[index] == 0 ? 1 : 0;
      // _saveScores();
    });
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
        // if (matchPlayFormat == 'Four Ball') {
        await _calculateTeamMatchPlayFourBall();
        // } else if (matchPlayFormat == 'Alternate Shot') {
        //   await _calculateTeamMatchPlayAlternateShot();
        // }
      } else {
        if (playerCount == 2 || playerCount == 3 || playerCount == 4) {
          await _calculateMatchPlay12();
          if (Provider.of<CourseDataProvider>(context).playerCount == 4) {
            await _calculateMatchPlay34();
          }
        }
        // if (Provider.of<CourseDataProvider>(context).playerCount == 4) {
        //   await _calculateMatchPlay34();
        // }
      }
    }
    setState(() {});
  }

  @override
  // ignore: unused_element
  Widget build(BuildContext context) {
    final scaleFactor = Provider.of<ScaleFactorProvider>(context).scaleFactor;
    pars.isEmpty ? _loadCourseData('') : null;
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
                      18,
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
                              // color: Colors.white,
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
                                  return TeamMatchPlayResultsRow(
                                    matchPlayResults: matchPlayResults,
                                    teamNames: [team1Name, team2Name],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                if (teamMatchPlayMode &&
                    matchPlayMode &&
                    Provider.of<CourseDataProvider>(context).playerCount == 4)
                  if (matchPlayFormat == 'Alternate Shot')
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
                                onScoreChanged:
                                    _calculateTeamMatchPlayAlternateShot,
                                playerTeamColor: playerIndex < 2
                                    ? const Color.fromRGBO(255, 139, 139, 1)
                                    : const Color.fromRGBO(171, 178, 255, 1),
                                isStrokeHole: isStrokeHole,
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
                                  return TeamMatchPlayResultsRow(
                                    matchPlayResults: matchPlayResults,
                                    teamNames: [team1Name, team2Name],
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
                                  return MatchPlayResultsRow(
                                    matchPlayResults: matchPlayResultsPair1,
                                    playerNames: [
                                      playerNames[0] ?? 'Player 1',
                                      playerNames[1] ?? 'Player 2'
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
                                  return MatchPlayResultsRow(
                                    matchPlayResults: matchPlayResultsPair2,
                                    playerNames: [
                                      playerNames[0] ?? 'Player 3',
                                      playerNames[1] ?? 'Player 4'
                                    ],
                                  );
                                }
                              },
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
                          if (showFairwayGreen) // Conditionally render the row based on the switch state
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
