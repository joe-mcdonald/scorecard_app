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
import 'package:scorecard_app/models/player.dart';
import 'package:scorecard_app/widgets/settings_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
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
  List<int> fairwaysHit = List.generate(18, (index) => 0);
  List<int> greensHit = List.generate(18, (index) => 0);
  List<int> score = List.generate(18, (index) => 0);
  List<int> par = [5, 4, 3, 4, 5, 4, 5, 3, 4, 4, 5, 3, 4, 4, 5, 4, 3, 4];
  List<FocusNode> focusNodes = List.generate(18, (index) => FocusNode());

  List<String> tees = [];
  List<int> mensHcap = List.generate(18, (index) => 0);
  List<int> womensHcap = List.generate(18, (index) => 0);
  String selectedTee = '';
  String selectedCourse = '';
  Map<String, List<int>> yardages = {};
  Map<String, List<int>> pars = {};

  bool showFairwayGreen = false;
  bool mensHandicap = true;
  bool showPutterRow = false;
  bool matchPlayMode = false;
  int _selectedIndex = 0;
  ScrollController scrollController = ScrollController();
  bool hasSeenMatchPlayWinDialog = false;

  List<int> matchPlayResults = List.generate(18, (index) => 0);

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _loadCourseData(selectedCourse);
    _loadRecentCourse();
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
      setState(() {
        int maxPlayerIndex = scores
            .map((e) => e['playerIndex'] as int)
            .reduce((a, b) => a > b ? a : b);
        playersControllers.clear();
        for (int i = 0; i <= maxPlayerIndex; i++) {
          playersControllers
              .add(List.generate(18, (index) => TextEditingController()));
        }
      });
    }
  }

  Future<void> _loadCourseData(String course) async {
    Map<String, String?> recentCourseData = await dbHelper.getRecentCourse();
    String recentCourse = recentCourseData['courseName'] ?? '';

    recentCourse = recentCourse.toLowerCase().replaceAll(' ', '');

    final rawData =
        await rootBundle.loadString('assets/$recentCourse - Sheet1.csv');
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
      playersControllers
          .add(List.generate(18, (index) => TextEditingController()));
      dbHelper.insertPlayerDetails(
        playersControllers.length - 1,
        '',
        0,
      );
    });
  }

  void _removePlayer(int index) {
    setState(() {
      playersControllers.removeAt(index);
      dbHelper.deletePlayerScores(index);
      dbHelper.removePlayerDetails(index);
    });
  }

  void _resetValues() {
    setState(() {
      // selectedTee = tees.isNotEmpty ? tees[0] : 'Whites';

      // playersScores[0] = List.generate(18, (index) => 0);
      // score = List.generate(18, (index) => 0);

      // for (var controller in playersControllers[0]) {
      //   controller.clear();
      // }

      // fairwaysHit = List.generate(18, (index) => 0);
      // greensHit = List.generate(18, (index) => 0);

      // nameControllers[0].clear();
      // hcapControllers[0].clear();

      // matchPlayResults = List.generate(18, (index) => 0);

      // playersControllers.removeRange(1, playersControllers.length);
      // playersScores.removeRange(1, playersScores.length);
      // playersFocusNodes.removeRange(1, playersFocusNodes.length);
      // nameControllers.removeRange(1, nameControllers.length);
      // hcapControllers.removeRange(1, hcapControllers.length);
      // hasSeenMatchPlayWinDialog = false;

      // _saveScores();
      // _saveState();
    });
  }

  void _shareRoundDetails() {
    String details = _formatRoundDetails();
    Share.share(details, subject: 'Golf Round Details');
  }

  String _formatRoundDetails() {
    StringBuffer details = StringBuffer();

    // details.writeln('Golf Round Details:');
    // details.writeln('Course: $selectedCourse');
    // details.writeln('Tee: $selectedTee');
    // details.writeln('');

    // for (int playerIndex = 0;
    //     playerIndex < playersScores.length;
    //     playerIndex++) {
    //   details.writeln('Player: ${nameControllers[playerIndex].text}');
    //   details.writeln('Scores: ${playersScores[playerIndex].join(', ')}');
    //   details.writeln('');
    // }

    // if (showPutterRow) {
    //   details.writeln('Putts: ${puttsScores.join(', ')}');
    //   details.writeln('');
    // }

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _showSettingsPage(context);
      }
    });
  }

  Future<void> _calculateMatchPlay() async {
    if (await dbHelper.getPlayerCount() as int < 2) return;
    int player1Handicap = (await dbHelper.getHandicap(0) as int) ?? 0;
    int player2Handicap = (await dbHelper.getHandicap(1) as int) ?? 0;
    int netStrokes = player1Handicap -
        player2Handicap; //if negative, player 2 gets strokes, if positive, player 1 gets strokes
    matchPlayResults = List.generate(18, (index) => 0);
    for (int i = 0; i < 18; i++) {
      if (await dbHelper.getScoreForHole(0, i) as int == 0 ||
          await dbHelper.getScoreForHole(1, i) as int == 0) {
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
      if (await dbHelper.getScoreForHole(0, i) != '' &&
          await dbHelper.getScoreForHole(1, i) != '') {
        if (isHandicapHole) {
          if (netStrokes > 0) {
            //player 1 gets extra stroke
            if ((await dbHelper.getScoreForHole(0, i) as int <
                (await dbHelper.getScoreForHole(1, i) as int) + 1)) {
              //playerindex 0 holeindex i < playerindex 1 holeindex i + 1
              if (i == 0) {
                matchPlayResults[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResults[i] = matchPlayResults[i - 1] - 1;
              }
            } else if (await dbHelper.getScoreForHole(0, i) as int >
                (await dbHelper.getScoreForHole(1, i) as int) + 1) {
              //playerindex 0 holeindex i > playerindex 1 holeindex i + 1
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
            if (((await dbHelper.getScoreForHole(0, i) as int) + 1 <
                (await dbHelper.getScoreForHole(1, i) as int))) {
              //playerindex 0 holeindex i  + 1 < playerindex 1 holeindex i
              if (i == 0) {
                matchPlayResults[i] = -1; //negative == player 1 lead
              } else {
                matchPlayResults[i] = matchPlayResults[i - 1] - 1;
              }
            } else if ((await dbHelper.getScoreForHole(0, i) as int) + 1 >
                (await dbHelper.getScoreForHole(1, i) as int)) {
              //playerindex 0 holeindex i + 1 > playerindex 1 holeindex i
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
          if ((await dbHelper.getScoreForHole(0, i) as int <
              (await dbHelper.getScoreForHole(1, i) as int))) {
            //playerindex 0 holeindex i < playerindex 1 holeindex i
            if (i == 0) {
              matchPlayResults[i] = -1; //negative == player 1 lead
            } else {
              matchPlayResults[i] = matchPlayResults[i - 1] - 1;
            }
          } else if (await dbHelper.getScoreForHole(0, i) as int >
              (await dbHelper.getScoreForHole(1, i) as int)) {
            //playerindex 0 holeindex i > playerindex 1 holeindex i
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
              title: Text('${dbHelper.getPlayerName(0)} Wins!'),
              content:
                  Text('${dbHelper.getPlayerName(0)} has won the match play.'),
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
              title: Text('${dbHelper.getPlayerName(1)} Wins!'),
              content:
                  Text('${dbHelper.getPlayerName(1)} has won the match play.'),
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

  @override
  Widget build(BuildContext context) {
    final scaleFactor = Provider.of<ScaleFactorProvider>(context).scaleFactor;

    // if (isLoading) {
    //   return Scaffold(
    //     appBar: AppBar(
    //       backgroundColor: const Color.fromARGB(255, 0, 120, 79),
    //       title:
    //           const Text('Loading...', style: TextStyle(color: Colors.white)),
    //     ),
    //     body: const Center(child: CircularProgressIndicator()),
    //   );
    // }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 120, 79),
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _onItemTapped(1),
        ),
        title: ElevatedButton(
          onPressed: () async {
            showCupertinoModalPopup<void>(
              context: context,
              builder: (BuildContext context) => CourseActionSheet(
                onCourseSelected: (course, tee) {
                  setState(() {
                    selectedCourse = course;
                    selectedTee = tee;
                    dbHelper.insertRecentCourse(course, tee);
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
                    }),
                  ),
                ),
                const SizedBox(height: 5),
                // Row(
                //   children: List.generate(18, (index) {
                //     return Container(
                //       width: 100,
                //       height: 100,
                //       margin: const EdgeInsets.all(2),
                //       decoration: BoxDecoration(
                //         color: Colors.white,
                //         borderRadius: BorderRadius.only(
                //           topLeft:
                //               index == 0 ? const Radius.circular(12) : Radius.zero,
                //           topRight:
                //               index == 17 ? const Radius.circular(12) : Radius.zero,
                //         ),
                //       ),
                //       child: Center(
                //         child: Text('Hole ${index + 1}'),
                //       ),
                //     );
                //   }),
                // ),
                // Row(
                //   children: List.generate(18, (index) {
                //     return Container(
                //       width: 100,
                //       height: 100,
                //       margin: const EdgeInsets.all(2),
                //       decoration: BoxDecoration(
                //         color: Colors.white,
                //         borderRadius: BorderRadius.only(
                //           topLeft:
                //               index == 0 ? const Radius.circular(12) : Radius.zero,
                //           topRight:
                //               index == 17 ? const Radius.circular(12) : Radius.zero,
                //         ),
                //       ),
                //       child: Center(
                //         child: Text('Par ${par[index]}'),
                //       ),
                //     );
                //   }),
                // ),
                // Row(
                //   children: List.generate(
                //     18,
                //     (index) {
                //       return Container(
                //         width: 100,
                //         height: 100,
                //         margin: const EdgeInsets.all(2),
                //         decoration: BoxDecoration(
                //           color: Colors.white,
                //           borderRadius: BorderRadius.only(
                //             topLeft:
                //                 index == 0 ? const Radius.circular(12) : Radius.zero,
                //             topRight:
                //                 index == 17 ? const Radius.circular(12) : Radius.zero,
                //           ),
                //         ),
                //         child: Center(
                //           child: Text(
                //               'Yard ${index}'), // Replace with actual yardage data
                //         ),
                //       );
                //     },
                //   ),
                // ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        PlayerRow(
                          playerIndex: 0,
                          score: score,
                          fairwaysHit: fairwaysHit,
                          greensHit: greensHit,
                          par: par,
                          tee: selectedTee,
                          nameController: TextEditingController(),
                          hcapController: TextEditingController(),
                          scrollController: scrollController,
                          focusNodes: focusNodes,
                          controllers: playersControllers[0],
                          coursePars: pars[selectedTee]!.toList(),
                          removePlayer: _removePlayer,
                          onScoreChanged: _calculateMatchPlay,
                        ),
                        for (int i = 1; i < playersControllers.length; i++)
                          PlayerRow(
                            playerIndex: i,
                            tee: selectedTee,
                            scrollController: scrollController,
                            score: List.generate(18, (index) => 0),
                            fairwaysHit: List.generate(18, (index) => 0),
                            greensHit: List.generate(18, (index) => 0),
                            par: par,
                            focusNodes:
                                List.generate(18, (index) => FocusNode()),
                            controllers: playersControllers[i],
                            nameController: TextEditingController(),
                            hcapController: TextEditingController(),
                            coursePars: pars[selectedTee]!.toList(),
                            removePlayer: _removePlayer,
                            onScoreChanged: _calculateMatchPlay,
                          ),
                      ],
                    ),
                  ),
                ),
                if (matchPlayMode && dbHelper.getPlayerCount() as int == 2)
                  MatchPlayResultsRow(
                    matchPlayResults: matchPlayResults,
                    playerNames: [
                      dbHelper.getPlayerName(0).toString(),
                      dbHelper.getPlayerName(1).toString()
                    ],
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

  @override
  void dispose() {
    for (var playerControllers in playersControllers) {
      for (var controller in playerControllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}
