import 'package:flutter/material.dart';

class CustomSnackBar {
  static bool _isShowing = false; // <-- ADD THIS

  static void show(
    BuildContext context,
    String message, {
    bool isSuccess = true,
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (_isShowing) return; // <-- PREVENT SPAMMING

    _isShowing = true; // <-- SET TO TRUE

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            icon ?? (isSuccess ? Icons.check_circle : Icons.error),
            color: iconColor ?? Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor ??
          (isSuccess ? Colors.green.shade600 : Colors.red.shade600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      duration: duration,
      elevation: 6,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {
      _isShowing = false; // <-- RESET AFTER SNACKBAR IS CLOSED
    });
  }
}
