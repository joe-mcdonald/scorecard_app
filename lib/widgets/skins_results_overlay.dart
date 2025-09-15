import 'package:flutter/material.dart';

OverlayEntry createSkinsOverlay({
  required Future<List<String>> playerNamesFuture,
  required List<int> skinsWon,
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
                      child: Column(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                playerNames[0],
                                style: const TextStyle(fontSize: 20),
                              ),
                              Text(
                                '\$${skinsWon[0]}',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                playerNames[1],
                                style: const TextStyle(fontSize: 20),
                              ),
                              Text(
                                '\$${skinsWon[1]}',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                          if (playerCount >= 3)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  playerNames[2],
                                  style: const TextStyle(fontSize: 20),
                                ),
                                Text(
                                  '\$${skinsWon[2]}',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                          if (playerCount >= 4)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  playerNames[3],
                                  style: const TextStyle(fontSize: 20),
                                ),
                                Text(
                                  '\$${skinsWon[3]}',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                        ],
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
