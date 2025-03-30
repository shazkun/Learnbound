import 'dart:io';

import 'package:Learnbound/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database/user_provider.dart';
import 'screen/auth_screen.dart';
import 'screen/loading_screen.dart';
import 'screen/start_screen.dart';

void main() {
  //sqlite
  if (Platform.isWindows || Platform.isLinux) {
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
  //final DatabaseHelper db = DatabaseHelper();

  Future<bool?> isFirstTime() async {
    //final ff = await db.getFlagStatus('first_time');
    //print(ff);
    return true;
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 2), () {
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
                      ? LoginScreen()
                      : StartScreen();
                }
              },
            ),
    );
  }
}
