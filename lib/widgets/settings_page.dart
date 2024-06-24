import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/scale_factor_provider.dart';
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
    });
  }

  Future<void> _saveSettings(
      bool showFairwayGreenValue,
      bool showPuttsPerHoleValue,
      bool mensHandicapValue,
      bool matchPlayModeValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showFairwayGreen', showFairwayGreenValue);
    await prefs.setBool('showPuttsPerHole', showPuttsPerHoleValue);
    await prefs.setBool('mensHandicap', mensHandicapValue);
    await prefs.setBool('matchPlayMode', matchPlayModeValue);
  }

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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                child: const Text('Match Play Mode',
                    style: TextStyle(fontSize: 20)),
              ),
              CupertinoSwitch(
                value: matchPlayMode,
                onChanged: (bool matchPlayModeValue) {
                  setState(() {
                    matchPlayMode = matchPlayModeValue;
                    _saveSettings(showFairwayGreen, showPuttsPerHole,
                        showMensHandicap, matchPlayModeValue);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
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
                  setState(() {
                    showFairwayGreen = showFairwayGreenValue;
                    _saveSettings(showFairwayGreenValue, showPuttsPerHole,
                        showMensHandicap, matchPlayMode);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
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
                  setState(() {
                    showPuttsPerHole = showPuttsPerHoleValue;
                    _saveSettings(showFairwayGreen, showPuttsPerHoleValue,
                        showMensHandicap, matchPlayMode);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
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
                  setState(() {
                    showMensHandicap = showMensHandicapValue;
                    _saveSettings(showFairwayGreen, showPuttsPerHole,
                        showMensHandicapValue, matchPlayMode);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
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
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
