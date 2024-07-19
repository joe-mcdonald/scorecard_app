import 'package:auto_size_text/auto_size_text.dart';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';
import 'package:scorecard_app/widgets/course_action_sheet.dart';
import 'package:scorecard_app/widgets/player_row.dart';
import 'package:scorecard_app/models/player.dart';
import 'package:scorecard_app/widgets/settings_page.dart';
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
  List<int> fairwaysHit = List.generate(18, (index) => 0);
  List<int> greensHit = List.generate(18, (index) => 0);
  List<int> score = List.generate(18, (index) => 0);
  List<int> par = [5, 4, 3, 4, 5, 4, 5, 3, 4, 4, 5, 3, 4, 4, 5, 4, 3, 4];
  List<FocusNode> focusNodes = List.generate(18, (index) => FocusNode());

  List<String> tees = [];
  List<int> mensHcap = [];
  List<int> womensHcap = [];
  String selectedTee = '';
  String selectedCourse = 'shaughnessy';
  Map<String, List<int>> yardages = {};
  Map<String, List<int>> pars = {};

  bool showFairwayGreen = false;
  bool mensHandicap = true;
  bool showPutterRow = false;
  bool matchPlayMode = false;
  int _selectedIndex = 0;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _loadCourseData(selectedCourse);
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

  void _addPlayer() {
    setState(() {
      playersControllers
          .add(List.generate(18, (index) => TextEditingController()));
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

  // bool isHandicapHole(int index, int handicapDifference) {
  //   if (mensHandicap) {
  //     return mensHcap[index] <= handicapDifference.abs();
  //   } else {
  //     return womensHcap[index] <= handicapDifference.abs();
  //   }
  // }

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
                          scrollController: scrollController,
                          focusNodes: focusNodes,
                          controllers: playersControllers[0],
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
