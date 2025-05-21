import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnbound/database/user_provider.dart';
import 'package:learnbound/screen/auth/login/login_screen.dart';
import 'package:learnbound/util/design/appbar.dart';
import 'package:learnbound/util/design/colors.dart';
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
      bool success = await userProvider.updateProfilePicture(pickedFile.path);

      if (success) {
        CustomSnackBar.show(context, 'Profile picture updated successfully.');
        Navigator.of(context).pop();
      } else {
        CustomSnackBar.show(context, 'Failed to update profile picture.');
      }
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
      Navigator.of(context).pop();
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
                TextButton(
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

  Widget buildButton({
    required Widget icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final double screenHeight = MediaQuery.of(context).size.height;

        final double buttonWidth =
            (constraints.maxWidth * 0.95).clamp(160, 320);
        final double buttonHeight = (screenHeight * 0.18).clamp(60, 100);
        final double fontSize = (screenWidth * 0.045).clamp(16, 20);
        final double padding = (screenWidth * 0.03).clamp(12, 20);
        final double spacing = (screenWidth * 0.02).clamp(8, 16);

        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding * 0.8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(padding * 0.8),
              ),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: fontSize,
                    color: Colors.black,
                  ),
            ),
            onPressed: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: icon,
                ),
                SizedBox(width: spacing),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: fontSize,
                          color: Colors.black,
                        ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    // Responsive sizing based on screen width and height
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double padding =
        (screenWidth * 0.04).clamp(16, 24); // Adjusted for larger screens
    final double avatarRadius =
        (screenWidth * 0.12).clamp(50, 100); // Larger avatar range
    final double imageSize = avatarRadius * 2;
    final double spacing =
        (screenHeight * 0.015).clamp(10, 16); // Increased spacing

    return Scaffold(
      appBar: AppBarCustom(
        showBackButton: true,
        titleText: 'Profile',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 800, // Increased for fullscreen monitors
              minWidth: 320, // Slightly increased for small screens
            ),
            child: Container(
              padding: EdgeInsets.all(padding * 1.5),
              decoration: BoxDecoration(
                color: AppColors.bgGrey200,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Options',
                              style: Theme.of(context).textTheme.titleMedium),
                          content: Text(
                            'You can change or delete your profile picture.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          actions: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TextButton(
                                  onPressed: _changeProfilePicture,
                                  child: Text('Change'),
                                ),
                                TextButton(
                                  onPressed: _deleteProfilePicture,
                                  child: Text('Delete'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Cancel'),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: user?.profilePicture != null &&
                                user!.profilePicture!.isNotEmpty
                            ? Image.file(
                                File(user.profilePicture!),
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/defaultprofile.png',
                                    width: imageSize,
                                    height: imageSize,
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/defaultprofile.png',
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
                  Text(
                    user?.username ?? "Name",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: (screenWidth * 0.045)
                              .clamp(18, 22), // Slightly larger
                        ),
                  ),
                  SizedBox(height: spacing * 1.5),
                  Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: (screenWidth * 0.05).clamp(20, 40)),
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildButton(
                          icon: Iconify(
                            Mdi.rename_box,
                            size: (screenWidth * 0.05)
                                .clamp(20, 28), // Dynamic icon size
                          ),
                          label: 'Change nickname',
                          color: AppColors.learnBound,
                          onPressed: () => _showChangeUsername(context),
                        ),
                        SizedBox(height: spacing * 1.5),
                        buildButton(
                          icon: Iconify(
                            Mdi.lock,
                            size: (screenWidth * 0.05).clamp(20, 28),
                          ),
                          label: 'Change password',
                          color: AppColors.learnBound,
                          onPressed: () => _showChangePasswordDialog(context),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing * 3),
                  Text(
                    '© BTVTED-CP-TUPC',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: (screenWidth * 0.035).clamp(12, 16),
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
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
