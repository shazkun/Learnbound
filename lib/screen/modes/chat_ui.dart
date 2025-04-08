import 'package:Learnbound/database/user_provider.dart';
import 'package:Learnbound/screen/modes/message_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatUI extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final Animation<double> fadeAnimation;
  final TextEditingController messageController;
  final bool isStarted;
  final Function(String) onSendMessage;
  final VoidCallback onWaitSnackBar;

  const ChatUI({
    super.key,
    required this.messages,
    required this.fadeAnimation,
    required this.messageController,
    required this.isStarted,
    required this.onSendMessage,
    required this.onWaitSnackBar,
  });

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
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () => isStarted
                    ? onSendMessage(messageController.text)
                    : onWaitSnackBar(),
                backgroundColor: Colors.teal[400],
                child: Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
