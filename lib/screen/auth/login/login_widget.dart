import 'package:flutter/material.dart';
import 'package:learnbound/screen/auth/login/reset/reset_screen.dart';
import 'package:learnbound/screen/auth/register/register_screen.dart'
    show RegisterScreen;
import 'package:learnbound/util/design/wave.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset(
            'assets/logoonly.png',
            height: isSmallScreen ? 80 : 100, // Increased logo size here
          ),
        ),
        toolbarHeight:
            isSmallScreen ? 80 : 100, // Increased AppBar height to fit the logo
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: screenSize.height * 0.18, // Space for bottom wave
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.08,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenSize.height * 0.10),
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
                        keyboardType: TextInputType.emailAddress,
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          labelText: "Password",
                          filled: true,
                          fillColor: Colors.brown[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: !rememberMe
                              ? IconButton(
                                  icon: Icon(
                                    isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: togglePasswordVisibility)
                              : null,
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
                            onChanged: (value) async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('rememberMe', value ?? false);
                              toggleRememberMe(value);
                            },
                          ),
                          GestureDetector(
                            onTap: () async {
                              final newValue = !rememberMe;
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('rememberMe', newValue);
                              toggleRememberMe(newValue);
                            },
                            child: Text(
                              "Remember Me",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Container()), // takes remaining space
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ResetPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Forgot password? ",
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.grey[600],
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
                            softWrap: true,
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Sign up",
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ClipPath(
            clipper: BottomClipper(),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: const BoxDecoration(color: Color(0xFFD7C19C)),
            ),
          ),
        ],
      ),
    ),
  );
}
