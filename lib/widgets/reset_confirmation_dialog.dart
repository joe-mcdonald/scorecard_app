import 'package:flutter/cupertino.dart';

class ResetConfirmationDialog extends StatelessWidget {
  const ResetConfirmationDialog({
    super.key,
    required this.onConfirm,
  });

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      content: const Text(
        'Are you sure you want to reset the scores?',
        style: TextStyle(fontSize: 18),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          child: const Text(
            'Reset',
            style: TextStyle(
              fontSize: 20,
              color: CupertinoColors.destructiveRed,
            ),
          ),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 20,
              color: CupertinoColors.activeBlue,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> showResetConfirmationDialog(
  BuildContext context,
  VoidCallback onConfirm,
) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (context) => ResetConfirmationDialog(onConfirm: onConfirm),
  );
}
