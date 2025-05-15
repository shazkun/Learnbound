import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnbound/database/user_provider.dart';
import 'package:learnbound/screen/auth/login/login_screen.dart';
import 'package:learnbound/util/design/appbar.dart';
import 'package:provider/provider.dart';

import '../util/design/snackbar.dart';

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
      CustomSnackBar.show(
        context,
        'Profile picture deleted successfully.',
        isSuccess: true,
      );
    } else {
      CustomSnackBar.show(
        context,
        'Failed to delete profile picture.',
        isSuccess: false,
      );
    }
  }

  void _showModernDialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              SizedBox(height: 8),
              Divider(thickness: 1),
            ],
          ),
          content: content,
          actions: actions,
          actionsAlignment: MainAxisAlignment.end,
        );
      },
    );
  }

  void _showChangeUsername(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    _showModernDialog(
      title: 'Change Username',
      content: TextField(
        maxLength: 12,
        controller: usernameController,
        decoration: InputDecoration(
          hintText: 'Enter new username',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
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
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    bool isCurrentVisible = false;
    bool isNewVisible = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Change Password',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  SizedBox(height: 8),
                  Divider(thickness: 1),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: !isCurrentVisible,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(isCurrentVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() => isCurrentVisible = !isCurrentVisible);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: !isNewVisible,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(isNewVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() => isNewVisible = !isNewVisible);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final current = currentPasswordController.text;
                    final newPass = newPasswordController.text;

                    if (current.isEmpty || newPass.isEmpty) {
                      CustomSnackBar.show(context, 'Please fill in all fields.',
                          isSuccess: false);
                      return;
                    }
                    if (newPass.length < 6) {
                      CustomSnackBar.show(context,
                          'New password must be at least 6 characters.',
                          isSuccess: false);
                      return;
                    }
                    if (newPass == current) {
                      CustomSnackBar.show(context,
                          'New password cannot be the same as current.',
                          isSuccess: false);
                      return;
                    }

                    final success =
                        await userProvider.changePassword(current, newPass);
                    if (success) {
                      Navigator.pop(context);
                      CustomSnackBar.show(
                          context, 'Password changed successfully!',
                          isSuccess: true);
                    } else {
                      CustomSnackBar.show(
                          context, 'Incorrect current password.',
                          isSuccess: false);
                    }
                  },
                  child: Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  void _logout() async {
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you really want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm logout
              },
              child: Text('Logout'),
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
              color: const Color(0xFFD7C19C),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version: 1.2.2',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'LearnBound is your smart study companion app to help students learn effectively.',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              SizedBox(height: 15),
              Text(
                'Contact:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'support@learnbound.com',
                style: TextStyle(color: const Color(0xFFD7C19C)),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                textStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBarCustom(
        showBackButton: true,
        titleText: 'Profile',
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          padding:
              EdgeInsets.only(bottom: 20), // Add padding to avoid FAB overlap
          child: Column(
            children: [
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
                          child: Text('Change Profile'),
                        ),
                        TextButton(
                          onPressed: _deleteProfilePicture,
                          child: Text('Delete Profile'),
                        ),
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
                      leading: Iconify(Mdi.rename_box),
                      title: Text('Change username'),
                      onTap: () {
                        _showChangeUsername(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.lock),
                      title: Text('Change password'),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                  ],
                ),
              ),
              // Add extra space at the bottom to ensure all content is accessible
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAbout(); // Ensure this function accepts BuildContext if needed
        },
        hoverColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        child: Icon(
          Icons.info_outlined,
          size: 32,
          color: Colors.black,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
