import 'dart:io';

import 'package:Learnbound/database/database_helper.dart';
import 'package:Learnbound/screen/auth_screen.dart';
import 'package:Learnbound/screen/loading_screen.dart';
import 'package:Learnbound/screen/start_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI database factory
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(
    ProviderScope(
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
  final DatabaseHelper db = DatabaseHelper();

  Future<bool?> isFirstTime() async {
    final ff = await db.getFlagStatus('first_time');
    print(ff);
    return ff;
  }

  @override
  void initState() {
    super.initState();
  
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnBound',
      theme: ThemeData(
        // Define a custom color scheme to control button colors
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.black, // Color for ElevatedButton background
          secondary:
              Colors.red, // Accent color for FloatingActionButton or toggles
          onPrimary: Colors.white, // Text color on ElevatedButton
          onSecondary: Colors.red, // Text color for secondary (TextButton)
        ),
      ),
      home: _isLoading
          ? LoadingScreen()
          : FutureBuilder<bool?>(
              future: isFirstTime(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // While waiting for the future, show a loading indicator
                  return LoadingScreen();
                } else {
                  // Render appropriate screen based on `isFirstTime`
                  bool? isFirstTimeResult = snapshot.data;
                  return isFirstTimeResult == true
                      ? AuthScreen()
                      : StartScreen();
                }
              },
            ),
    );
  }
}
