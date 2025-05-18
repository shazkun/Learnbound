// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class FirebaseHelper {
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   /// **Register User in Firebase**
//   static Future<String?> registerUser(
//       String email, String password, String username) async {
//     try {
//       UserCredential userCredential =
//           await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       // Store additional user data in Firestore
//       await _firestore.collection("users").doc(userCredential.user!.uid).set({
//         "username": username,
//         "email": email,
//         "profile_picture": "",
//       });

//       return userCredential.user!.uid;
//     } catch (e) {
//       return null; // Handle errors appropriately
//     }
//   }

//   /// **Login User**
//   static Future<User?> loginUser(String email, String password) async {
//     try {
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return userCredential.user;
//     } catch (e) {
//       return null;
//     }
//   }

//   /// **Check if Email is Registered**
//   static Future<bool> isEmailRegistered(String email) async {
//     QuerySnapshot query = await _firestore
//         .collection("users")
//         .where("email", isEqualTo: email)
//         .limit(1)
//         .get();

//     return query.docs.isNotEmpty;
//   }

//   /// **Get User Details**
//   static Future<Map<String, dynamic>?> getUser(String uid) async {
//     DocumentSnapshot doc = await _firestore.collection("users").doc(uid).get();
//     return doc.exists ? doc.data() as Map<String, dynamic> : null;
//   }

//   /// **Update Profile Picture**
//   static Future<void> updateProfilePicture(String uid, String imageUrl) async {
//     await _firestore.collection("users").doc(uid).update({
//       "profile_picture": imageUrl,
//     });
//   }

//   /// **Change Password**
//   static Future<void> updatePassword(String newPassword) async {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       await user.updatePassword(newPassword);
//     }
//   }

//   /// **Change Username**
//   static Future<void> updateUsername(String uid, String newUsername) async {
//     await _firestore.collection("users").doc(uid).update({
//       "username": newUsername,
//     });
//   }

//   /// **Logout**
//   static Future<void> logout() async {
//     await _auth.signOut();
//   }
// }
