import 'dart:io';

import 'package:learnbound/database/user_provider.dart';
import 'package:learnbound/screen/auth/login/login_screen.dart';
import 'package:learnbound/screen/chat/chat_screen.dart';
import 'package:learnbound/screen/host/host_screen.dart';
import 'package:learnbound/screen/quiz/quiz_screen.dart';
import 'package:learnbound/util/design/wave.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:provider/provider.dart';

import '../util/design/cs_snackbar.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenWidget createState() => _HomeScreenWidget();
}

class _HomeScreenWidget extends State<HomeScreen> {
  void _logout() async {
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log out?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8),
              Divider(thickness: 1),
            ],
          ),
          content: const Text(
            'Do you really want to log out?',
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm logout
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.logout();
      if (!mounted) return;
      CustomSnackBar.show(
        context,
        "You have been logged out.",
        isSuccess: true,
        backgroundColor: Colors.orange,
        icon: Icons.exit_to_app,
        duration: Duration(seconds: 1),
      );
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
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
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Return `false` to disable the back button globally
        _logout();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
        ),
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
                    SizedBox(height: 20),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: user.profilePicture != null &&
                                user.profilePicture!.isNotEmpty
                            ? Image.file(
                                File(user.profilePicture!),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/defaultprofile.png',
                                    width: 100,
                                    height: 100,
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

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // your content here
                        Padding(
                          padding: EdgeInsets.only(bottom: imagePaddingBottom),
                          child: Image.asset(
                            'assets/logoonly.png',
                            height: imageSize,
                            width: imageSize,
                          ),
                        ),
                        SizedBox(height: buttonSpacing),
                        _buildButton('Host', buttonWidth, () {
                          _createHost(context);
                        },
                            icon: const Iconify(Mdi.account_multiple,
                                size: 24, color: Colors.black)),
                        SizedBox(height: buttonSpacing),
                        _buildButton('Join', buttonWidth, () {
                          _joinChat(context);
                        },
                            icon: const Iconify(Mdi.lan_connect,
                                size: 24, color: Colors.black)),
                        SizedBox(height: buttonSpacing),
                        _buildButton('Quiz-PAD', buttonWidth, () {
                          _joinQuiz(context);
                        },
                            icon: const Iconify(Mdi.assignment,
                                size: 24, color: Colors.black)),
                      ],
                    ),
                  ),
                ),

                // Footer
                ClipPath(
                  clipper: BottomWaveClipper(),
                  child: Container(
                    height: screenSize.height * 0.20,
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Color(0xFFD7C19C)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton(
    String text,
    double buttonWidth,
    VoidCallback onPressed, {
    Widget? icon,
  }) {
    return SizedBox(
      width: buttonWidth,
      height: 50.0,
      child: Tooltip(
        message: 'Click to $text',
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD3AC70),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (icon != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: icon,
                ),
              Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
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

  void _joinQuiz(BuildContext context) async {
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
