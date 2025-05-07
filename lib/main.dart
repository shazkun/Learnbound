import 'dart:io';
import 'package:flutter/material.dart';
import 'package:learnbound/database/user_provider.dart';
import 'package:learnbound/screen/auth/login/login_screen.dart';
import 'package:learnbound/screen/home_screen.dart';
import 'package:learnbound/screen/loading_screen.dart';
import 'package:learnbound/screen/start_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnBound',
      theme: ThemeData(
        fontFamily: "Poppins",
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.black,
          secondary: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.red,
        ),
      ),
      home: const LoginHandler(),
    );
  }
}

class LoginHandler extends StatefulWidget {
  const LoginHandler({super.key});

  @override
  State<LoginHandler> createState() => _LoginHandlerState();
}

class _LoginHandlerState extends State<LoginHandler> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    if (!seenOnboarding) {
      await prefs.setBool('seenOnboarding', true);
      _goTo(const StartScreen());
      return;
    }

    final bool rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      final String email = prefs.getString('email') ?? '';
      final String password = prefs.getString('password') ?? '';

      try {
        await userProvider.loginUser(email, password);

        if (userProvider.user != null) {
          await prefs.setBool('isLoggedIn', true);
          _goTo(const HomeScreen());
          return;
        }
      } catch (e) {
        debugPrint('Auto-login failed: $e');
      }
    }

    _goTo(const LoginScreen());
  }

  void _goTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingAnimation();
  }
}
