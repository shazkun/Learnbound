import 'dart:convert';
import 'dart:io';

import 'package:Learnbound/screen/auth/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database/user_provider.dart';
import 'screen/loading_screen.dart';
import 'screen/start_screen.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Simulate loading screen for 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        
      });
    });
  }

  Future<bool> isFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? seen = prefs.getBool('seenOnboarding');

    if (seen == null || seen == false) {
      await prefs.setBool('seenOnboarding', true);
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnBound',
      theme: ThemeData(
        fontFamily: "Comic Sans",
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.black,
          secondary: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.red,
        ),
      ),
      home: _isLoading
          ? LoadingScreen()
          : FutureBuilder<bool>(
              future: isFirstTime(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LoadingScreen();
                } else {
                  final firstTime = snapshot.data ?? true;
                  return firstTime ? StartScreen() : LoginScreen();
                }
              },
            ),
    );
  }
}
