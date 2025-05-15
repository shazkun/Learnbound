import 'dart:io';

import 'package:flutter/material.dart';
import 'package:learnbound/screen/auth/login/login_screen.dart';
import 'package:learnbound/util/design/wave.dart';

class RegisterUI {
  static PreferredSizeWidget buildAppBar(
      BuildContext context, bool isSmallScreen) {
    final screenSize = MediaQuery.of(context).size;

    return PreferredSize(
      preferredSize: Size.fromHeight(
          screenSize.height * 0.15), // Set the height of the app bar
      child: AppBar(
        centerTitle: true,
        title: Text(
          'Sign Up',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        automaticallyImplyLeading:
            false, // Optional, if you don't want a back button
        backgroundColor: Colors
            .transparent, // Make background transparent to show custom design
        elevation: 0, // Removes the default shadow
        flexibleSpace: ClipPath(
          clipper:
              TopClipper(), // Assuming you have a TopClipper defined elsewhere
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFD7C19C), // Background color of the app bar
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildProfilePicture(
      String? profilePicture, VoidCallback onTap, bool isSmallScreen) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: isSmallScreen ? 40 : 50,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child: profilePicture != null && profilePicture.isNotEmpty
              ? Image.file(
                  File(profilePicture),
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
    );
  }

  static Widget buildTextField(
    TextInputType keyboardType,
    String label,
    IconData icon,
    TextEditingController controller, {
    bool obscureText = false,
    String? Function(String?)? validator,
    VoidCallback? toggleVisibility,
    bool isPassword = false,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
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
        fillColor: const Color(0xFFF5EFE2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static Widget buildRegisterButton(
      VoidCallback onPressed, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD3AC70),
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: Size.fromHeight(isSmallScreen ? 45 : 50),
        ),
        child: Text(
          "Register",
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
      ),
    );
  }

  static Widget buildSignInLink(BuildContext context, bool isSmallScreen) {
    return Row(
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
              MaterialPageRoute(builder: (context) => LoginScreen()),
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
    );
  }
}
