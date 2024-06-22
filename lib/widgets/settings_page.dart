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
    });
  }

  Future<void> _saveSettings(bool showFairwayGreenValue,
      bool showPuttsPerHoleValue, bool mensHandicapValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showFairwayGreen', showFairwayGreenValue);
    await prefs.setBool('showPuttsPerHole', showPuttsPerHoleValue);
    await prefs.setBool('mensHandicap', mensHandicapValue);
  }

  void _showPopup() {
    final overlay = Overlay.of(context)?.context.findRenderObject();
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

    Overlay.of(context)?.insert(entry);

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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onLongPress: () {
                  _startPopupTimer();
                },
                child: const Text('Show Fairway/Green'),
              ),
              CupertinoSwitch(
                value: showFairwayGreen,
                onChanged: (bool showFairwayGreenValue) {
                  setState(() {
                    showFairwayGreen = showFairwayGreenValue;
                    _saveSettings(showFairwayGreenValue, showPuttsPerHole,
                        showMensHandicap);
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
                child: const Text('Show Putts Per Hole'),
              ),
              CupertinoSwitch(
                value: showPuttsPerHole,
                onChanged: (bool showPuttsPerHoleValue) {
                  setState(() {
                    showPuttsPerHole = showPuttsPerHoleValue;
                    _saveSettings(showFairwayGreen, showPuttsPerHoleValue,
                        showMensHandicap);
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
                child: const Text('Mens Handicap'),
              ),
              CupertinoSwitch(
                value: showMensHandicap,
                activeColor: CupertinoColors.lightBackgroundGray,
                onChanged: (bool showMensHandicapValue) {
                  setState(() {
                    showMensHandicap = showMensHandicapValue;
                    _saveSettings(showFairwayGreen, showPuttsPerHole,
                        showMensHandicapValue);
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
                child: const Text('Text Size'),
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
