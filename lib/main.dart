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
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.black, 
          secondary:
              Colors.red, 
          onPrimary: Colors.white, 
          onSecondary: Colors.red, 
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
