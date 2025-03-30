import 'dart:io';
import 'package:Learnbound/models/user.dart';

import 'package:Learnbound/screen/auth_screen.dart';
import 'package:Learnbound/screen/login_screen.dart';
import 'package:Learnbound/screen/wave/wave.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Check if email is already registered
      bool emailExists =
          await userProvider.isEmailRegistered(_emailController.text);
      if (emailExists) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text(
                    'Email is already registered. Try logging in instead.'),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
        return; // Stop registration
      }

      // If email is unique, proceed with registration
      final newUser = User(
        id: null, // Auto-generated in DB
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        profilePicture: _profilePicture ?? '',
      );

      await userProvider.registerUser(newUser);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Registration successful'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AuthScreen()),
                    );
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Curved Header
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
                      right: 40, // Moves text to the right
                      child: Text(
                        "Sign Up",
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
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage, // Remove parentheses
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child: _profilePicture != null &&
                                  _profilePicture!.isNotEmpty
                              ? Image.file(
                                  File(_profilePicture!),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
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
                    const SizedBox(height: 30),
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
                    const SizedBox(height: 15),
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
                    const SizedBox(height: 15),
                    buildTextField(
                      "Password",
                      Icons.lock,
                      _passwordController,
                      obscureText: !_isPasswordVisible, // Uses visibility state
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

                    const SizedBox(height: 15),

                    buildTextField(
                      "Confirm Password",
                      Icons.lock,
                      _confirmPasswordController,
                      obscureText:
                          !_isConfirmPasswordVisible, // Uses confirm visibility state
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

                    const SizedBox(height: 25),
                    // Register Button
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD3AC70),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        "Register",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sign in Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          },
                          child: const Text(
                            "Sign in",
                            style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

