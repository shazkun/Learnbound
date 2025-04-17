import 'package:Learnbound/database/user_provider.dart';
import 'package:Learnbound/models/user.dart';
import 'package:Learnbound/screen/auth/login/login_screen.dart';
import 'package:Learnbound/util/design/cs_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class RegisterFunctions {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  String? profilePicture;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  void togglePasswordVisibility(VoidCallback setState) {
    isPasswordVisible = !isPasswordVisible;
    setState();
  }

  void toggleConfirmPasswordVisibility(VoidCallback setState) {
    isConfirmPasswordVisible = !isConfirmPasswordVisible;
    setState();
  }

  Future<void> pickImage(VoidCallback setState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      profilePicture = pickedFile.path;
      setState();
    }
  }

  Future<void> register(BuildContext context) async {
    if (formKey.currentState?.validate() ?? false) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Check if email is already registered
      bool emailExists =
          await userProvider.isEmailRegistered(emailController.text);
      if (emailExists) {
        CustomSnackBar.show(
          context,
          "Email is already registered. Try logging in instead.",
          isSuccess: false,
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
        return;
      }

      // Proceed with registration
      final newUser = User(
        id: null,
        username: usernameController.text,
        email: emailController.text,
        password: passwordController.text,
        profilePicture: profilePicture ?? '',
      );

      await userProvider.registerUser(newUser);

      if (context.mounted) {
        CustomSnackBar.show(
          context,
          "Registration successful! Welcome 🎉",
          isSuccess: true,
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
       Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email cannot be empty";
    } else if (!emailRegex.hasMatch(value)) {
      return "Enter a valid email address";
    }
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return "Username cannot be empty";
    } else if (!usernameRegex.hasMatch(value)) {
      return "Username can only contain letters, numbers, and underscores";
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password cannot be empty";
    } else if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    } else if (value != passwordController.text) {
      return "Passwords do not match";
    }
    return null;
  }

  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }
}
