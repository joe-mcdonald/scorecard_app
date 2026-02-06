import 'package:flutter/material.dart';

OverlayEntry createSkinsOverlay({
  required Future<List<String>> playerNamesFuture,
  required List<int> skinsWonCount,
  required int playerCount,
}) {
  return OverlayEntry(
    builder: (context) => FutureBuilder<List<String>>(
      future: playerNamesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final playerNames = snapshot.data ?? [];
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                ),
              ),
              Center(
                child: SizedBox(
                  width: 300,
                  child: Material(
                    color: Colors.white,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _SkinsResultsContent(
                        playerNames: playerNames,
                        skinsWonCount: skinsWonCount,
                        playerCount: playerCount,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    ),
  );
}

class _SkinsResultsContent extends StatelessWidget {
  const _SkinsResultsContent({
    required this.playerNames,
    required this.skinsWonCount,
    required this.playerCount,
  });

  final List<String> playerNames;
  final List<int> skinsWonCount;
  final int playerCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Skins Results',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        for (int index = 0; index < playerCount; index++) ...[
          if (index != 0) const SizedBox(height: 8),
          _SkinsResultRow(
            name: _playerName(index),
            count: index < skinsWonCount.length ? skinsWonCount[index] : 0,
          ),
        ],
      ],
    );
  }

  String _playerName(int index) {
    if (index < playerNames.length && playerNames[index].isNotEmpty) {
      return playerNames[index];
    }
    return 'Player ${index + 1}';
  }
}

class _SkinsResultRow extends StatelessWidget {
  const _SkinsResultRow({
    required this.name,
    required this.count,
  });

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 20),
        ),
        Text(
          '$count',
          style: const TextStyle(fontSize: 20),
        ),
      ],
    );
  }
}
