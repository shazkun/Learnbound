// import 'package:Learnbound/database/user_provider.dart';
// import 'package:Learnbound/util/design/cs_snackbar.dart';
// import 'package:Learnbound/screen/home_screen.dart';
// import 'package:Learnbound/old%20files/register_screen.dart';
// import 'package:Learnbound/util/design/wave.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isPasswordVisible = false;
//   bool _rememberMe = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   void _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _rememberMe = prefs.getBool('rememberMe') ?? false;
//       if (_rememberMe) {
//         _emailController.text = prefs.getString('email') ?? '';
//         _passwordController.text = prefs.getString('password') ?? '';
//       }
//     });
//   }

//   void _saveUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     prefs.setBool('rememberMe', _rememberMe);
//     if (_rememberMe) {
//       prefs.setString('email', _emailController.text);
//       prefs.setString('password', _passwordController.text);
//     } else {
//       prefs.remove('email');
//       prefs.remove('password');
//     }
//     await prefs.setBool('isLoggedIn', true);
//     await prefs.setString('userEmail', _emailController.text);
//   }

//   Future<void> _login() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       final userProvider = Provider.of<UserProvider>(context, listen: false);

//       await userProvider.loginUser(
//         _emailController.text,
//         _passwordController.text,
//       );

//       if (!mounted) return; // Check if the widget is still in the tree

//       if (userProvider.user != null) {
//         _saveUserData();

//         CustomSnackBar.show(
//           context,
//           "Login successful!",
//           isSuccess: true,
//           backgroundColor: Colors.green,
//           icon: Icons.check_circle,
//         );

//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => HomeScreen()),
//         );
//       } else {
//         CustomSnackBar.show(context, 'Invalid email or password',
//             isSuccess: false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final isSmallScreen = screenSize.width < 600; // Threshold for small screens

//     return WillPopScope(
//       onWillPop: () async => false, // Prevents back navigation
//       child: Scaffold(
//         resizeToAvoidBottomInset:
//             false, // Prevents bottom widgets from shifting up
//         body: Stack(
//           children: [
//             // Logo positioned at top left
//             Positioned(
//               top: screenSize.height * 0.05, // 5% from top
//               left: screenSize.width * 0.05, // 5% from left
//               child: Image.asset(
//                 'assets/logoonly.png',
//                 width: isSmallScreen ? 50 : 60,
//                 height: isSmallScreen ? 50 : 60,
//               ),
//             ),

//             // Concurrent Login UI
//             Center(
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.only(
//                   bottom: MediaQuery.of(context)
//                       .viewInsets
//                       .bottom, // Keyboard adjustment
//                   left: screenSize.width * 0.08, // 8% horizontal padding
//                   right: screenSize.width * 0.08,
//                 ),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(
//                           height:
//                               screenSize.height * 0.12), // Dynamic top spacing

//                       // Sign In Title
//                       Text(
//                         "Sign In",
//                         style: TextStyle(
//                           fontSize: isSmallScreen ? 22 : 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),

//                       // Subtitle
//                       Text(
//                         "Please fill the credentials",
//                         style: TextStyle(
//                           fontSize: isSmallScreen ? 12 : 14,
//                           color: Colors.grey,
//                         ),
//                       ),

//                       SizedBox(height: screenSize.height * 0.05),

//                       // Email Field
//                       TextFormField(
//                         controller: _emailController,
//                         decoration: InputDecoration(
//                           prefixIcon: const Icon(Icons.person),
//                           labelText: "Email",
//                           filled: true,
//                           fillColor: Colors.brown[100],
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(15),
//                             borderSide: BorderSide.none,
//                           ),
//                           contentPadding: EdgeInsets.symmetric(
//                             vertical: isSmallScreen ? 12 : 16,
//                             horizontal: 10,
//                           ),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return "Please enter your email";
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: screenSize.height * 0.025),

//                       // Password Field
//                       TextFormField(
//                         controller: _passwordController,
//                         obscureText: !_isPasswordVisible,
//                         decoration: InputDecoration(
//                           prefixIcon: const Icon(Icons.lock),
//                           labelText: "Password",
//                           filled: true,
//                           fillColor: Colors.brown[100],
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(15),
//                             borderSide: BorderSide.none,
//                           ),
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _isPasswordVisible
//                                   ? Icons.visibility
//                                   : Icons.visibility_off,
//                             ),
//                             onPressed: () {
//                               setState(() {
//                                 _isPasswordVisible = !_isPasswordVisible;
//                               });
//                             },
//                           ),
//                           contentPadding: EdgeInsets.symmetric(
//                             vertical: isSmallScreen ? 12 : 16,
//                             horizontal: 10,
//                           ),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return "Please enter your password";
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: screenSize.height * 0.015),

//                       // Remember Me Checkbox
//                       Row(
//                         children: [
//                           Checkbox(
//                             value: _rememberMe,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(5),
//                             ),
//                             activeColor: Colors.grey,
//                             onChanged: (value) {
//                               setState(() {
//                                 _rememberMe = value ?? false;
//                               });
//                             },
//                           ),
//                           GestureDetector(
//                             onTap: () {
//                               setState(() {
//                                 _rememberMe = !_rememberMe;
//                               });
//                             },
//                             child: Text(
//                               "Remember Me",
//                               style: TextStyle(
//                                 fontSize: isSmallScreen ? 14 : 16,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: screenSize.height * 0.04),

//                       // Sign In Button
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor:
//                                 const Color.fromRGBO(211, 172, 112, 1.0),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                             padding: EdgeInsets.symmetric(
//                               vertical: isSmallScreen ? 16 : 20,
//                             ),
//                           ),
//                           onPressed: _login,
//                           child: Text(
//                             "Sign In",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: isSmallScreen ? 16 : 18,
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: screenSize.height * 0.025),

//                       // Sign Up Link
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Don't have an account? ",
//                             style: TextStyle(
//                               fontSize: isSmallScreen ? 14 : 16,
//                             ),
//                           ),
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => RegisterScreen(),
//                                 ),
//                               );
//                             },
//                             child: Text(
//                               "Sign up",
//                               style: TextStyle(
//                                 color: Colors.orange,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: isSmallScreen ? 14 : 16,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: screenSize.height * 0.025),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // Bottom UI (Wave)
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: IgnorePointer(
//                 ignoring: MediaQuery.of(context).viewInsets.bottom >
//                     0, // Hide with keyboard
//                 child: ClipPath(
//                   clipper: BottomWaveClipper(),
//                   child: Container(
//                     height: screenSize.height * 0.15, // 15% of screen height
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Color(0xFFD7C19C),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
