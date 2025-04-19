import 'dart:io';

import 'package:flutter/material.dart';

class MessageTile extends StatelessWidget {
  final Map<String, dynamic> messageData;
  final String? profilePicture;

  const MessageTile(
      {super.key, required this.messageData, required this.profilePicture});

  @override
  Widget build(BuildContext context) {
    bool isSystemMessage = messageData['system'] ?? false;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isSystemMessage
              ? Icon(Icons.info, color: Colors.blueGrey[800])
              : profilePicture != null && profilePicture!.isNotEmpty
                  ? CircleAvatar(
                      backgroundImage: FileImage(File(profilePicture!)))
                  : CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Image.asset(
                        'assets/defaultprofile.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (messageData['isImage'] == true &&
                    messageData['image'] != null)
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(messageData['image'],
                              fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(messageData['image'],
                          width: 100, height: 100, fit: BoxFit.cover),
                    ),
                  )
                else
                  Text(
                    messageData['text'] ?? '',
                    style: TextStyle(
                        color: isSystemMessage
                            ? Colors.blueGrey[800]
                            : Colors.black),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
