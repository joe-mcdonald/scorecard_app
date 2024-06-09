import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scorecard_app/widgets/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<List<TextEditingController>> playersControllers = [];

  bool showFairwayGreen = false;
  List<int> fairwaysHit = List.generate(18, (index) => 0);
  List<int> greensHit = List.generate(18, (index) => 0);
  int _selectedIndex = 0;

  List<int> par = [5, 4, 3, 4, 5, 4, 5, 3, 4, 4, 5, 3, 4, 4, 5, 4, 3, 4];
  List<String> tees = ['Blacks', 'Blues', 'Whites', 'White/Greens', 'Greens', 'Green/Reds', 'Reds', 'Yellows'];
  String selectedTee = 'WhiBtes';

  List<int> score = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  int get frontNineScore => score.sublist(0, 9).reduce((a, b) => a + b);
  int get backNineScore => score.sublist(9, 18).reduce((a, b) => a + b);
  int get frontNinePar => par.sublist(0, 9).reduce((a, b) => a + b);
  int get backNinePar => par.sublist(9, 18).reduce((a, b) => a + b);

  List<FocusNode> focusNodes = List.generate(18, (index) => FocusNode());
  List<TextEditingController> controllers = List.generate(18, (index) => TextEditingController());

  List<int> black = [475, 389, 200, 418, 471, 428, 551, 210, 421, 453, 520, 173, 442, 315, 577, 372, 158, 472];
  int blackFront = 3563;
  int blackBack = 3482;
  int blackTotal = 7045;

  List<int> blue = [457, 376, 180, 410, 463, 364, 529, 192, 390, 425, 485, 169, 420, 307, 550, 368, 150, 437];
  int blueFront = 3361;
  int blueBack = 3311;
  int blueTotal = 6672;

  List<int> white = [452, 368, 168, 403, 451, 324, 516, 181, 362, 410, 460, 157, 403, 299, 531, 330, 141, 388];
  int whiteFront = 3225;
  int whiteBack = 3119;
  int whiteTotal = 6344;

  List<int> whiteGreen = [452, 368, 168, 382, 451, 324, 462, 181, 362, 366, 460, 157, 341, 299, 464, 330, 141, 388];
  int whiteGreenFront = 3150;
  int whiteGreenBack = 2989;
  int whiteGreenTotal = 6139;

  List<int> green = [432, 357, 157, 382, 427, 315, 462, 129, 341, 366, 338, 149, 341, 285, 464, 319, 133, 378];
  int greenFront = 3002;
  int greenBack = 2773;
  int greenTotal = 5775;

  List<int> greenRed = [432, 357, 157, 300, 427, 315, 437, 129, 341, 316, 338, 149, 334, 285, 449, 319, 133, 378];
  int greenRedFront = 2898;
  int greenRedBack = 2711;
  int greenRedTotal = 5609;

  List<int> red = [426, 350, 115, 300, 418, 305, 437, 125, 284, 316, 331, 142, 334, 280, 449, 334, 127, 378];
  int redFront = 2760;
  int redBack = 2671;
  int redTotal = 5431;

  List<int> yellow = [319, 244, 115, 263, 319, 219, 339, 125, 244, 270, 331, 142, 263, 190, 359, 239, 127, 259];
  int yellowFront = 2187;
  int yellowBack = 2189;
  int yellowTotal = 4376;

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => SizedBox(
        height: 300,
        child: CupertinoActionSheet(
          title: const Text('Tees'),
          message: const Text('Select a tee.'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  selectedTee = 'Blacks';
                });
                Navigator.pop(context);
              },
              child: const Text('Blacks'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  selectedTee = 'Blues';
                });
                Navigator.pop(context);
              },
              child: const Text('Blues'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  selectedTee = 'Whites';
                });
                Navigator.pop(context);
              },
              isDefaultAction: true,
              child: const Text('Whites'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  selectedTee = 'White/Greens';
                });
                Navigator.pop(context);
              },
              child: const Text('White/Greens'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  selectedTee = 'Greens';
                });
                Navigator.pop(context);
              },
              child: const Text('Greens'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  selectedTee = 'Green/Reds';
                });
                Navigator.pop(context);
              },
              child: const Text('Green/Reds'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  selectedTee = 'Reds';
                });
                Navigator.pop(context);
              },
              child: const Text('Reds'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  selectedTee = 'Yellows';
                });
                Navigator.pop(context);
              },
              child: const Text('Yellows'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
  }

  @override
  void dispose() {
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('score', jsonEncode(score));
    await prefs.setString('fairwaysHit', jsonEncode(fairwaysHit));
    await prefs.setString('greensHit', jsonEncode(greensHit));
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      score = (jsonDecode(prefs.getString('score') ?? '[]') as List<dynamic>).cast<int>();
      fairwaysHit = (jsonDecode(prefs.getString('fairwaysHit') ?? '[]') as List<dynamic>).cast<int>();
      greensHit = (jsonDecode(prefs.getString('greensHit') ?? '[]') as List<dynamic>).cast<int>();

      // Ensure the lists have the correct length
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showFairwayGreen = prefs.getBool('showFairwayGreen') ?? false;
    });
  }

  void _showSettingsPage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SettingsPage(),
    ).then((_) => _loadSettings()); // Reload settings after closing the modal
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
      selectedTee = 'White';
      score = List.generate(18, (index) => 0);
      fairwaysHit = List.generate(18, (index) => 0);
      greensHit = List.generate(18, (index) => 0);
      for (var controller in controllers) {
        controller.clear();
      }
      _saveScores();
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

  BoxDecoration _getDecoration(int index) {
    int? input = int.tryParse(controllers[index].text);
    if (input == null) return BoxDecoration();

    int difference = input - par[index];
    if (difference <= -2) {
      return BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      );
    } else if (difference == -1) {
      return BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black),
      );
    } else if (difference == 1) {
      return BoxDecoration(
        border: Border.all(color: Colors.black),
      );
    } else if (difference >= 2) {
      return BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      );
    }
    return BoxDecoration(); // Default, no decoration
  }

  Widget _buildTextField(int index) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(10), // Adjust padding as needed
          child: TextField(
            focusNode: focusNodes[index],
            controller: controllers[index],
            onChanged: (text) {
              int? value = int.tryParse(text);
              if (value != null) {
                setState(() {
                  score[index] = value;
                  _saveScores();
                });
              } else {
                setState(() {
                  score[index] = 0;
                  _saveScores();
                });
              }
            },
            decoration: InputDecoration(
              hintText: '${par[index]}',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 30), // Adjust font size as needed
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero, // Remove default padding
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontSize: 30), // Adjust font size as needed
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ShapePainter(par[index], int.tryParse(controllers[index].text)),
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildTextField(int playerIndex, int holeIndex) {
  //   return TextField(
  //     controller: playersControllers[playerIndex][holeIndex],
  //     decoration: InputDecoration(
  //       border: OutlineInputBorder(),
  //       contentPadding: EdgeInsets.all(8),
  //     ),
  //   );
  // }

  void _addPlayer() {
    setState(() {
      playersControllers.add(List.generate(18, (index) => TextEditingController()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 120, 79),
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _onItemTapped(1),
        ),
        title: const Text('Scorecard', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            child: Text(
              selectedTee,
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () => _showActionSheet(context),
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
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(18, (index) {
                          return Container(
                            width: 100,
                            height: 80,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: index == 0 ? const Radius.circular(12) : Radius.zero,
                                topRight: index == 17 ? const Radius.circular(12) : Radius.zero,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 5),
                                  Text(
                                    'Hole ${index + 1}',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                  Text(
                                    'Par ${par[index]}',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  Text(
                                    '${selectedTee == 'Blacks' ? black[index] : selectedTee == 'Blues' ? blue[index] : selectedTee == 'Whites' ? white[index] : selectedTee == 'White/Greens' ? whiteGreen[index] : selectedTee == 'Greens' ? green[index] : selectedTee == 'Green/Reds' ? greenRed[index] : selectedTee == 'Reds' ? red[index] : yellow[index]} yards',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      Row(
                        children: List.generate(
                          18,
                          (index) {
                            return Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: index == 0 ? const Radius.circular(12) : Radius.zero,
                                  bottomRight: index == 17 ? const Radius.circular(12) : Radius.zero,
                                ),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: _buildTextField(index),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (showFairwayGreen) // Conditionally render the row based on the switch state
                        Row(
                          children: List.generate(
                            18,
                            (index) {
                              return Container(
                                width: 100,
                                height: 70,
                                margin: const EdgeInsets.all(2),
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
                                    SizedBox(
                                      height: 35,
                                      child: TextButton(
                                        onPressed: () => _toggleFairway(index),
                                        child: Text(
                                          'Fairway',
                                          style: TextStyle(fontSize: 13, color: fairwaysHit[index] == 1 ? Colors.green : Colors.red),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 35,
                                      child: TextButton(
                                        onPressed: () => _toggleGreen(index),
                                        child: Text(
                                          'Green',
                                          style: TextStyle(fontSize: 13, color: greensHit[index] == 1 ? Colors.green : Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: showFairwayGreen ? 144 - 140 : 214 - 190),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200], // Use the color within BoxDecoration
                    borderRadius: BorderRadius.circular(12), // Add rounded corners
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          children: [
                            // const SizedBox(width: 80),
                            Text(
                              'Front: ${frontNineScore}',
                              style: TextStyle(fontSize: 20),
                            ),
                            // const SizedBox(height: 10),
                            Text(
                              'Back: ${backNineScore}',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Column(
                          children: [
                            if (!score.contains(0))
                              Text(
                                '${(frontNineScore + backNineScore) - (frontNinePar + backNinePar) < 0 ? '-' : '+'}${((frontNineScore + backNineScore) - (frontNinePar + backNinePar)).abs()}',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: (frontNineScore + backNineScore) - (frontNinePar + backNinePar) < 0
                                        ? const Color.fromARGB(255, 0, 120, 79)
                                        : Colors.black),
                              ),
                            Text(
                              'Total: ${frontNineScore + backNineScore}',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: (frontNineScore + backNineScore) - (frontNinePar + backNinePar) < 0
                                      ? const Color.fromARGB(255, 0, 120, 79)
                                      : Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 62.0,
        child: SizedBox(
          child: Row(
            children: <Widget>[
              IconButton(
                  onPressed: () {
                    _addPlayer();
                  },
                  icon: Icon(Icons.add)),

              if (showFairwayGreen)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0), // Padding to push it closer to the left edg
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Fairways Hit: ${_countFairwaysHit()}/15',
                        style: TextStyle(fontSize: 11),
                      ),
                      Text(
                        'Greens Hit: ${_countGreensHit()}/18',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              Spacer(), // Pushes the settings button to the right
              TextButton(
                onPressed: () {
                  _resetValues();
                },
                child: const Text('Reset', style: TextStyle(fontSize: 20, color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final int par;
  final int? score;

  _ShapePainter(this.par, this.score);

  @override
  void paint(Canvas canvas, Size size) {
    if (score == null) return;

    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke // Use stroke to create outlines
      ..strokeWidth = 3.0; // Make circles thicker to match squares

    int difference = score! - par;

    if (difference <= -2) {
      _drawCircles(canvas, size, 2);
    } else if (difference == -1) {
      _drawCircles(canvas, size, 1);
    } else if (difference == 1) {
      _drawSquares(canvas, size, 1);
    } else if (difference >= 2) {
      _drawSquares(canvas, size, 2);
    }
  }

  void _drawCircles(Canvas canvas, Size size, int count) {
    final radius = size.width / 3; // Adjust radius to ensure circles are smaller
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < count; i++) {
      final offset = Offset(
        center.dx + (i - (count - 1) / 2) * radius * 0, // Further reduce the offset to fully overlap circles
        center.dy,
      );
      canvas.drawCircle(
        offset,
        radius - i * 8, // Adjust size to create smaller inner circles
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0, // Ensure thickness matches squares
      );
    }
  }

  void _drawSquares(Canvas canvas, Size size, int count) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Make squares thicker

    for (int i = 0; i < count; i++) {
      final halfSize = size.width / 5 * (1 - 0.3 * i); // smaller size to fit within grid
      canvas.drawRect(
        Rect.fromCenter(center: center, width: halfSize * 3, height: halfSize * 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
