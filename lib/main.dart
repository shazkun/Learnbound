import 'dart:io';

import 'package:Learnbound/screen/start_screen.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Learnbound/screen/loading_screen.dart'; // Import the LoadingScreen widget

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

  @override
  void initState() {
    super.initState();
    // Simulate loading with a delay or await initialization tasks
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learnbound',
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
      home: _isLoading ? LoadingScreen() : StartScreen(),
    );
  }
}
