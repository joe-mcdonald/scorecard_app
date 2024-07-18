import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/database_helper.dart';
import 'package:scorecard_app/models/player.dart';
import 'package:scorecard_app/scale_factor_provider.dart';
import 'package:scorecard_app/widgets/course_action_sheet.dart';
import 'package:scorecard_app/widgets/match_play_results_row.dart';
import 'package:scorecard_app/widgets/player_row.dart';
import 'package:scorecard_app/widgets/putts_row.dart';
import 'package:scorecard_app/widgets/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // List<List<TextEditingController>> playersControllers = [
  //   List.generate(18, (index) => TextEditingController()),
  // ];
  late List<List<TextEditingController>> playersControllers;
  // List<List<int>> playersScores = [
  //   List.generate(18, (index) => 0),
  // ];
  late List<List<int>> playersScores;
  // List<List<FocusNode>> playersFocusNodes = [
  //   List.generate(18, (index) => FocusNode()),
  // ];
  late List<List<FocusNode>> playersFocusNodes;
  // List<TextEditingController> nameControllers = [
  //   TextEditingController(),
  // ];
  late List<TextEditingController> nameControllers;
  // List<TextEditingController> hcapControllers = [
  //   TextEditingController(),
  // ];
  late List<TextEditingController> hcapControllers;

  bool isLoading = true;
  bool showFairwayGreen = false;
  bool mensHandicap = true;
  List<int> fairwaysHit = List.generate(18, (index) => 0);
  // late List<int> fairwaysHit;
  List<int> greensHit = List.generate(18, (index) => 0);
  // late List<int> greensHit;
  bool showPutterRow = false;
  bool matchPlayMode = false;
  List<int> puttsScores = List.generate(18, (index) => 0);
  // late List<int> puttsScores;
  final List<TextEditingController> puttsControllers =
      List.generate(18, (index) => TextEditingController());
  // late List<TextEditingController> puttsControllers;
  final List<FocusNode> puttsFocusNodes =
      List.generate(18, (index) => FocusNode());
  // late List<FocusNode> puttsFocusNodes;
  // ignore: unused_field
  int _selectedIndex = 0;
  List<int> matchPlayResults = List.generate(18, (index) => 0);

  String selectedCourse = 'Shaughnessy G&CC';

  List<String> tees = [];
  List<int> mensHcap = [];
  List<int> womensHcap = [];
  String selectedTee = '';
  Map<String, List<int>> yardages = {};
  Map<String, List<int>> pars = {};

  List<int> score = List.generate(18, (index) => 0);
  // late List<int> score;

  List<TextEditingController> controllers =
      List.generate(18, (index) => TextEditingController());
  // late List<TextEditingController> controllers;
  List<FocusNode> focusNodes = List.generate(18, (index) => FocusNode());
  // late List<FocusNode> focusNodes;
  ScrollController scrollController = ScrollController();
  bool hasSeenMatchPlayWinDialog = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // _loadSavedState();
    _fetchPlayers();
    // _resetValues();
    _loadCourseData('shaughnessy').then((_) {
      setState(() {});
    });
    for (int i = 0; i < controllers.length; i++) {
      controllers[i].addListener(() {
        int? value = int.tryParse(controllers[i].text);
        if (value != null) {
          setState(() {
            score[i] = value;
            _saveScores();
          });
        }
      });
    }

    // _loadScores();
    // _loadPutts();
  }

  DatabaseHelper _dbHelper = DatabaseHelper();
  List<Player> _players = [];

  Future<void> _fetchPlayers() async {
    final players = await _dbHelper.getPlayers();
    setState(() {
      _players = players
          .map((map) => Player.fromMap(map as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  void dispose() {
    for (var focusNode in puttsFocusNodes) {
      focusNode.dispose();
    }
    for (var controller in puttsControllers) {
      controller.dispose();
    }
    for (var controller in nameControllers) {
      controller.dispose();
    }
    for (var controller in hcapControllers) {
      controller.dispose();
    }
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCourseData(String course) async {
    final rawData = await rootBundle.loadString('assets/$course - Sheet1.csv');
    List<List<dynamic>> csvData = const CsvToListConverter().convert(rawData);
    setState(() {
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
    });
  }

  Future<void> _saveScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('score', jsonEncode(score));
    await prefs.setString('fairwaysHit', jsonEncode(fairwaysHit));
    await prefs.setString('greensHit', jsonEncode(greensHit));
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPuttsRow', showPutterRow);
    await prefs.setBool('matchPlayMode', matchPlayMode);
    await prefs.setString('puttsScores', jsonEncode(puttsScores));
    await prefs.setString('selectedCourse', selectedCourse);
    await prefs.setString('playerScores', jsonEncode(playersScores));
    await prefs.setString(
        'nameControllers',
        jsonEncode(
            nameControllers.map((controller) => controller.text).toList()));
    await prefs.setString(
        'hcapControllers',
        jsonEncode(
            hcapControllers.map((controller) => controller.text).toList()));
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showPutterRow = prefs.getBool('showPuttsRow') ?? false;
      matchPlayMode = prefs.getBool('matchPlayMode') ?? false;
      if (matchPlayMode && playersScores.length == 2) {
        _calculateMatchPlay();
      }
      puttsScores =
          (jsonDecode(prefs.getString('puttsScores') ?? '[]') as List<dynamic>)
              .cast<int>();
      selectedCourse = prefs.getString('selectedCourse') ?? '';

      playersScores =
          (jsonDecode(prefs.getString('playerScores') ?? '[]') as List<dynamic>)
              .map((e) => (e as List<dynamic>).cast<int>())
              .toList();

      nameControllers = (jsonDecode(prefs.getString('nameControllers') ?? '[]')
              as List<dynamic>)
          .map((name) => TextEditingController(text: name))
          .toList();
      hcapControllers = (jsonDecode(prefs.getString('hcapControllers') ?? '[]')
              as List<dynamic>)
          .map((hcap) => TextEditingController(text: hcap))
          .toList();
    });

    if (playersScores.isEmpty) {
      playersScores = [List.generate(18, (index) => 0)];
    }

    if (nameControllers.isEmpty) {
      nameControllers = [TextEditingController()];
    }

    if (hcapControllers.isEmpty) {
      hcapControllers = [TextEditingController()];
    }

    for (int i = 0; i < playersScores.length; i++) {
      if (playersScores[i].length != 18) {
        playersScores[i] = List.generate(18, (index) => 0);
      }
    }

    playersControllers = playersScores
        .map((scores) => scores
            .map((score) =>
                TextEditingController(text: score != 0 ? score.toString() : ''))
            .toList())
        .toList();
    playersFocusNodes = List.generate(playersScores.length,
        (index) => List.generate(18, (index) => FocusNode()));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      matchPlayMode = prefs.getBool('matchPlayMode') ?? false;
      showFairwayGreen = prefs.getBool('showFairwayGreen') ?? false;
      showPutterRow = prefs.getBool('showPuttsPerHole') ?? false;
      mensHandicap = prefs.getBool('mensHandicap') ?? false;
    });
  }

  void _showSettingsPage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SettingsPage(),
    ).then((_) => _loadSettings());
  }

  void _toggleFairway(int index) {
    setState(() {
      fairwaysHit[index] = fairwaysHit[index] == 0 ? 1 : 0;
      _saveScores();
    });
  }

  void _toggleGreen(int index) {
    setState(() {
      greensHit[index] = greensHit[index] == 0 ? 1 : 0;
      _saveScores();
    });
  }

  void _resetValues() {
    setState(() {
      selectedTee = tees.isNotEmpty ? tees[0] : 'Whites';

      playersScores[0] = List.generate(18, (index) => 0);
      score = List.generate(18, (index) => 0);

      for (var controller in playersControllers[0]) {
        controller.clear();
      }

      fairwaysHit = List.generate(18, (index) => 0);
      greensHit = List.generate(18, (index) => 0);

      nameControllers[0].clear();
      hcapControllers[0].clear();

      matchPlayResults = List.generate(18, (index) => 0);

      playersControllers.removeRange(1, playersControllers.length);
      playersScores.removeRange(1, playersScores.length);
      playersFocusNodes.removeRange(1, playersFocusNodes.length);
      nameControllers.removeRange(1, nameControllers.length);
      hcapControllers.removeRange(1, hcapControllers.length);
      hasSeenMatchPlayWinDialog = false;

      _saveScores();
      _saveState();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _showSettingsPage(context);
      }
    });
  }

  int _countFairwaysHit() {
    return fairwaysHit.where((hit) => hit == 1).length;
  }

  int _countGreensHit() {
    return greensHit.where((hit) => hit == 1).length;
  }

  // void _addPlayer() {
  //   setState(() {
  //     playersControllers
  //         .add(List.generate(18, (index) => TextEditingController()));
  //     playersScores.add(List.generate(18, (index) => 0));
  //     playersFocusNodes.add(List.generate(18, (index) => FocusNode()));
  //     nameControllers.add(TextEditingController());
  //     hcapControllers.add(TextEditingController());
  //   });
  // }

  Future<void> _addPlayer(String name, double handicap) async {
    final newPlayer = Player(
      name: name,
      handicap: handicap,
      score: List.generate(18, (index) => 0),
    );
    final id = await _dbHelper.addPlayer(newPlayer.toMap());
    playersControllers
        .add(List.generate(18, (index) => TextEditingController()));
    playersScores.add(List.generate(18, (index) => 0));
    playersFocusNodes.add(List.generate(18, (index) => FocusNode()));
    nameControllers.add(TextEditingController());
    hcapControllers.add(TextEditingController());
    newPlayer.id = id;
    setState(() {
      _players.add(newPlayer);
    });
  }

  void _removePlayer(int index) {
    setState(() {
      playersControllers.removeAt(index);
      playersScores.removeAt(index);
      playersFocusNodes.removeAt(index);
      nameControllers.removeAt(index);
    });
  }

  Future<void> _calculateMatchPlay() async {
    if (playersScores.length < 2) return;

    int player1Handicap = int.tryParse(hcapControllers[0].text) ?? 0;
    int player2Handicap = int.tryParse(hcapControllers[1].text) ?? 0;
    int netStrokes = player1Handicap -
        player2Handicap; //if negative, player 2 gets strokes, if positive, player 1 gets strokes
    matchPlayResults = List.generate(18, (index) => 0);

    for (int i = 0; i < 18; i++) {
      if (playersScores[0][i] == 0 || playersScores[1][i] == 0) {
        matchPlayResults[i] = 0;
        setState(() {});
        return;
      }
      bool isHandicapHole;
      if (mensHandicap) {
        isHandicapHole = mensHcap[i] <= netStrokes.abs();
      } else {
        isHandicapHole = womensHcap[i] <= netStrokes;
      }

      // ignore: unrelated_type_equality_checks
      if (playersScores[0][i] != '' && playersScores[1][i] != '') {
        if (isHandicapHole) {
          if (netStrokes > 0) {
            //player 1 gets extra stroke
            if ((playersScores[0][i] < playersScores[1][i] + 1)) {
              if (i == 0) {
                matchPlayResults[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResults[i] = matchPlayResults[i - 1] - 1;
              }
            } else if (playersScores[0][i] > playersScores[1][i] + 1) {
              if (i == 0) {
                matchPlayResults[i] = 1; //positive  == player 2 lead
              } else {
                matchPlayResults[i] = matchPlayResults[i - 1] + 1;
              }
            } else {
              if (i == 0) {
                matchPlayResults[i] = 0; //tie == nothing changes
              } else {
                matchPlayResults[i] = matchPlayResults[i - 1];
              }
            }
          } else if (netStrokes < 0) {
            if ((playersScores[0][i] + 1 < playersScores[1][i])) {
              if (i == 0) {
                matchPlayResults[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResults[i] = matchPlayResults[i - 1] - 1;
              }
            } else if (playersScores[0][i] + 1 > playersScores[1][i]) {
              if (i == 0) {
                matchPlayResults[i] = 1; //positive  == player 2 lead
              } else {
                matchPlayResults[i] = matchPlayResults[i - 1] + 1;
              }
            } else {
              if (i == 0) {
                matchPlayResults[i] = 0; //tie == nothing changes
              } else {
                matchPlayResults[i] = matchPlayResults[i - 1];
              }
            }
          }
        } else {
          if ((playersScores[0][i] < playersScores[1][i])) {
            if (i == 0) {
              matchPlayResults[i] = -1; //negative == player 1 lead
            } else {
              matchPlayResults[i] = matchPlayResults[i - 1] - 1;
            }
          } else if (playersScores[0][i] > playersScores[1][i]) {
            if (i == 0) {
              matchPlayResults[i] = 1; //positive  == player 2 lead
            } else {
              matchPlayResults[i] = matchPlayResults[i - 1] + 1;
            }
          } else {
            if (i == 0) {
              matchPlayResults[i] = 0; //tie == nothing changes
            } else {
              matchPlayResults[i] = matchPlayResults[i - 1];
            }
          }
        }
      } else {
        matchPlayResults[i] = 0;
      }
      if (!hasSeenMatchPlayWinDialog &&
          ((i == 17 && matchPlayResults[17].abs() >= 1) ||
              (i == 16 && matchPlayResults[16].abs() >= 2) ||
              (i == 15 && matchPlayResults[15].abs() >= 3) ||
              (i == 14 && matchPlayResults[14].abs() >= 4) ||
              (i == 13 && matchPlayResults[13].abs() >= 5) ||
              (i == 12 && matchPlayResults[12].abs() >= 6) ||
              (i == 11 && matchPlayResults[11].abs() >= 7) ||
              (i == 10 && matchPlayResults[10].abs() >= 8))) {
        hasSeenMatchPlayWinDialog = true;
        if (matchPlayResults[i] < 0) {
          // Player 1 wins
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
              title: Text('${nameControllers[0].text} Wins!'),
              content:
                  Text('${nameControllers[0].text} has won the match play.'),
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
        } else if (matchPlayResults[i] > 0) {
          // Player 2 wins
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
              title: Text('${nameControllers[1].text} Wins!'),
              content:
                  Text('${nameControllers[1].text} has won the match play.'),
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
        // showCupertinoDialog(
        //   context: context,
        //   builder: (BuildContext context) => CupertinoAlertDialog(
        //     title: Text('${nameControllers[0].text} Wins!'),
        //     content:
        //         Text('${nameControllers[0].text}  has won the match play.'),
        //     actions: <CupertinoDialogAction>[
        //       CupertinoDialogAction(
        //         child: const Text('OK'),
        //         onPressed: () {
        //           Navigator.of(context).pop();
        //         },
        //       ),
        //     ],
        //   ),
        // );
      }
    }

    // Trigger a rebuild to display the results
    setState(() {});
  }

  void _shareRoundDetails() {
    String details = _formatRoundDetails();
    Share.share(details, subject: 'Golf Round Details');
  }

  String _formatRoundDetails() {
    StringBuffer details = StringBuffer();

    details.writeln('Golf Round Details:');
    details.writeln('Course: $selectedCourse');
    details.writeln('Tee: $selectedTee');
    details.writeln('');

    for (int playerIndex = 0;
        playerIndex < playersScores.length;
        playerIndex++) {
      details.writeln('Player: ${nameControllers[playerIndex].text}');
      details.writeln('Scores: ${playersScores[playerIndex].join(', ')}');
      details.writeln('');
    }

    if (showPutterRow) {
      details.writeln('Putts: ${puttsScores.join(', ')}');
      details.writeln('');
    }

    return details.toString();
  }

  bool isHandicapHole(int index, int handicapDifference) {
    if (mensHandicap) {
      return mensHcap[index] <= handicapDifference.abs();
    } else {
      return womensHcap[index] <= handicapDifference.abs();
    }
  }

  Future<void> _updatePlayer(Player player) async {
    await _dbHelper.updatePlayer(player);
    setState(() {
      int index = _players.indexWhere((p) => p.id == player.id);
      if (index != -1) {
        _players[index] = player;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = Provider.of<ScaleFactorProvider>(context).scaleFactor;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 120, 79),
          title:
              const Text('Loading...', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 120, 79),
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _onItemTapped(1),
        ),
        title: ElevatedButton(
          onPressed: () {
            showCupertinoModalPopup<void>(
              context: context,
              builder: (BuildContext context) => CourseActionSheet(
                onCourseSelected: (course, tee) {
                  setState(() {
                    selectedCourse = course;
                    selectedTee = tee;
                  });
                },
                onCourseDataLoaded: (loadedPars,
                    loadedMensHcap,
                    loadedWomensHcap,
                    loadedTees,
                    loadedYardages,
                    loadedSelectedTee) {
                  setState(() {
                    pars = loadedPars;
                    mensHcap = loadedMensHcap;
                    womensHcap = loadedWomensHcap;
                    tees = loadedTees;
                    yardages = loadedYardages;
                    selectedTee = loadedSelectedTee;
                    isLoading = false;
                  });
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
                          });
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Container(
          color: const Color.fromRGBO(225, 225, 225, 1),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(), // Add this line
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 20 * scaleFactor),
                        child: Row(
                          children: List.generate(18, (index) {
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
                                              color: Colors.black,
                                              fontSize: 16),
                                        ),
                                      if (mensHandicap == false)
                                        Text(
                                          'HCap: ${womensHcap[index]}',
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 16),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Player rows
                      if (_players.isNotEmpty)
                        ...playersControllers.asMap().entries.map((entry) {
                          int playerIndex = entry.key;
                          List<TextEditingController> controllers = entry.value;
                          List<FocusNode> focusNodes =
                              playersFocusNodes[playerIndex];
                          List<int> scores = playersScores[playerIndex];
                          TextEditingController nameController =
                              nameControllers[playerIndex];
                          TextEditingController hcapController =
                              hcapControllers[playerIndex];
                          if (_players.isEmpty) {
                            _addPlayer('Player ${playersScores.length + 1}', 0);
                          }
                          return PlayerRow(
                            player: _players[playerIndex],
                            index: playerIndex,
                            score: scores,
                            fairwaysHit: fairwaysHit,
                            greensHit: greensHit,
                            par: pars,
                            tee: selectedTee,
                            focusNodes: focusNodes,
                            controllers: controllers,
                            nameController: nameController,
                            hcapController: hcapController,
                            scrollController: scrollController,
                            removePlayer: _removePlayer,
                            onScoreChanged:
                                _calculateMatchPlay, // Add this line
                            matchPlayEnabled: matchPlayMode,
                            coursePars: pars[selectedTee]!.toList(),
                          );
                        }),
                      if (matchPlayMode && playersScores.length == 2)
                        MatchPlayResultsRow(
                          matchPlayResults: matchPlayResults,
                          playerNames: [
                            nameControllers[0].text,
                            nameControllers[1].text
                          ],
                        ),
                      if (showPutterRow)
                        Padding(
                          padding: EdgeInsets.only(left: 0 * scaleFactor),
                          child: PutterRow(
                            // putts: puttsScores.toList(),
                            putts: List.generate(18, (index) => 0),
                            par: pars.values.toList()[0],
                            focusNodes: puttsFocusNodes,
                            controllers: puttsControllers,
                            scrollController: scrollController,
                          ),
                        ),
                      if (showFairwayGreen) // Conditionally render the row based on the switch state
                        Padding(
                          padding: EdgeInsets.only(right: 20.0 * scaleFactor),
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
                                                color: fairwaysHit[index] == 1
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
                SizedBox(height: showFairwayGreen ? 144 - 140 : 214 - 190),
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
              IconButton(
                onPressed: () {
                  _addPlayer('Player ${playersScores.length}', 0);
                },
                icon: Icon(Icons.add),
              ),

              // if (showFairwayGreen)
              Padding(
                padding: const EdgeInsets.only(
                    left: 12.0), // Padding to push it closer to the left edg
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Fairways Hit: ${_countFairwaysHit()}/${pars[selectedTee]?.where((p) => p == 4 || p == 5).length}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      'Greens Hit: ${_countGreensHit()}/18',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
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
