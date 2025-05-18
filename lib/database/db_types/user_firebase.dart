// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// // ignore: library_prefixes
// import '../../models/user.dart' as AppUser; // Alias to avoid Firebase conflict

// class UserProvider with ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   AppUser.User? _user; // Store user data from Firestore

//   AppUser.User? get user => _user;

//   /// **Listen to Auth State Changes**
//   UserProvider() {
//     _auth.authStateChanges().listen((User? firebaseUser) async {
//       if (firebaseUser != null) {
//         await fetchUserData(firebaseUser.uid);
//       } else {
//         _user = null;
//       }
//       notifyListeners();
//     });
//   }
//   Future<bool> isEmailRegistered(String email) async {
//     try {
//       var querySnapshot = await _firestore
//           .collection("users")
//           .where("email", isEqualTo: email)
//           .get();

//       return querySnapshot.docs.isNotEmpty; // Returns true if the email exists
//     } catch (e) {
//       print("Error checking email registration: $e");
//       return false; // Assume false on error to avoid blocking registration
//     }
//   }

//   Future<bool> registerUser(
//       String username, String email, String password, String pathimg) async {
//     try {
//       // **Register in Firebase Authentication**
//       UserCredential userCredential =
//           await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       // **Save user details in Firestore (without password)**
//       String uid = userCredential.user!.uid;
//       await _firestore.collection("users").doc(uid).set({
//         'uid': uid,
//         'username': username,
//         'email': email,
//         'profile_picture': pathimg,
//       });

//       // **Fetch & Update User Provider**
//       await fetchUserData(uid);
//       return true;
//     } catch (e) {
//       print("Error registering user: $e");
//       return false;
//     }
//   }

//   /// **Fetch User Data from Firestore**
//   Future<void> fetchUserData(String uid) async {
//     try {
//       DocumentSnapshot doc =
//           await _firestore.collection("users").doc(uid).get();

//       if (doc.exists) {
//         _user = AppUser.User.fromMap(doc.data() as Map<String, dynamic>);
//         notifyListeners();
//       }
//     } catch (e) {
//       print("Error fetching user data: $e");
//     }
//   }

//   /// **Login User**
//   Future<bool> loginUser(String email, String password) async {
//     try {
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       await fetchUserData(userCredential.user!.uid);
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   Future<bool> changePassword(
//       String currentPassword, String newPassword) async {
//     try {
//       User? user = _auth.currentUser;
//       if (user == null) return false;

//       // Re-authenticate the user before changing the password
//       AuthCredential credential = EmailAuthProvider.credential(
//         email: user.email!,
//         password: currentPassword, // Verify the old password
//       );

//       // await user.reauthenticateWithCredential(credential);
//       await user.updatePassword(newPassword);

//       return true; // Password change successful
//     } on FirebaseAuthException catch (e) {
//       print("FirebaseAuthException: ${e.message}");
//       return false;
//     } catch (e) {
//       print("Unexpected error: $e");
//       return false;
//     }
//   }

//   /// **Update Profile Picture**
//   Future<void> updateProfilePicture(String imageUrl) async {
//     if (_user == null) return;

//     try {
//       await _firestore.collection("users").doc(_user!.uid).update({
//         "profile_picture": imageUrl,
//       });

//       _user = AppUser.User(
//         uid: _user!.uid,
//         username: _user!.username,
//         email: _user!.email,
//         profilePicture: imageUrl, // Update profile picture
//       );

//       notifyListeners();
//     } catch (e) {
//       print("Error updating profile picture: $e");
//     }
//   }

//   /// **Logout**
//   Future<void> logout() async {
//     await _auth.signOut();
//     _user = null;
//     notifyListeners();
//   }

//   Future<bool> changeUsername(String newUsername) async {
//     try {
//       User? user = _auth.currentUser;
//       if (user == null) return false;

//       // Update the username in Firestore
//       await _firestore.collection("users").doc(user.uid).update({
//         'username': newUsername,
//       });

//       // No need to manually fetch data here, Firestore listener will handle updates
//       return true;
//     } catch (e) {
//       print("Error changing username: $e");
//       return false;
//     }
//   }

//   final StreamController<AppUser.User?> _userStreamController =
//       StreamController<AppUser.User?>.broadcast();
//   void listenToUserChanges() {
//     User? firebaseUser = _auth.currentUser;
//     if (firebaseUser != null) {
//       _firestore
//           .collection('users')
//           .doc(firebaseUser.uid)
//           .snapshots()
//           .listen((snapshot) {
//         if (snapshot.exists) {
//           final newUser =
//               AppUser.User.fromMap(snapshot.data() as Map<String, dynamic>);
//           _userStreamController.add(newUser);
//         }
//       });

//       // Listen to stream on main thread
//       _userStreamController.stream.listen((newUser) {
//         _user = newUser;
//         notifyListeners();
//       });
//     }
//   }
// }
// /////////FIREBASE