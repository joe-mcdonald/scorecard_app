import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool showFairwayGreen = false;
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
      showMensHandicap = prefs.getBool('mensHandicap') ?? true;
    });
  }

  Future<void> _saveSettings(bool showFairwayGreenValue, bool mensHandicapValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showFairwayGreen', showFairwayGreenValue);
    await prefs.setBool('mensHandicap', mensHandicapValue); //men = true, women = false
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
                    _saveSettings(showFairwayGreenValue, showMensHandicap);
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
                activeColor: CupertinoColors.inactiveGray,
                onChanged: (bool showMensHandicapValue) {
                  setState(() {
                    showMensHandicap = showMensHandicapValue;
                    _saveSettings(showFairwayGreen, showMensHandicapValue);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
