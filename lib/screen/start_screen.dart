import 'package:flutter/material.dart';
import 'auth_screen.dart';

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Centered logo at the top
            Spacer(),
            Center(
              child: Image.asset(
                'assets/applogo.png', // Path to your logo asset
                height: 500,
                width: 500,
              ),
            ),
            SizedBox(height: 40), // Space between logo and fields
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                minimumSize: Size(60, 60), // adjust size as needed
                padding: EdgeInsets.zero,
              ),
              child: Icon(Icons.arrow_forward), // or any other icon
            ),
            SizedBox(height: 16),

            Spacer(), // Push content to center vertically
          ],
        ),
      ),
    ));
  }
}
