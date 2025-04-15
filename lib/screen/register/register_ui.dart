import 'dart:io';
import 'package:Learnbound/screen/login/login_screen.dart';
import 'package:flutter/material.dart';

class RegisterUI {
  static Widget buildHeader(BuildContext context, bool isSmallScreen) {
    final screenSize = MediaQuery.of(context).size;
    return ClipPath(
      clipper: TopClipper(),
      child: Container(
        height: screenSize.height * 0.18,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFD7C19C),
        ),
        child: Stack(
          children: [
            Positioned(
              top: screenSize.height * 0.04,
              right: screenSize.width * 0.1,
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
    String label,
    IconData icon,
    TextEditingController controller, {
    bool obscureText = false,
    String? Function(String?)? validator,
    VoidCallback? toggleVisibility,
    bool isPassword = false,
  }) {
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
           Navigator.push(
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

// Placeholder for TopClipper (replace with your actual Wave clipper)
class TopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
        size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(
        3 * size.width / 4, size.height - 40, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
