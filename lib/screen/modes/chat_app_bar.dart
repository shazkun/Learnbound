import 'dart:io';
import 'package:Learnbound/database/user_provider.dart';
import 'package:Learnbound/models/user.dart';
import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User? user;
  final Future<bool> Function() onBackPressed;

  const ChatAppBar({required this.user, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    final profilePicture = user?.profilePicture;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () async {
          if (await onBackPressed()) Navigator.pop(context);
        },
      ),
      title: Row(
        children: [
          profilePicture != null && profilePicture.isNotEmpty
              ? CircleAvatar(backgroundImage: FileImage(File(profilePicture)))
              : CircleAvatar(
                  child: Icon(Icons.account_circle, color: Colors.white)),
          SizedBox(width: 12),
          Text(
            user!.username,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
