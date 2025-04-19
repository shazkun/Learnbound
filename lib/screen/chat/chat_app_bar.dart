import 'package:Learnbound/models/user.dart';
import 'package:Learnbound/util/design/wave.dart';
import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User? user;
  final Future<bool> Function() onBackPressed;

  const ChatAppBar(
      {super.key, required this.user, required this.onBackPressed});
  @override
  Widget build(BuildContext context) {
    final profilePicture = user?.profilePicture;

    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: ClipPath(
        clipper: TopClipper(),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Image.asset(
              'assets/back-arrow.png',
              height: 24,
              width: 24,
            ),
            onPressed: () async {
              if (await onBackPressed()) Navigator.pop(context);
            },
          ),
          centerTitle: true,
          title: Text(
            "Student",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFD7C19C),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}
