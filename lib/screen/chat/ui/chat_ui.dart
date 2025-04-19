import 'dart:io';

import 'package:Learnbound/database/user_provider.dart';
import 'package:Learnbound/screen/chat/message_title.dart';
import 'package:Learnbound/screen/chat/questions_dialog.dart';
import 'package:Learnbound/util/design/cs_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatUI extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final Animation<double> fadeAnimation;
  final TextEditingController messageController;
  final bool isStarted;
  final Function(String) onSendMessage;
  final VoidCallback onWaitSnackBar;

  final List<String> questions;
  final Map<String, List<String>> multipleChoiceQuestions;
  final Map<String, String?> selectedAnswers;
  final Set<String> confirmedAnswers;
  final Socket? clientSocket;
  final void Function(VoidCallback fn) onStateUpdate;

  const ChatUI({
    super.key,
    required this.messages,
    required this.fadeAnimation,
    required this.messageController,
    required this.isStarted,
    required this.onSendMessage,
    required this.onWaitSnackBar,
    required this.questions,
    required this.multipleChoiceQuestions,
    required this.selectedAnswers,
    required this.confirmedAnswers,
    required this.clientSocket,
    required this.onStateUpdate,
  });

  void _checkMaxLength(BuildContext context) {
    if (messageController.text.length == 100) {
      // Show SnackBar when maxLength is reached
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum character length reached!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final profilePicture = user?.profilePicture;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final messageData = messages[index];
              return FadeTransition(
                opacity: fadeAnimation,
                child: MessageTile(
                  messageData: messageData,
                  profilePicture: profilePicture,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  maxLength: 100,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Color(0xFF888888)),
                    filled: true,
                    fillColor: Color(0xFFF7F7F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              SizedBox(width: 8),
              FloatingActionButton(
                heroTag: 'send-Student',
                onPressed: () {
                  if (messageController.text.trim().isEmpty) {
                    // Show SnackBar if the message is blank
                    CustomSnackBar.show(context, "Input is empty.",
                        backgroundColor: Colors.orange, icon: Icons.info);
                  } else {
                    // Send the message if it's not blank
                    isStarted
                        ? onSendMessage(messageController.text)
                        : onWaitSnackBar();
                  }
                },
                backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                child: Icon(Icons.send),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                heroTag: 'q-Student',
                onPressed: () => showQuestionsDialog(
                  context: context,
                  questions: questions,
                  multipleChoiceQuestions: multipleChoiceQuestions,
                  selectedAnswers: selectedAnswers,
                  confirmedAnswers: confirmedAnswers,
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
