import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/home_screen.dart';
import 'package:scorecard_app/scale_factor_provider.dart';
import 'package:scorecard_app/widgets/slide_left_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool showFairwayGreen = false;
  bool showPuttsPerHole = false;
  bool showMensHandicap = true;
  bool matchPlayMode = false;
  bool teamMatchPlayMode = false;
  String matchPlayFormat = '';
  Timer? _popupTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showFairwayGreen = prefs.getBool('showFairwayGreen') ?? false;
      showPuttsPerHole = prefs.getBool('showPuttsPerHole') ?? false;
      showMensHandicap = prefs.getBool('mensHandicap') ?? true;
      matchPlayMode = prefs.getBool('matchPlayMode') ?? false;
      teamMatchPlayMode = prefs.getBool('teamMatchPlayMode') ?? false;
      matchPlayFormat = prefs.getString('matchPlayFormat') ?? '';
    });
  }

  Future<void> _saveFairwayGreen(bool showFairwayGreenValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showFairwayGreen', showFairwayGreenValue);
  }

  Future<void> _saveShowPuttsPerHole(bool showPuttsPerHoleValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPuttsPerHole', showPuttsPerHoleValue);
  }

  Future<void> _saveMensHandicap(bool showMensHandicapValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mensHandicap', showMensHandicapValue);
  }

  Future<void> _saveMatchPlayMode(bool matchPlayModeValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('matchPlayMode', matchPlayModeValue);
  }

  Future<void> _saveTeamMatchPlayMode(bool teamMatchPlayModeValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('teamMatchPlayMode', teamMatchPlayModeValue);
  }

  Future<void> _saveMatchPlayFormat(String matchPlayFormatValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('matchPlayFormat', matchPlayFormatValue);
  }

  // Future<void> _saveSettings(
  // bool showFairwayGreenValue,
  // bool showPuttsPerHoleValue,
  // bool mensHandicapValue,
  // bool matchPlayModeValue,
  // bool teamMatchPlayModeValue,
  // String matchPlayFormatValue,
  // ) async {
  // final prefs = await SharedPreferences.getInstance();
  // await prefs.setBool('showFairwayGreen', showFairwayGreenValue);
  // await prefs.setBool('showPuttsPerHole', showPuttsPerHoleValue);
  // await prefs.setBool('mensHandicap', mensHandicapValue);
  // await prefs.setBool('matchPlayMode', matchPlayModeValue);
  // await prefs.setBool('teamMatchPlayMode', teamMatchPlayModeValue);
  // await prefs.setString('matchPlayFormat', matchPlayFormatValue);
  // }

  void _showPopup() {
    final overlay = Overlay.of(context).context.findRenderObject();
    final overlayBox = overlay as RenderBox;
    final offset = overlayBox.localToGlobal(Offset.zero);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + 300,
        left: offset.dx + 100,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: Colors.black.withOpacity(0.1),
            child: const Text(
              'To Bob, love Joe',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);

    Future.delayed(const Duration(seconds: 1), () {
      entry.remove();
    });
  }

  void _startPopupTimer() {
    _popupTimer?.cancel();
    _popupTimer = Timer(const Duration(seconds: 4), _showPopup);
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactorProvider = Provider.of<ScaleFactorProvider>(context);
    final double scaleFactor = scaleFactorProvider.scaleFactor;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 120, 79),
          automaticallyImplyLeading: false,
          leading: IconButton(
              icon: const Icon(
                CupertinoIcons.chevron_back,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                    SlideLeftRoute(page: const HomeScreen()), (route) => false);
              }),
          title: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        body: CupertinoFormSection.insetGrouped(
          children: [
            CupertinoFormRow(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: const Text('Match Play Mode',
                        style: TextStyle(fontSize: 20)),
                  ),
                  CupertinoSwitch(
                    value: matchPlayMode,
                    onChanged: (bool matchPlayModeValue) {
                      matchPlayMode = matchPlayModeValue;
                      setState(() {
                        _saveMatchPlayMode(matchPlayModeValue);
                      });
                    },
                  ),
                ],
              ),
            ),
            if (matchPlayMode)
              CupertinoFormRow(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      child: const Text('Team Match Play Mode',
                          style: TextStyle(fontSize: 20)),
                    ),
                    CupertinoSwitch(
                      value: teamMatchPlayMode,
                      onChanged: (bool teamMatchPlayModeValue) {
                        teamMatchPlayMode = teamMatchPlayModeValue;
                        setState(() {
                          _saveTeamMatchPlayMode(teamMatchPlayModeValue);
                        });
                      },
                    ),
                  ],
                ),
              ),
            if (matchPlayMode)
              CupertinoFormRow(
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    const SizedBox(width: 19),
                    const Text(
                      'Match Play Format',
                      style: TextStyle(fontSize: 20),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      child: matchPlayFormat.isEmpty
                          ? const Text('    ',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.black))
                          : AutoSizeText(
                              matchPlayFormat,
                              style: const TextStyle(color: Colors.black),
                              maxFontSize: 20,
                            ),
                      onPressed: () => showCupertinoModalPopup<void>(
                        context: context,
                        builder: (BuildContext context) => CupertinoActionSheet(
                          // title: const Text('Title'),
                          // message: const Text('Message'),
                          actions: <CupertinoActionSheetAction>[
                            CupertinoActionSheetAction(
                              // isDefaultAction: true,
                              onPressed: () {
                                matchPlayFormat = 'Four Ball';
                                setState(() {
                                  _saveMatchPlayFormat(matchPlayFormat);
                                });
                                Navigator.pop(context);
                              },
                              child: const Text('Four Ball',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.black)),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                matchPlayFormat = 'Alternate Shot';
                                setState(() {
                                  _saveMatchPlayFormat(matchPlayFormat);
                                });
                                Navigator.pop(context);
                              },
                              child: const Text('Alternate Shot',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.black)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            CupertinoFormRow(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onLongPress: () {
                      _startPopupTimer();
                    },
                    child: const Text(
                      'Show Fairway/Green',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  CupertinoSwitch(
                    value: showFairwayGreen,
                    onChanged: (bool showFairwayGreenValue) {
                      showFairwayGreen = showFairwayGreenValue;
                      setState(() {
                        _saveFairwayGreen(showFairwayGreenValue);
                      });
                    },
                  ),
                ],
              ),
            ),
            CupertinoFormRow(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: const Text(
                      'Show Putts Per Hole',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  CupertinoSwitch(
                    value: showPuttsPerHole,
                    onChanged: (bool showPuttsPerHoleValue) {
                      showPuttsPerHole = showPuttsPerHoleValue;
                      setState(() {
                        _saveShowPuttsPerHole(showPuttsPerHoleValue);
                      });
                    },
                  ),
                ],
              ),
            ),
            CupertinoFormRow(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: const Text(
                      'Mens Handicap',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  CupertinoSwitch(
                    value: showMensHandicap,
                    // activeColor: CupertinoColors.lightBackgroundGray,
                    onChanged: (bool showMensHandicapValue) {
                      showMensHandicapValue = showMensHandicapValue;
                      setState(() {
                        _saveMensHandicap(showMensHandicapValue);
                      });
                    },
                  ),
                ],
              ),
            ),
            CupertinoFormRow(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: const Text(
                      'Text Size',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  CupertinoSlider(
                    value: scaleFactor,
                    min: 0.7,
                    max: 1.19,
                    divisions: 20,
                    onChanged: (value) {
                      scaleFactorProvider.setScaleFactor(value);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
