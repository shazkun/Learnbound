import 'package:Learnbound/database/database_helper.dart';
import 'package:flutter/material.dart';

import 'auth_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  //final DatabaseHelper db = DatabaseHelper();
  @override
  Widget build(BuildContext context) {
    // Get the width and height of the screen
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Centered logo at the top
              Spacer(),
              Center(
                child: Image.asset(
                  'assets/applogo.png', // Path to your logo asset
                  height: screenHeight * 0.3, // Responsive height
                  width: screenWidth * 0.6, // Responsive width
                ),
              ),
              SizedBox(
                  height: screenHeight * 0.05), // Space between logo and button
              ElevatedButton(
                onPressed: () {
                  //db.updateFlagStatus('first_time', 1);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15), // Adjust horizontal padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  'Start Learning!',
                  style: TextStyle(fontSize: 18),
                ),
              ),

              SizedBox(height: screenHeight * 0.02), // Space below button
              Spacer(), // Push content to center vertically
            ],
          ),
        ),
      ),
    );
  }
}
