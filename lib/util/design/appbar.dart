import 'package:flutter/material.dart';
import 'package:learnbound/util/design/wave.dart';

class AppBarCustom {
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required String title, // Title for the app bar
    required bool enableBackButton,
  }) {
    final screenSize = MediaQuery.of(context).size;

    return PreferredSize(
      preferredSize: Size.fromHeight(
          screenSize.height * 0.15), // Set the height of the app bar
      child: AppBar(
        centerTitle: true,
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        leading: enableBackButton
            ? IconButton(
                icon: Image.asset(
                  'assets/back-arrow.png',
                  height: 24,
                  width: 24,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null, // If backButton is false, leading is set to null
        automaticallyImplyLeading:
            enableBackButton, // Optional, if you don't want a back button
        backgroundColor: Colors
            .transparent, // Make background transparent to show custom design
        elevation: 0, // Removes the default shadow
        flexibleSpace: ClipPath(
          clipper:
              TopClipper(), // Assuming you have a TopClipper defined elsewhere
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFD7C19C), // Background color of the app bar
            ),
          ),
        ),
      ),
    );
  }
}
