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
import 'package:scorecard_app/widgets/home_bottom_bar.dart';
import 'package:scorecard_app/widgets/match_play_press_row.dart';
import 'package:scorecard_app/widgets/match_play_results_row.dart';
import 'package:scorecard_app/widgets/match_play_results_row_9.dart';
import 'package:scorecard_app/widgets/player_row.dart';
import 'package:scorecard_app/widgets/putts_row.dart';
import 'package:scorecard_app/widgets/settings_page.dart';
import 'package:scorecard_app/widgets/skins_row.dart';
import 'package:scorecard_app/widgets/skins_results_overlay.dart';
import 'package:scorecard_app/widgets/team_match_play_results_row.dart';
import 'package:scorecard_app/services/skins_service.dart';
import 'package:scorecard_app/services/round_share_service.dart';
import 'package:scorecard_app/services/match_play_service.dart';
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

  late final SkinsService _skinsService = SkinsService(dbHelper: dbHelper);
  late final RoundShareService _roundShareService =
      RoundShareService(dbHelper: dbHelper);
  late final MatchPlayService _matchPlayService =
      MatchPlayService(dbHelper: dbHelper);

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

      int holeResult;
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
    final report = await _roundShareService.buildRoundSummary(
      course: selectedCourse,
      tee: selectedTee,
      playerCount: playersControllers.length,
    );

    Share.share(report, subject: 'Golf Round Details');
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

    final PairMatchResult result = await _matchPlayService.calculatePairMatch(
      playerAIndex: 0,
      playerBIndex: 1,
      mensHandicap: mensHcap,
    );

    setState(() {
      matchPlayResultsPair1 = result.overall;
      matchPlayResultsPair1Back9 = result.backNine;

      if (presses.isNotEmpty) {
        for (int startHole in pressStartHoles) {
          pressMatchPlayResults[pressStartHoles.indexOf(startHole)] =
              _calculatePressMatchPlay(startHole, false);
        }
      }
    });
  }

  Future<void> _calculateMatchPlay34() async {
    if (matchPlayMode == false && skinsMode == true) {
      await _calculateSkins();
      return;
    }
    final playerCount = await dbHelper.getPlayerCount();
    if (playerCount < 1) return;

    final PairMatchResult result = await _matchPlayService.calculatePairMatch(
      playerAIndex: 2,
      playerBIndex: 3,
      mensHandicap: mensHcap,
    );

    setState(() {
      matchPlayResultsPair2 = result.overall;
      matchPlayResultsPair2Back9 = result.backNine;

      if (presses.isNotEmpty) {
        for (int startHole in pressStartHoles) {
          pressMatchPlayResults[pressStartHoles.indexOf(startHole)] =
              _calculatePressMatchPlay(startHole, false);
        }
      }
    });
  }

  Future<void> _calculateTeamMatchPlayFourBall() async {
    final TeamMatchResult result =
        await _matchPlayService.calculateTeamMatchPlayFourBall(
      mensHandicap: mensHcap,
      womensHandicap: womensHcap,
      useMensHandicap: mensHandicap,
    );

    setState(() {
      matchPlayResults = result.overall;
      matchPlayResultsBack9 = result.backNine;
    });
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
        return mensHcap[hole] <= handicapDifference;
      } else if (playerIndex == 1) {
        // if player 2
        int player1Handicap = await dbHelper.getHandicap(0) ?? 0;
        int player2Handicap = await dbHelper.getHandicap(1) ?? 0;
        int handicapDifference = player2Handicap - player1Handicap;
        return mensHcap[hole] <= handicapDifference;
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
    final int newSkinValue = prefs.getInt('skinValue') ?? skinValue;

    final SkinsResult result = await _skinsService.calculateSkins(
      mensHandicap: mensHcap,
      skinValue: newSkinValue,
    );

    setState(() {
      skinValue = newSkinValue;
      skinsArray = result.skinsArray;
      skinsWon = result.skinsWon;
      skinsWonByHole = result.skinsWonByHole;
    });
  }

  OverlayEntry? _skinsOverlay;

  void _showSkinsOverlay(BuildContext context) {
    final overlay = Overlay.of(context);

    _skinsOverlay = createSkinsOverlay(
      playerNamesFuture: _fetchPlayerNames(),
      skinsWon: skinsWon,
      playerCount: playersControllers.length,
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

  void _confirmReset(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
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
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ],
      ),
    );
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
                                          playerNames: [team1Name, team2Name],
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
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomBar(
        canAddPlayer: playersControllers.length < 4,
        onAddPlayer: _addPlayer,
        skinsMode: skinsMode,
        onShowSkinsOverlay: () => _showSkinsOverlay(context),
        onHideSkinsOverlay: _hideSkinsOverlay,
        onShare: _shareRoundDetails,
        onResetPressed: () => _confirmReset(context),
      ),
    );
  }
}
