import 'dart:io';

import 'package:flutter/material.dart';

import '../questions_dialog.dart';

class PictureUI extends StatelessWidget {
  final Future<void> Function() onPickAndSendImage;
  final String? imagePath;
  final List<Map<String, dynamic>> messages;
  final Animation<double> fadeAnimation;
  final TextEditingController messageController;
  final bool isStarted;
  final VoidCallback onWaitSnackBar;

  final List<String> questions;
  final Map<String, List<String>> multipleChoiceQuestions;
  final Map<String, String?> selectedAnswers;
  final Set<String> confirmedAnswers;
  final Socket? clientSocket;
  final void Function(VoidCallback fn) onStateUpdate;

  const PictureUI({
    super.key,
    required this.onPickAndSendImage,
    required this.imagePath,
    required this.messages,
    required this.fadeAnimation,
    required this.messageController,
    required this.isStarted,
    required this.onWaitSnackBar,
    required this.questions,
    required this.multipleChoiceQuestions,
    required this.selectedAnswers,
    required this.confirmedAnswers,
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
                ? GestureDetector(
                    onTap: () {
                      // Show the image in a full-screen dialog
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: InteractiveViewer(
                              child: Image.file(File(imagePath!)),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius:
                            BorderRadius.circular(20), // Rounded border
                      ),
                      padding: EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20), // Round the image itself
                        child: Image.file(
                          File(imagePath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                : Text(
                    'Please select an image.',
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
                onPressed: onPickAndSendImage,
                backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                child: Icon(Icons.image),
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
