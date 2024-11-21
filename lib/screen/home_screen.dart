import 'dart:io';

import 'package:Learnbound/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'host_screen.dart';
import 'profile_screen.dart';
import 'testscreen.dart'; // Import the new screen

class HomeScreen extends StatelessWidget {
  final int? uid;
  final DatabaseHelper _dbHelper = DatabaseHelper();
 
  

  HomeScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    // Define constant padding values
    const double imagePaddingBottom = 20.0; // Fixed padding below the image
    const double buttonSpacing = 10.0; // Fixed spacing between buttons
    // const double buttonHeight = 50.0; // Fixed button height

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD3A97D).withOpacity(1), // Start color
              Color(0xFFEBE1C8).withOpacity(1), // End color
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: imagePaddingBottom),
                    child: Image.asset(
                      'assets/applogo.png',
                      height: 300, // Fixed height for the image
                      width: 300, // Fixed width for the image
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error); // Placeholder for image error
                      },
                    ),
                  ),
                  SizedBox(height: buttonSpacing),
                  _buildButton('Host', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HostScreen()),
                    );
                  }),
                  SizedBox(height: buttonSpacing),
                  _buildButton('Join', () {
                    _joinChat(context);

                  }),
                  
                ],
              ),
            ),
            Positioned(
              top: 50.0,
              right: 20.0,
              child: Material(
                color: Colors.transparent, // Make the background transparent
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileSettingsScreen(uid: uid),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.settings,
                    size: 40.0, // Adjust the size as needed
                    color: Colors.black, // Change the icon color
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 200.0, // Fixed button width
      height: 50.0, // Fixed button height
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(50),
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }

  void _joinChat(BuildContext context) async {
    String? profilePicture = await _dbHelper.getUsername(uid ?? 0);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(nickname: profilePicture ?? '', uid: uid,),
      ),
    );
  }

}

