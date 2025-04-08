import 'dart:io';

import 'package:Learnbound/util/design/cs_snackbar.dart';
import 'package:Learnbound/screen/login_screen.dart';
import 'package:Learnbound/util/design/wave.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../database/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _profilePicture;
  final _formKey = GlobalKey<FormState>();

  final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');

  bool _isPasswordVisible = false;

  bool _isConfirmPasswordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profilePicture = pickedFile.path;
      });
    }
  }

  // Future<void> _register() async {
  //   if (_formKey.currentState?.validate() ?? false) {
  //     final userProvider = Provider.of<UserProvider>(context, listen: false);

  //     // Check if email is already registered
  //     bool emailExists =
  //         await userProvider.isEmailRegistered(_emailController.text);
  //     if (emailExists) {
  //       if (!mounted) return;
  //       CustomSnackBar.show(
  //         context,
  //         "Email is already registered. Try logging in instead.",
  //         isSuccess: false,
  //         backgroundColor: Colors.red,
  //         icon: Icons.error,
  //       );

  //       return; // Stop registration
  //     }

  //     // If email is unique, proceed with registration
  //     final newUser = User(
  //       uid: null, // Auto-generated in DB
  //       username: _usernameController.text,
  //       email: _emailController.text,
  //       password: _passwordController.text,
  //       profilePicture: _profilePicture ?? '',
  //     );

  //     await userProvider.registerUser(newUser);

  //     if (context.mounted) {
  //       return CustomSnackBar.show(
  //         context,
  //         "Registration successful! Welcome 🎉",
  //         isSuccess: true,
  //         backgroundColor: Colors.green,
  //         icon: Icons.check_circle,
  //       );
  //     }
  //   }
  // }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Check if email is already registered
      bool emailExists =
          await userProvider.isEmailRegistered(_emailController.text);
      if (emailExists) {
        if (!mounted) return;
        CustomSnackBar.show(
          context,
          "Email is already registered. Try logging in instead.",
          isSuccess: false,
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
        return; // Stop registration
      }

      // **Proceed with registration using Firebase**
      bool success = await userProvider.registerUser(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
          _profilePicture ?? '');

      if (success) {
        if (!mounted) return;
        CustomSnackBar.show(
          context,
          "Registration successful! Welcome 🎉",
          isSuccess: true,
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        // Navigate to home screen or login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size information
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen =
        screenSize.width < 600; // Define small screen threshold

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // Wrap with SafeArea to handle notches and status bars
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Curved Header
              ClipPath(
                clipper: TopClipper(),
                child: Container(
                  height: screenSize.height * 0.18, // 18% of screen height
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFD7C19C),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: screenSize.height * 0.04, // Dynamic positioning
                        right: screenSize.width * 0.1, // 10% from right
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.03), // Dynamic spacing
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.08, // 8% of screen width
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: isSmallScreen
                              ? 40
                              : 50, // Smaller on small screens
                          backgroundColor: Colors.grey[200],
                          child: ClipOval(
                            child: _profilePicture != null &&
                                    _profilePicture!.isNotEmpty
                                ? Image.file(
                                    File(_profilePicture!),
                                    width: isSmallScreen ? 80 : 100,
                                    height: isSmallScreen ? 80 : 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'assets/defaultprofile.png',
                                    width: isSmallScreen ? 80 : 100,
                                    height: isSmallScreen ? 80 : 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.03),
                      buildTextField(
                        "Email",
                        Icons.email,
                        _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Email cannot be empty";
                          } else if (!emailRegex.hasMatch(value)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      buildTextField(
                        "Username",
                        Icons.person,
                        _usernameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Username cannot be empty";
                          } else if (!usernameRegex.hasMatch(value)) {
                            return "Username can only contain letters, numbers, and underscores";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      buildTextField(
                        "Password",
                        Icons.lock,
                        _passwordController,
                        obscureText: !_isPasswordVisible,
                        isPassword: true,
                        toggleVisibility: _togglePasswordVisibility,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password cannot be empty";
                          } else if (value.length < 6) {
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      buildTextField(
                        "Confirm Password",
                        Icons.lock,
                        _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        isPassword: true,
                        toggleVisibility: _toggleConfirmPasswordVisibility,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please confirm your password";
                          } else if (value != _passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenSize.height * 0.03),
                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFD3AC70),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize:
                                Size.fromHeight(isSmallScreen ? 45 : 50),
                          ),
                          child: Text(
                            "Register",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 16 : 18,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      // Sign in Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have account? ",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()),
                              );
                            },
                            child: Text(
                              "Sign in",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                          height: screenSize.height * 0.02), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      String label, IconData icon, TextEditingController controller,
      {bool obscureText = false,
      String? Function(String?)? validator,
      void Function()? toggleVisibility,
      bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black,
                ),
                onPressed: toggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Color(0xFFF5EFE2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
