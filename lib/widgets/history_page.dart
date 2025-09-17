import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../database_helper.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.onSave});

  final Future<void> Function(BuildContext context)? onSave;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _dbHelper.getHistoryEntries();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = _dbHelper.getHistoryEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      appBar: AppBar(
<<<<<<< HEAD
        automaticallyImplyLeading: true,
=======
>>>>>>> fdbfc13d4615d063f229cf0a69c27bfe2df617ee
        title: const Text(
          'History',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 120, 79),
<<<<<<< HEAD
        foregroundColor: Colors.white,
        elevation: 0.5,
=======
>>>>>>> fdbfc13d4615d063f229cf0a69c27bfe2df617ee
        actions: [
          if (widget.onSave != null)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white, size: 28),
              onPressed: () async {
                await widget.onSave!(context);
                await _refreshHistory();
              },
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading history: ${snapshot.error}'));
          }

          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('No history saved yet.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final String course =
                    (entry['course'] as String?) ?? 'Unknown Course';
                final DateTime? date =
                    DateTime.tryParse(entry['datePlayed'] as String? ?? '');
                final String formattedDate = date != null
                    ? '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                    : 'Unknown date';

                BorderRadius? radius;
                if (entries.length == 1) {
                  radius = BorderRadius.circular(18);
                } else if (index == 0) {
                  radius =
                      const BorderRadius.vertical(top: Radius.circular(18));
                } else if (index == entries.length - 1) {
                  radius =
                      const BorderRadius.vertical(bottom: Radius.circular(18));
                }

                return ClipRRect(
                  borderRadius: radius ?? BorderRadius.zero,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      border: index != entries.length - 1
                          ? const Border(
                              bottom: BorderSide(
                                color: CupertinoColors.separator,
                                width: 0.25,
                              ),
                            )
                          : null,
                    ),
                    child: CupertinoListTile(
                      title: Text(
                        course,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      subtitle: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showHistoryDetails(entry),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showHistoryDetails(Map<String, dynamic> entry) {
    final List<dynamic> decodedPlayers =
        jsonDecode(entry['players'] as String? ?? '[]') as List<dynamic>;
    final List<Map<String, dynamic>> players = decodedPlayers
        .map((player) =>
            Map<String, dynamic>.from(player as Map<dynamic, dynamic>))
        .toList();

    showDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            entry['course'] as String? ?? 'Unknown Course',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Date: ${(entry['datePlayed'] as String?) ?? ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 18),
                ),
                const SizedBox(height: 12),
                ...players.map((player) {
                  final String name = (player['name'] as String?) ?? 'Player';
                  final List<dynamic> scoreList =
                      (player['scores'] as List<dynamic>? ?? const []);
                  final scores =
                      scoreList.map((value) => value.toString()).join(', ');
                  final total = player['total'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text('Scores: $scores'),
                        if (total != null)
                          Text(
                            'Score: $total',
                            style: const TextStyle(fontSize: 16),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _dbHelper.deleteHistoryEntry(entry['id'] as int);
                navigator.pop();
                if (!mounted) return;
                await _refreshHistory();
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                    color: CupertinoColors.destructiveRed, fontSize: 20),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                    color: CupertinoColors.inactiveGray, fontSize: 20),
              ),
            ),
          ],
        );
      },
    );
  }
}
