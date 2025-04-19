import 'dart:io';

import 'package:Learnbound/database/user_provider.dart';
import 'package:Learnbound/screen/auth/login/login_screen.dart';
import 'package:Learnbound/screen/chat/chat_screen.dart';
import 'package:Learnbound/screen/host/host_screen.dart';
import 'package:Learnbound/screen/quiz/quiz_screen.dart';
import 'package:Learnbound/util/design/wave.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      // PUT LOGOUT-HERE
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double imagePaddingBottom = 20.0;
    const double buttonSpacing = 10.0;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return WillPopScope(
      onWillPop: () async {
        // Return `false` to disable the back button globally
        _logout();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(0xFFD7C19C),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: user?.profilePicture != null &&
                                user!.profilePicture!.isNotEmpty
                            ? Image.file(
                                File(user.profilePicture!),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/defaultprofile.png',
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/defaultprofile.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Text(
                      user!.username,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Profile'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileSettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout'),
                onTap: _logout,
              ),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            bool isPortrait = constraints.maxHeight > constraints.maxWidth;
            double imageSize = isPortrait ? 300 : 250;
            double buttonWidth = isPortrait ? 200.0 : 250.0;

            return Container(
              decoration: BoxDecoration(),
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding:
                                EdgeInsets.only(bottom: imagePaddingBottom),
                            child: Image.asset(
                              'assets/logoonly.png',
                              height: imageSize, // Responsive image size
                              width: imageSize, // Responsive image size
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.error);
                              },
                            ),
                          ),
                          SizedBox(height: buttonSpacing),
                          _buildButton('Host', buttonWidth, () {
                            _createHost(context);
                          }),
                          SizedBox(height: buttonSpacing),
                          _buildButton('Join', buttonWidth, () {
                            _joinChat(context);
                          }),
                          SizedBox(height: buttonSpacing),
                          _buildButton('Quiz-PAD', buttonWidth, () {
                            _joinChatQuiz(context);
                          }),
                          SizedBox(
                            height: 30,
                          ),
                          ClipPath(
                            clipper: BottomWaveClipper(),
                            child: Container(
                              height: screenSize.height * 0.26,
                              width: double.infinity,
                              decoration:
                                  const BoxDecoration(color: Color(0xFFD7C19C)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton(String text, double buttonWidth, VoidCallback onPressed) {
    return SizedBox(
      width: buttonWidth,
      height: 50.0,
      child: Tooltip(
        message: 'Click to $text',
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

  void _joinChatQuiz(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(),
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
