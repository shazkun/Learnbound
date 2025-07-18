import 'package:flutter/material.dart';
import 'package:learnbound/models/user.dart';
import 'package:learnbound/util/design/colors.dart';
import 'package:learnbound/util/design/wave.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final User? user;
  final Future<bool> Function()? onBackPressed;
  final bool showBackButton;
  final String titleText;
  final Color titleColor;
  final Color backgroundColor;
  final List<Widget>? actions; // <-- new field

  const AppBarCustom({
    super.key,
    this.user,
    this.onBackPressed,
    this.showBackButton = true,
    this.titleText = "Student",
    this.titleColor = Colors.black,
    this.backgroundColor = AppColors.learnBound,
    this.actions, // <-- include in constructor
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: ClipPath(
        clipper: TopClipper(),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: showBackButton
              ? IconButton(
                  icon: Image.asset(
                    'assets/back-arrow.png',
                    height: 24,
                    width: 24,
                  ),
                  onPressed: () async {
                    if (onBackPressed != null) {
                      final shouldPop = await onBackPressed!();
                      if (shouldPop &&
                          context.mounted &&
                          Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    } else if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                )
              : null,
          centerTitle: true,
          title: Text(
            titleText,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          actions: actions, // <-- inject custom action buttons
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}
