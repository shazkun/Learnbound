import 'package:flutter/material.dart';
import 'package:learnbound/database/user_provider.dart';
import 'package:learnbound/screen/home_screen.dart';
import 'package:learnbound/util/design/snackbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void loadUserData({
  required void Function(VoidCallback) setState,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required void Function(bool) updateRememberMe,
}) async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    bool rememberMe = prefs.getBool('rememberMe') ?? false;
    updateRememberMe(rememberMe);
    if (rememberMe) {
      emailController.text = prefs.getString('email') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
    }
  });
}

Future<void> saveUserData({
  required bool rememberMe,
  required String email,
  required String password,
}) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool('rememberMe', rememberMe);
  if (rememberMe) {
    prefs.setString('email', email);
    prefs.setString('password', password);
  } else {
    prefs.remove('email');
    prefs.remove('password');
  }

  await prefs.setString('userEmail', email);
}

Future<void> login({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required VoidCallback saveUserData,
}) async {
  String email = emailController.text.trim();
  String password = passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    CustomSnackBar.show(context, 'Please fill in all fields.',
        isSuccess: false);
    return;
  }

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(email)) {
    CustomSnackBar.show(context, 'Invalid email format.', isSuccess: false);
    return;
  }

  if (password.length < 6) {
    CustomSnackBar.show(context, 'Password must be at least 6 characters.',
        isSuccess: false);
    return;
  }

  if (formKey.currentState?.validate() ?? false) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    try {
      bool success = await userProvider.loginUser(email, password);

      if (!context.mounted) return;

      if (success) {
        saveUserData();
        await prefs.setBool('isLoggedIn', true);
        CustomSnackBar.show(
          context,
          "Login successful!",
          isSuccess: true,
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        CustomSnackBar.show(context, 'Invalid email or password.',
            isSuccess: false);
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        'An error occurred: $e',
        isSuccess: false,
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }
}
