import 'package:learnbound/database/user_provider.dart';
import 'package:learnbound/screen/home_screen.dart';
import 'package:learnbound/util/design/snackbar.dart';
import 'package:flutter/material.dart';
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
  if (formKey.currentState?.validate() ?? false) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    try {
      await userProvider.loginUser(
        emailController.text,
        passwordController.text,
      );

      if (!context.mounted) return;

      if (userProvider.user != null) {
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
        CustomSnackBar.show(
          context,
          'Invalid email or password',
          isSuccess: false,
        );
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
