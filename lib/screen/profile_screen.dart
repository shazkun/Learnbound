import 'dart:io';
import 'package:Learnbound/database/user_provider.dart';
import 'package:Learnbound/screen/wave/wave.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'auth_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  void _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateProfilePicture(pickedFile.path);
    }
  }

  void _deleteProfilePicture() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.updateProfilePicture("");
  }

  void _showChangeUsername(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Username'),
          content: TextField(
            maxLength: 12,
            inputFormatters: [LengthLimitingTextInputFormatter(12)],
            controller: usernameController,
            decoration: InputDecoration(hintText: 'Enter new username'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newUsername = usernameController.text.trim();
                if (newUsername.isNotEmpty && newUsername.length <= 12) {
                  await userProvider.changeUsername(newUsername);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Username updated successfully!')));
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid username.')));
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

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
                if (currentPasswordController.text.isEmpty ||
                    newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill in all fields.')));
                  return;
                }

                if (userProvider.user!.password ==
                    currentPasswordController.text) {
                  if (newPasswordController.text.length >= 6 &&
                      newPasswordController.text !=
                          currentPasswordController.text) {
                    await userProvider
                        .changePassword(newPasswordController.text);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Password changed successfully!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid new password.')));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Current password is incorrect.')));
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
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you really want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.logout();
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => AuthScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ClipPath(
                  clipper: TopClipper(),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Color(0xFFD7C19C),
                    ),
                    child: Stack(
                      children: [
                        SizedBox(height: 20),
                        Row(
                          
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Spacer(),
                            Text(
                              "Profile",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Profile Options'),
                        content:
                            Text('Choose an action for your profile picture:'),
                        actions: [
                          TextButton(
                              onPressed: _changeProfilePicture,
                              child: Text('Change Profile')),
                          TextButton(
                              onPressed: _deleteProfilePicture,
                              child: Text('Delete Profile')),
                        ],
                      );
                    },
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(
                      child: user?.profilePicture != null &&
                              user!.profilePicture!.isNotEmpty
                          ? Image.file(File(user.profilePicture!),
                              width: 100, height: 100, fit: BoxFit.cover)
                          : Image.asset('assets/defaultprofile.png',
                              width: 100, height: 100, fit: BoxFit.cover),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  user?.username ?? "Name",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 20),
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 30),
                  color: Color(0xFFEBE1C8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.lock),
                        title: Text('Change password'),
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Change username'),
                        onTap: () => _showChangeUsername(context),
                      ),
                      ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Logout'),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
