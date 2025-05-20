import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:learnbound/database/user_provider.dart';
import 'package:learnbound/screen/auth/login/login_screen.dart';
import 'package:learnbound/screen/chat/chat_screen.dart';
import 'package:learnbound/screen/host/host_screen.dart';
import 'package:learnbound/screen/log_screen.dart';
import 'package:learnbound/screen/quiz/quiz_main.dart';
import 'package:learnbound/util/design/wave.dart';
import 'package:provider/provider.dart';

import '../util/design/snackbar.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenWidget createState() => _HomeScreenWidget();
}

class _HomeScreenWidget extends State<HomeScreen> {
  @override
  void dispose() {
    super.dispose();
  }

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

  void showAbout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'LearnBound',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version: 1.0.0',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'LearnBound is your smart study companion app to help students learn effectively.',
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
                SizedBox(height: 50),
                Text(
                  'Contact:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'seanwiltonr@gmail.com',
                      style: TextStyle(color: Color(0xFFD7C19C)),
                    ),
                    Text(
                      'rjosepheusebio@gmail.com',
                      style: TextStyle(color: Color(0xFFD7C19C)),
                    ),
                    Text(
                      'rjamesramos@gmail.com',
                      style: TextStyle(color: Color(0xFFD7C19C)),
                    ),
                  ],
                )
              ],
            ),
            actions: []);
      },
    );
  }

  Widget _buildButton(BuildContext context, String text,
      {required VoidCallback onPressed, Widget? icon}) {
    return SizedBox(
      width: 200,
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

  @override
  Widget build(BuildContext context) {
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
        _logout();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
        ),
        drawer: Drawer(
          child: Column(
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFFD7C19C)),
                child: Center(
                  child: CircleAvatar(
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
                leading: Icon(Icons.history),
                title: Text('Logs'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionLogScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout'),
                onTap: _logout,
              ),
              Spacer(),
              Divider(),
              ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                  onTap: () => showAbout()),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: imagePaddingBottom),
                          child: Image.asset(
                            'assets/logoonly.png',
                            height: 300,
                            width: 250,
                          ),
                        ),
                        SizedBox(height: buttonSpacing),
                        _buildButton(
                          context,
                          'Host',
                          icon: const Iconify(Mdi.account_multiple,
                              size: 24, color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HostScreen()),
                            );
                          },
                        ),
                        SizedBox(height: buttonSpacing),
                        _buildButton(
                          context,
                          'Join',
                          icon: const Iconify(Mdi.lan_connect,
                              size: 24, color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChatScreen()),
                            );
                          },
                        ),
                        SizedBox(height: buttonSpacing),
                        _buildButton(
                          context,
                          'Quiz-PAD',
                          icon: const Iconify(Mdi.assignment,
                              size: 24, color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => QuizScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    ClipPath(
                      clipper: BottomClipper(),
                      child: Container(
                        height: constraints.maxHeight * 0.25,
                        width: double.infinity,
                        decoration:
                            const BoxDecoration(color: Color(0xFFD7C19C)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
