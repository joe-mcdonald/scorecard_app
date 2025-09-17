import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({
    super.key,
    required this.canAddPlayer,
    required this.onAddPlayer,
    required this.skinsMode,
    required this.onShowSkinsOverlay,
    required this.onHideSkinsOverlay,
    required this.onShare,
    required this.onResetPressed,
    required this.onHistoryPressed,
  });

  final bool canAddPlayer;
  final VoidCallback onAddPlayer;
  final bool skinsMode;
  final VoidCallback onShowSkinsOverlay;
  final VoidCallback onHideSkinsOverlay;
  final VoidCallback onShare;
  final VoidCallback onResetPressed;
  final VoidCallback onHistoryPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 12,
            height: 80,
            color: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onHistoryPressed,
                    icon: const Icon(Icons.history),
                  ),
                  if (skinsMode) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onLongPress: onShowSkinsOverlay,
                      onLongPressUp: onHideSkinsOverlay,
                      child: Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Skins\nResults',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (canAddPlayer) const SizedBox(width: 72),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onShare,
                        color: CupertinoColors.activeBlue,
                        iconSize: 24,
                        icon: const Icon(
                          CupertinoIcons.share_up,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                      TextButton(
                        onPressed: onResetPressed,
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
                ],
              ),
            ),
          ),
          if (canAddPlayer)
            Positioned(
              top: -18,
              child: FloatingActionButton(
                onPressed: onAddPlayer,
                heroTag: 'addPlayerFab',
                elevation: 6,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                child: const Icon(Icons.add),
              ),
            ),
        ],
      ),
    );
  }
}
