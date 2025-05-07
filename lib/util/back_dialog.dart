import 'package:flutter/material.dart';

class CustomExitDialog {
  static Future<bool> show(
    BuildContext context, {
    bool usePushReplacement = false,
    Widget? targetPage,
  }) async {
    // Show the dialog
    bool result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text(
              'Exit?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('All progress and links will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    // Perform navigation based on result and usePushReplacement parameter
    if (result) {
      if (usePushReplacement) {
        if (targetPage == null) {
          throw ArgumentError(
              'targetPage is required when usePushReplacement is true');
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      } else {
        Navigator.pop(context);
      }
    }

    return result;
  }
}
