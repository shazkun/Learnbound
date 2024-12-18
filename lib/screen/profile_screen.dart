import 'dart:io'; // Ensure you import this for File usage

import 'package:Learnbound/database/auth_service.dart';
import 'package:Learnbound/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final int? uid;

  const ProfileSettingsScreen({super.key, required this.uid});

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final AuthService _authService = AuthService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String? _profilePicturePath;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<String?> displayUsername() async {
    String? username = await _dbHelper.getUsername(widget.uid ?? 0);
    return username;
  }

  void _loadProfilePicture() async {
    String? profilePicture = await _dbHelper.getProfilePicture(widget.uid ?? 0);
    setState(() {
      _profilePicturePath = profilePicture;
    });
  }

  void _changeProfilePicture() async {
    await _authService.changeProfilePicture(widget.uid ?? 0);
    _loadProfilePicture();
  }

  void _deleteProfilePicture() async {
    await _authService.delProfilePicture(widget.uid ?? 0);
    _loadProfilePicture();
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: InputDecoration(labelText: 'Current Password'),
                obscureText: true,
              ),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  final currentp = await _dbHelper.getPassword(widget.uid ?? 0);

                  if (currentPasswordController.text.isEmpty ||
                      newPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill in all fields.')),
                    );
                    return;
                  }

                  if (currentp == currentPasswordController.text) {
                    if (newPasswordController.text.length >= 6) {
                      if (newPasswordController.text !=
                          currentPasswordController.text) {
                        // Change password
                        await _authService.changePassword(
                          widget.uid ?? 0,
                          currentPasswordController.text,
                          newPasswordController.text,
                        );

                        Navigator.of(context).pop(); // Close the dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Password changed successfully!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'New password must be different from the old password.')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Password must be at least 6 characters long.')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Current password does not match.')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('An error occurred: ${e.runtimeType}')),
                  );
                }
              },
              child: Text('Change'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

void _about(BuildContext context) async {
    List<String> lines = [
    "Developer: Eusebio & Rodriguez",
      "Version: 1.0.0",
      "Framework: Flutter",
      "Language: Dart",
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text("About")),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map((line) => ListTile(
                      // Optional leading icon
                        title: Text(line), // Display the line as plain text
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

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
                  MaterialPageRoute(builder: (context) => AuthScreen()),
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
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen()),
        );
      }
    }
  }

  void _showChangeUsername(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Username'),
          content: TextField(
            maxLength: 12, // Limits the number of characters
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                  12), // Enforces the character limit
            ],

            controller: usernameController,
            decoration: InputDecoration(
              hintText: 'Enter new username',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newUsername = usernameController.text.trim();
                if (newUsername.isNotEmpty && newUsername.length <= 12) {
                  await _dbHelper.changeUsername(widget.uid ?? 0, newUsername);

                  print('Username changed to: $newUsername');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid nickname.')),
                  );
                }
                // Close the dialog
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsiveness
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Profile Settings'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD3A97D).withOpacity(1), // Start color
              Color(0xFFEBE1C8).withOpacity(1), // End color
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth *
                  0.05, // 5% horizontal padding based on screen width
              vertical: screenHeight *
                  0.05, // 5% vertical padding based on screen height
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Background color for the list
                border: Border.all(
                  color: Colors.grey.shade400, // Border color
                  width: 2.0, // Border width
                ),
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
              ),
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 0.0),
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Profile Options'),
                              content: Text(
                                  'Choose an action for your profile picture:'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close the dialog
                                    _changeProfilePicture(); // Change profile picture
                                  },
                                  child: Text('Change Profile'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close the dialog
                                    _deleteProfilePicture(); // Delete profile picture
                                  },
                                  child: Text('Delete Profile'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child: _profilePicturePath != null &&
                                      _profilePicturePath!.isNotEmpty ||
                                  _profilePicturePath == " "
                              ? Image.file(
                                  File(_profilePicturePath!),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
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
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: FutureBuilder<String?>(
                        future:
                            displayUsername(), // Call the displayUsername function
                        builder: (BuildContext context,
                            AsyncSnapshot<String?> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // While waiting for the data, show a loading indicator
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            // If there is an error, show an error message
                            return Text('Error: ${snapshot.error}');
                          } else if (!snapshot.hasData ||
                              snapshot.data == null) {
                            // If there is no data, show a default message
                            return Text('No username available');
                          } else {
                            return Text('${snapshot.data}');
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.lock),
                    title: Text('Change Password'),
                    onTap: () {
                      _showChangePasswordDialog(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Change Username'),
                    onTap: () {
                      _showChangeUsername(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('About'),
                    onTap: () => _about(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
