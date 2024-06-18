import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';
import 'package:scorecard_app/widgets/course_action_sheet.dart';
import 'package:scorecard_app/widgets/player_row.dart';
import 'package:scorecard_app/widgets/putts_row.dart';
import 'package:scorecard_app/widgets/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ScrollController scrollController = ScrollController();
  final List<List<TextEditingController>> playersControllers = [
    List.generate(18, (index) => TextEditingController()),
  ];
  List<List<int>> playersScores = [
    List.generate(18, (index) => 0),
  ];
  final List<List<FocusNode>> playersFocusNodes = [
    List.generate(18, (index) => FocusNode()),
  ];
  List<TextEditingController> nameControllers = [
    TextEditingController(),
  ];

  final List<TextEditingController> puttsControllers = List.generate(18, (index) => TextEditingController());
  List<int> puttsScores = List.generate(18, (index) => 0);
  final List<FocusNode> puttsFocusNodes = List.generate(18, (index) => FocusNode());

  bool isLoading = true;
  bool showFairwayGreen = false;
  bool showPutterRow = false;
  bool mensHandicap = true;

  List<int> fairwaysHit = List.generate(18, (index) => 0);
  List<int> greensHit = List.generate(18, (index) => 0);
  int _selectedIndex = 0;

  String selectedCourse = 'Shaughnessy G&CC';

  List<int> par = [];
  List<String> tees = [];
  List<int> mensHcap = [];
  List<int> womensHcap = [];
  String selectedTee = '';
  Map<String, List<int>> yardages = {};

  List<int> score = List.generate(18, (index) => 0);

  int get frontNineScore => score.sublist(0, 9).reduce((a, b) => a + b);
  int get backNineScore => score.sublist(9, 18).reduce((a, b) => a + b);
  int get frontNinePar => par.sublist(0, 9).reduce((a, b) => a + b);
  int get backNinePar => par.sublist(9, 18).reduce((a, b) => a + b);

  List<TextEditingController> controllers = List.generate(18, (index) => TextEditingController());
  List<FocusNode> focusNodes = List.generate(18, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
    _loadScores();
    _loadPutts();
    _loadSavedState();
  }

  @override
  void dispose() {
    _saveState();
    // for (var focusNode in focusNodes) {
    //   focusNode.dispose();
    // }
    // for (var controller in controllers) {
    //   controller.dispose();
    // }
    for (var focusNode in puttsFocusNodes) {
      focusNode.dispose();
    }
    for (var controller in puttsControllers) {
      controller.dispose();
    }
    for (var controller in nameControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadCourseData(String course) async {
    final rawData = await rootBundle.loadString('assets/$course.csv');
    List<List<dynamic>> csvData = const CsvToListConverter().convert(rawData);
    setState(() {
      par = csvData[2].sublist(1).map((e) => e as int).toList();
      mensHcap = csvData[3].sublist(1).map((e) => e as int).toList();
      womensHcap = csvData[4].sublist(1).map((e) => e as int).toList();
      tees = csvData.map((row) => row[0].toString()).skip(5).toList();
      for (var row in csvData.skip(5)) {
        String teeName = row[0];
        List<int> yardage = row.sublist(1).map((e) => e as int).toList();
        yardages[teeName] = yardage;
      }
      selectedTee = tees[0];
      isLoading = false;
    });
  }

  void _onCourseDataLoaded(List<int> loadedPar, List<int> loadedMensHcap, List<int> loadedWomensHcap, List<String> loadedTees,
      Map<String, List<int>> loadedYardages, String loadedSelectedTee) {
    setState(() {
      par = loadedPar;
      mensHcap = loadedMensHcap;
      womensHcap = loadedWomensHcap;
      tees = loadedTees;
      yardages = loadedYardages;
      selectedTee = loadedSelectedTee;
      isLoading = false;
    });
  }

  Future<void> _saveScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('score', jsonEncode(score));
    await prefs.setString('fairwaysHit', jsonEncode(fairwaysHit));
    await prefs.setString('greensHit', jsonEncode(greensHit));
  }

  Future<void> _savePutts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('puttsScores', jsonEncode(puttsScores));
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      score = (jsonDecode(prefs.getString('score') ?? '[]') as List<dynamic>).cast<int>();
      fairwaysHit = (jsonDecode(prefs.getString('fairwaysHit') ?? '[]') as List<dynamic>).cast<int>();
      greensHit = (jsonDecode(prefs.getString('greensHit') ?? '[]') as List<dynamic>).cast<int>();

      if (score.length != 18) {
        score = List.generate(18, (index) => 0);
      }
      if (fairwaysHit.length != 18) {
        fairwaysHit = List.generate(18, (index) => 0);
      }
      if (greensHit.length != 18) {
        greensHit = List.generate(18, (index) => 0);
      }

      for (int i = 0; i < controllers.length; i++) {
        controllers[i].text = score[i] != 0 ? score[i].toString() : '';
      }
    });
  }

  Future<void> _loadPutts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      puttsScores = (jsonDecode(prefs.getString('puttsScores') ?? '[]') as List<dynamic>).cast<int>();

      if (puttsScores.isEmpty) {
        puttsScores = List.generate(18, (index) => 0);
      }
      for (int i = 0; i < puttsControllers.length; i++) {
        puttsControllers[i].text = puttsScores[i] != 0 ? puttsScores[i].toString() : '';
      }
    });
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showPutterRow = prefs.getBool('showPuttsRow') ?? false;
      puttsScores = (jsonDecode(prefs.getString('puttsScore') ?? '[]') as List<dynamic>).cast<int>();

      selectedCourse = prefs.getString('selectedCourse') ?? '';

      playersScores = (jsonDecode(prefs.getString('playerScores') ?? '[]') as List<dynamic>).map((e) => (e as List<dynamic>).cast<int>()).toList();

      nameControllers =
          (jsonDecode(prefs.getString('nameControllers') ?? '[]') as List<dynamic>).map((name) => TextEditingController(text: name)).toList();
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPuttsRow', showPutterRow);
    await prefs.setString('puttsScore', jsonEncode(puttsScores));
    await prefs.setString('selectedCourse', selectedCourse);
    await prefs.setString('playerScores', jsonEncode(playersScores));
    await prefs.setString('nameControllers', jsonEncode(nameControllers.map((controller) => controller.text).toList()));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
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

  void _togglePutterRow() {
    setState(() {
      showPutterRow = !showPutterRow;
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
      playersControllers.removeRange(1, playersControllers.length);
      playersScores.removeRange(1, playersScores.length);
      playersFocusNodes.removeRange(1, playersFocusNodes.length);
      nameControllers.removeRange(1, nameControllers.length);

      puttsScores = List.generate(18, (index) => 0);
      showPutterRow = false;
      for (var controller in puttsControllers) {
        controller.clear();
      }

      _saveScores();
      _savePutts();
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

  void _addPlayer() {
    setState(() {
      playersControllers.add(List.generate(18, (index) => TextEditingController()));
      playersScores.add(List.generate(18, (index) => 0));
      playersFocusNodes.add(List.generate(18, (index) => FocusNode()));
      nameControllers.add(TextEditingController());
    });
  }

  void _addPutter() {
    setState(() {
      showPutterRow = true;
      _loadPutts();
    });
  }

  void _showTeesActionSheet(BuildContext context, double scaleFactor) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => SizedBox(
        height: 300,
        child: CupertinoActionSheet(
          title: Text('Tees', style: TextStyle(fontSize: 15 * scaleFactor)),
          message: Text(
            'Select a tee.',
            style: TextStyle(fontSize: 12 * scaleFactor),
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
                style: TextStyle(fontSize: 15 * scaleFactor),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = Provider.of<ScaleFactorProvider>(context).scaleFactor;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 120, 79),
          title: const Text('Loading...', style: TextStyle(color: Colors.white)),
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
        title: TextButton(
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
                onCourseDataLoaded: _onCourseDataLoaded,
                par: par,
                mensHcap: mensHcap,
                womensHcap: womensHcap,
                tees: tees,
                yardages: yardages,
                selectedTee: selectedTee,
                isLoading: isLoading,
              ),
            );
          },
          child: Text(
            selectedCourse,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              selectedTee,
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            onPressed: () {
              _showTeesActionSheet(context, scaleFactor);
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
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: index == 0 ? const Radius.circular(12) : Radius.zero,
                                    topRight: index == 17 ? const Radius.circular(12) : Radius.zero,
                                    bottomLeft: index == 0 ? const Radius.circular(12) : Radius.zero,
                                    bottomRight: index == 17 ? const Radius.circular(12) : Radius.zero,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 5),
                                      Text(
                                        'Hole ${index + 1}',
                                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20 * scaleFactor),
                                      ),
                                      Text(
                                        'Par ${par[index]}',
                                        style: TextStyle(color: Colors.black, fontSize: 14 * scaleFactor),
                                      ),
                                      Text(
                                        '${yardages[selectedTee]?[index] ?? 0} yards',
                                        style: TextStyle(color: Colors.black, fontSize: 14 * scaleFactor),
                                      ),
                                      if (mensHandicap == true)
                                        Text(
                                          'HCap: ${mensHcap[index]}',
                                          style: TextStyle(color: Colors.black, fontSize: 14 * scaleFactor),
                                        ),
                                      if (mensHandicap == false)
                                        Text(
                                          'HCap: ${womensHcap[index]}',
                                          style: TextStyle(color: Colors.black, fontSize: 14 * scaleFactor),
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
                      ...playersScores.asMap().entries.map((entry) {
                        int index = entry.key;
                        List<int> playerScore = entry.value;
                        return PlayerRow(
                          score: score,
                          fairwaysHit: fairwaysHit,
                          greensHit: greensHit,
                          par: par,
                          focusNodes: focusNodes,
                          controllers: controllers,
                          nameController: nameControllers[index],
                          scrollController: scrollController,
                        );
                      }).toList(),
                      // ...playersControllers.asMap().entries.map((entry) {
                      //   int playerIndex = entry.key;
                      //   List<TextEditingController> controllers = entry.value;
                      //   List<FocusNode> focusNodes = playersFocusNodes[playerIndex];
                      //   List<int> scores = playersScores[playerIndex];
                      //   TextEditingController nameController = nameControllers[playerIndex];
                      //   return PlayerRow(
                      //     score: scores,
                      //     fairwaysHit: fairwaysHit,
                      //     greensHit: greensHit,
                      //     par: par,
                      //     focusNodes: focusNodes,
                      //     controllers: controllers,
                      //     nameController: nameController,
                      //     // nameController: TextEditingController(),
                      //     scrollController: scrollController,
                      //   );
                      // }),
                      if (showPutterRow)
                        Padding(
                          padding: EdgeInsets.only(left: 0 * scaleFactor),
                          child: PutterRow(
                            putts: puttsScores,
                            par: par,
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
                                      topLeft: index == 0 ? const Radius.circular(12) : Radius.zero,
                                      topRight: index == 17 ? const Radius.circular(12) : Radius.zero,
                                      bottomLeft: index == 0 ? const Radius.circular(12) : Radius.zero,
                                      bottomRight: index == 17 ? const Radius.circular(12) : Radius.zero,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      if (par[index] == 4 || par[index] == 5)
                                        SizedBox(
                                          height: 35 * scaleFactor,
                                          child: TextButton(
                                            onPressed: () => _toggleFairway(index),
                                            child: Text(
                                              'Fairway',
                                              style: TextStyle(
                                                fontSize: 13 * scaleFactor,
                                                color: fairwaysHit[index] == 1 ? Colors.green : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (par[index] == 4 || par[index] == 5)
                                        SizedBox(
                                          height: 35 * scaleFactor,
                                          child: TextButton(
                                            onPressed: () => _toggleGreen(index),
                                            child: Text(
                                              'Green',
                                              style: TextStyle(
                                                fontSize: 13 * scaleFactor,
                                                color: greensHit[index] == 1 ? Colors.green : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (par[index] == 3)
                                        SizedBox(
                                          height: 70 * scaleFactor,
                                          child: TextButton(
                                            onPressed: () => _toggleGreen(index),
                                            child: Text(
                                              'Green',
                                              style: TextStyle(
                                                fontSize: 13 * scaleFactor,
                                                color: greensHit[index] == 1 ? Colors.green : Colors.red,
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
        height: 62.0 * scaleFactor,
        child: SizedBox(
          height: 62 * scaleFactor,
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  _addPlayer();
                },
                // onLongPress: () {
                //   showCupertinoModalPopup(
                //     context: context,
                //     builder: (BuildContext context) => CupertinoActionSheet(
                //       title: Text(
                //         'Add Player or Putt Counter',
                //         style: TextStyle(fontSize: 18),
                //       ),
                //       message: const Text('Choose an option.'),
                //       actions: [
                //         CupertinoActionSheetAction(
                //           onPressed: () {
                //             _addPlayer();
                //             Navigator.pop(context);
                //           },
                //           child: const Text('Add Player'),
                //         ),
                //         CupertinoActionSheetAction(
                //           onPressed: () {
                //             _addPutter();
                //             // _togglePutterRow();
                //             Navigator.pop(context);
                //           },
                //           child: const Text('Add Putt Counter'),
                //         ),
                //       ],
                //       cancelButton: CupertinoActionSheetAction(
                //         onPressed: () {
                //           Navigator.pop(context);
                //         },
                //         child: const Text('Cancel'),
                //       ),
                //     ),
                //   );
                // },
                child: const Row(
                  children: [
                    SizedBox(width: 8),
                    Icon(Icons.add),
                  ],
                ),
              ),

              if (showFairwayGreen)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0), // Padding to push it closer to the left edg
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Fairways Hit: ${_countFairwaysHit()}/${par.where((p) => p == 4 || p == 5).length}',
                        style: TextStyle(fontSize: 11 * scaleFactor),
                      ),
                      Text(
                        'Greens Hit: ${_countGreensHit()}/18',
                        style: TextStyle(fontSize: 11 * scaleFactor),
                      ),
                    ],
                  ),
                ),
              const Spacer(), // Pushes the settings button to the right
              TextButton(
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (BuildContext context) => CupertinoAlertDialog(
                      // title: Text(
                      //   'Reset',
                      //   style: TextStyle(fontSize: 20 * scaleFactor),
                      // ),
                      content: Text(
                        'Are you sure you want to reset the scores?',
                        style: TextStyle(fontSize: 18 * scaleFactor),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () {
                            _resetValues();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 20 * scaleFactor,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        CupertinoDialogAction(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 20 * scaleFactor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 20 * scaleFactor,
                    color: Colors.red,
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
