import 'package:Learnbound/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:Learnbound/database/auth_service.dart';
import 'auth_screen.dart'; // Import your AuthScreen here
import 'dart:io'; // Ensure you import this for File usage

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    }
  }
  void _showChangeUsername(BuildContext context)  {
  final TextEditingController usernameController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Change Username'),
        content: TextField(
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
              if (newUsername.isNotEmpty) {
                await _dbHelper.changeUsername(widget.uid??0,newUsername );
                print('Username changed to: $newUsername');
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
    return Scaffold(
      appBar: AppBar(
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
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: 15.0), // Adjust the padding as needed
              child: GestureDetector(
                onTap: _changeProfilePicture,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[
                      200], // Optional: Add a background color for when there’s no image
                  child: ClipOval(
                    child: _profilePicturePath != null
                        ? Image.file(
                            File(_profilePicturePath!),
                            width: 100, // Diameter of the CircleAvatar
                            height: 100,
                            fit: BoxFit
                                .cover, // Ensures the image fits within the circle
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
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}

