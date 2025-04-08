import 'package:Learnbound/screen/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database/user_provider.dart';
import 'screen/loading_screen.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // sqfliteFfiInit();
  // databaseFactory = databaseFactoryFfi;

  await Supabase.initialize(
    url: 'https://acxqyygwnsuyturslbpa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFjeHF5eWd3bnN1eXR1cnNsYnBhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM0MzEyODIsImV4cCI6MjA1OTAwNzI4Mn0.RnF9PMageUkyBa_C7YvLMYvyEIyJXIIFnLxBm5vtEM4',
  );

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
        // home: _isLoading
        //     ? LoadingScreen()
        //     : FutureBuilder<bool?>(
        //         future: isFirstTime(),
        //         builder: (context, snapshot) {
        //           if (snapshot.connectionState == ConnectionState.waiting) {
        //             // While waiting for the future, show a loading indicator
        //             return LoadingScreen();
        //           } else {
        //             // Render appropriate screen based on `isFirstTime`
        //             bool? isFirstTimeResult = snapshot.data;
        //             return isFirstTimeResult == true
        //                 ? LoginScreen()
        //                 : StartScreen();
        //           }
        //         },
        //       ),
        home: _isLoading ? LoadingScreen() : LoginScreen());
  }
}
