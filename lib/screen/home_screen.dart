import 'package:Learnbound/screen/auth_screen.dart';
import 'package:Learnbound/screen/login_screen.dart';
import 'package:Learnbound/screen/wave/wave.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';
import 'host_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenWidget createState() => _HomeScreenWidget();
}

class _HomeScreenWidget extends State<HomeScreen> {
  void _logout() async {
    // Show a confirmation dialog
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you really want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User pressed Cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User pressed Confirm
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false, // Clears all previous routes
                );
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    // If user confirmed logout, proceed with the logout process
    if (shouldLogout == true) {
      //PUT LOGOUT-HERE
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double imagePaddingBottom = 20.0; // Fixed padding below the image
    const double buttonSpacing = 10.0; // Fixed spacing between buttons

    return WillPopScope(
        onWillPop: () async {
          // Return `false` to disable the back button globally
          _logout();
          return false;
        },
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
             
            ),
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding:
                                EdgeInsets.only(bottom: imagePaddingBottom),
                            child: Image.asset(
                              'assets/logoonly.png',
                              height: 300, // Fixed height for the image
                              width: 300, // Fixed width for the image
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                    Icons.error); // Placeholder for image error
                              },
                            ),
                          ),
                          SizedBox(height: buttonSpacing),
                          _buildButton('Host', () {
                            _createHost(context);
                          }),
                          SizedBox(height: buttonSpacing),
                          _buildButton('Join', () {
                            _joinChat(context);
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 50.0,
                  right: 20.0,
                  child: Material(
                    color:
                        Colors.transparent, // Make the background transparent
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileSettingsScreen(),
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
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipPath(
                    clipper: BottomWaveClipper(),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Color(0xFFD7C19C),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 200.0, // Fixed button width
      height: 50.0, // Fixed button height
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFD3AC70),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(),
      ),
    );
  }

  void _createHost(BuildContext context) async {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HostScreen()));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
