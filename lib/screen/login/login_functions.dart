import 'package:Learnbound/database/user_provider.dart';
import 'package:Learnbound/screen/home_screen.dart';
import 'package:Learnbound/util/design/cs_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  await prefs.setBool('isLoggedIn', true);
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
    final supabase = Supabase.instance.client; // Get Supabase client instance
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      // Check if the user exists in the Supabase 'users' table
      final response = await supabase
          .from('users') // Replace 'users' with your actual table name
          .select()
          .eq('email', emailController.text)
          .maybeSingle(); // Use maybeSingle to get a single record or null

      if (response == null) {
        // User does not exist
        CustomSnackBar.show(
          context,
          'User with this email does not exist',
          isSuccess: false,
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
        return;
      }

      // If user exists, proceed with login
      await userProvider.loginUser(
        emailController.text,
        passwordController.text,
      );

      if (!context.mounted) return; // Check if the widget is still in the tree

      if (userProvider.user != null) {
        saveUserData();

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
      // Handle any errors (e.g., network issues, Supabase misconfiguration)
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
