import 'dart:io';

import 'package:flutter/material.dart';

import '../questions_dialog.dart';

class DrawingUI extends StatelessWidget {
  final VoidCallback onOpenDrawingCanvas;
  final String? imagePath; // Add this to show the drawing
  final List<Map<String, dynamic>> messages;
  final Animation<double> fadeAnimation;
  final TextEditingController messageController;
  final bool isStarted;

  final VoidCallback onWaitSnackBar;
  final Socket? clientSocket;
  final void Function(VoidCallback fn) onStateUpdate;

  const DrawingUI({
    super.key,
    required this.onOpenDrawingCanvas,
    this.imagePath,
    required this.messages,
    required this.fadeAnimation,
    required this.messageController,
    required this.isStarted,
    required this.onWaitSnackBar,
    required this.clientSocket,
    required this.onStateUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: imagePath != null
                ? Image.file(File(imagePath!)) // Show the drawing
                : Text(
                    "Drawing is empty.",
                    style: TextStyle(color: Colors.black),
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: onOpenDrawingCanvas,
                backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                child: Icon(Icons.brush),
              ),
              SizedBox(width: 10), // space between buttons
              FloatingActionButton(
                heroTag: 'q-Student',
                onPressed: () => showQuestionsDialog(
                  context: context,
                  fadeAnimation: fadeAnimation,
                  clientSocket: clientSocket,
                  onStateUpdate: onStateUpdate,
                ),
                backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                child: Icon(Icons.question_answer),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
