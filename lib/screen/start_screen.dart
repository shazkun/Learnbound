import 'package:flutter/material.dart';
import 'auth_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  minimumSize: Size(screenWidth * 0.10,
                      screenWidth * 0.10), // Adjust size based on screen width
                  padding: EdgeInsets.zero,
                ),
                child:
                    Icon(Icons.arrow_forward, size: 20), // Icon size responsive
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
