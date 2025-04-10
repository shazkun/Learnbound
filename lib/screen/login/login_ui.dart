import 'package:Learnbound/screen/register_screen.dart';
import 'package:Learnbound/util/design/wave.dart';
import 'package:flutter/material.dart';

Widget buildLoginUI({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required bool isPasswordVisible,
  required bool rememberMe,
  required VoidCallback togglePasswordVisibility,
  required void Function(bool?) toggleRememberMe,
  required VoidCallback onLogin,
}) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;

  return WillPopScope(
    onWillPop: () async => false,
    child: Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: screenSize.height * 0.05,
            left: screenSize.width * 0.05,
            child: Image.asset(
              'assets/logoonly.png',
              width: isSmallScreen ? 50 : 60,
              height: isSmallScreen ? 50 : 60,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: screenSize.width * 0.08,
                right: screenSize.width * 0.08,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenSize.height * 0.12),
                    Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Please fill the credentials",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.05),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person),
                        labelText: "Email",
                        filled: true,
                        fillColor: Colors.brown[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16,
                          horizontal: 10,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Please enter your email"
                          : null,
                    ),
                    SizedBox(height: screenSize.height * 0.025),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        labelText: "Password",
                        filled: true,
                        fillColor: Colors.brown[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: togglePasswordVisibility,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16,
                          horizontal: 10,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Please enter your password"
                          : null,
                    ),
                    SizedBox(height: screenSize.height * 0.015),
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          activeColor: Colors.grey,
                          onChanged: toggleRememberMe,
                        ),
                        GestureDetector(
                          onTap: () => toggleRememberMe(!rememberMe),
                          child: Text(
                            "Remember Me",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.04),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(211, 172, 112, 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 16 : 20),
                        ),
                        onPressed: onLogin,
                        child: Text(
                          "Sign In",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 16 : 18,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.025),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegisterScreen()),
                            );
                          },
                          child: Text(
                            "Sign up",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.025),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              ignoring: MediaQuery.of(context).viewInsets.bottom > 0,
              child: ClipPath(
                clipper: BottomWaveClipper(),
                child: Container(
                  height: screenSize.height * 0.15,
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xFFD7C19C)),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
