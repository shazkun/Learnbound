
import 'package:Learnbound/screen/auth/register/register_functions.dart';
import 'package:flutter/material.dart';
import 'register_ui.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final logic = RegisterFunctions();

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar:  RegisterUI.buildAppBar(context, isSmallScreen),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              
              SizedBox(height: screenSize.height * 0.03),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
                child: Form(
                  key: logic.formKey,
                  child: Column(
                    children: [
                      RegisterUI.buildProfilePicture(
                        logic.profilePicture,
                        () => logic.pickImage(() => setState(() {})),
                        isSmallScreen,
                      ),
                      SizedBox(height: screenSize.height * 0.03),
                      RegisterUI.buildTextField(
                        "Email",
                        Icons.email,
                        logic.emailController,
                        validator: logic.validateEmail,
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      RegisterUI.buildTextField(
                        "Username",
                        Icons.person,
                        logic.usernameController,
                        validator: logic.validateUsername,
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      RegisterUI.buildTextField(
                        "Password",
                        Icons.lock,
                        logic.passwordController,
                        obscureText: !logic.isPasswordVisible,
                        isPassword: true,
                        toggleVisibility: () => logic
                            .togglePasswordVisibility(() => setState(() {})),
                        validator: logic.validatePassword,
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      RegisterUI.buildTextField(
                        "Confirm Password",
                        Icons.lock,
                        logic.confirmPasswordController,
                        obscureText: !logic.isConfirmPasswordVisible,
                        isPassword: true,
                        toggleVisibility: () =>
                            logic.toggleConfirmPasswordVisibility(
                                () => setState(() {})),
                        validator: logic.validateConfirmPassword,
                      ),
                      SizedBox(height: screenSize.height * 0.03),
                      RegisterUI.buildRegisterButton(
                        () => logic.register(context),
                        isSmallScreen,
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      RegisterUI.buildSignInLink(context, isSmallScreen),
                      SizedBox(height: screenSize.height * 0.02),
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
}
