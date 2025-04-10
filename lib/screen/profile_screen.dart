import 'dart:io';
import 'package:Learnbound/database/user_provider.dart';
import 'package:Learnbound/util/design/wave.dart';
import 'package:Learnbound/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../util/design/cs_snackbar.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

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
    final success = await userProvider.updateProfilePicture("");

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture deleted successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete profile picture.')),
      );
    }
  }

  void _showChangeUsername(BuildContext context) {
    if (!mounted) return;
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

                  CustomSnackBar.show(context, 'Username updated successfully!',
                      isSuccess: true);

                  Navigator.of(context).pop();
                } else {
                  CustomSnackBar.show(context, 'Invalid username.',
                      backgroundColor: Colors.red, isSuccess: false);
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
                  CustomSnackBar.show(context, 'Please fill in all fields.',
                      isSuccess: false);
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  CustomSnackBar.show(
                      context, 'New password must be at least 6 characters.',
                      isSuccess: false);
                  return;
                }

                if (newPasswordController.text ==
                    currentPasswordController.text) {
                  CustomSnackBar.show(
                      context, 'New password cannot be the same as current.',
                      isSuccess: false);
                  return;
                }
                bool success = await userProvider.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );

                if (success) {
                  Navigator.of(context).pop();
                  CustomSnackBar.show(context, 'Password changed successfully!',
                      isSuccess: true);
                } else {
                  CustomSnackBar.show(context, 'Incorrect current password.',
                      isSuccess: false);
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

    if (shouldLogout == true || context.mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.logout();
      if (!mounted) return;
      CustomSnackBar.show(context, "You have been logged out.",
          isSuccess: true,
          backgroundColor: Colors.orange,
          icon: Icons.exit_to_app,
          duration: Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
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
                        Positioned(
                            top: 30, // Adjust based on wave shape
                            left: 30, // Moves text to the right
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: SvgPicture.asset(
                                'assets/arrow.svg',
                                height: 24,
                                width: 24,
                                colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn), // Change color
                              ),
                            )),
                        Positioned(
                          top: 30, // Adjust based on wave shape
                          right: 60, // Moves text to the right
                          child: Text(
                            "Profile",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
                          ? Image.network(
                              user!.profilePicture!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to default image if URL fails to load
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
