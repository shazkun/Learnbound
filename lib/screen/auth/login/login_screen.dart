import 'package:learnbound/screen/auth/login/login_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_functions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    loadUserData(
      setState: setState,
      emailController: _emailController,
      passwordController: _passwordController,
      updateRememberMe: (value) => _rememberMe = value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildLoginUI(
      context: context,
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      isPasswordVisible: _isPasswordVisible,
      rememberMe: _rememberMe,
      togglePasswordVisibility: () {
        setState(() {
          _isPasswordVisible = !_isPasswordVisible;
        });
      },
      toggleRememberMe: (value) {
        setState(() {
          _rememberMe = value ?? false;
        });
      },
      onLogin: () => login(
        context: context,
        formKey: _formKey,
        emailController: _emailController,
        passwordController: _passwordController,
        saveUserData: () => saveUserData(
          rememberMe: _rememberMe,
          email: _emailController.text,
          password: _passwordController.text,
        ),
      ),
    );
  }
}
