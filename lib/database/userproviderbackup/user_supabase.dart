// import 'dart:async';
// import 'dart:io'; // For File handling
// import 'package:Learnbound/models/user.dart' as AppUser;
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';


// class UserProvider with ChangeNotifier {
//   final SupabaseClient _supabaseClient = Supabase.instance.client;
//   AppUser.User? _user;
//   final _userStreamController = StreamController<AppUser.User?>.broadcast();
//   RealtimeChannel? _subscription;

//   AppUser.User? get user => _user;
//   Stream<AppUser.User?> get userStream => _userStreamController.stream;

//   UserProvider() {
//     _initAuthListener();
//     _initStreamListener();
//   }

//   void _initAuthListener() {
//     _supabaseClient.auth.onAuthStateChange.listen((data) async {
//       final session = data.session;
//       if (session != null) {
//         await fetchUserData(session.user.id);
//         listenToUserChanges();
//       } else {
//         _clearUserState();
//       }
//     });
//   }

//   void _initStreamListener() {
//     _userStreamController.stream.listen((newUser) {
//       _user = newUser;
//       notifyListeners();
//     }, onError: (error) {
//       print("Stream error: $error");
//       _user = null;
//       notifyListeners();
//     });
//   }

//   Future<bool> registerUser(
//       String username, String email, String password, String? pathImg) async {
//     try {
//       final response = await _supabaseClient.auth.signUp(
//         password: password,
//         email: email,
//         data: {'username': username},
//       );

//       final user = response.user;
//       if (user == null) {
//         throw Exception("No user returned after sign-up");
//       }

//       String profilePictureUrl = "";

//       if (pathImg != null && pathImg.isNotEmpty) {
//         final file = File(pathImg);
//         final storagePath =
//             'profile_pictures/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
//         await _supabaseClient.storage.from('avatars').upload(storagePath, file);
//         profilePictureUrl =
//             _supabaseClient.storage.from('avatars').getPublicUrl(storagePath);
//       }

//       await _supabaseClient.from('users').insert({
//         'uid': user.id,
//         'username': username,
//         'email': email,
//         'profile_picture': profilePictureUrl,
//       });

//       await fetchUserData(user.id);
//       print("User successfully registered: $email");
//       return true;
//     } catch (e) {
//       print("Registration failed: $e");
//       if (e is AuthException && e.message.contains('User already registered')) {
//         print("Error: Email '$email' is already registered");
//         return false;
//       }
//       return false;
//     }
//   }

//   /// **Login User**
//   Future<bool> loginUser(String email, String password) async {
//     try {
//       final response = await _supabaseClient.auth.signInWithPassword(
//         email: email,
//         password: password,
//       );

//       final user = response.user;
//       if (user == null) {
//         throw Exception("No user returned after login");
//       }

//       await fetchUserData(user.id);
//       return true;
//     } catch (e) {
//       print("Login failed: $e");
//       return false;
//     }
//   }

//   /// **Fetch User Data**
//   Future<void> fetchUserData(String uid) async {
//     try {
//       final response = await _supabaseClient
//           .from('users')
//           .select()
//           .eq('uid', uid)
//           .maybeSingle();

//       if (response != null) {
//         final newUser = AppUser.User.fromMap(response);
//         _userStreamController.add(newUser);
//       } else {
//         _userStreamController.add(null);
//       }
//     } catch (e) {
//       print("Failed to fetch user data: $e");
//       _userStreamController.addError(e);
//     }
//   }

//   /// **Update Profile Picture**
//   Future<bool> updateProfilePicture(String imagePath) async {
//     if (_user == null) return false;

//     try {
//       // Step 1: Fetch the current profile picture URL
//       final userData = await _supabaseClient
//           .from('users')
//           .select('profile_picture')
//           .eq('uid', _user!.uid)
//           .single();

//       final currentProfileUrl = userData['profile_picture'] as String?;
//       String? currentStoragePath;

//       // Step 2: Convert public URL to storage path
//       if (currentProfileUrl != null && currentProfileUrl.isNotEmpty) {
//         final uri = Uri.parse(currentProfileUrl);
//         final segments = uri.pathSegments;
//         final index = segments.indexOf('avatars');
//         if (index != -1 && segments.length > index + 1) {
//           currentStoragePath = segments.sublist(index + 1).join('/');
//         }
//       }

//       String? profilePictureUrl;

//       if (imagePath.isEmpty) {
//         // Deletion request
//         if (currentStoragePath != null) {
//           await _supabaseClient.storage
//               .from('avatars')
//               .remove([currentStoragePath]);
//         }
//         profilePictureUrl = null; // Or a default image URL
//       } else {
//         // Upload new profile picture
//         final file = File(imagePath);
//         final newStoragePath =
//             'profile_pictures/${_user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
//         await _supabaseClient.storage
//             .from('avatars')
//             .upload(newStoragePath, file);
//         profilePictureUrl = _supabaseClient.storage
//             .from('avatars')
//             .getPublicUrl(newStoragePath);

//         // Optional: Remove old image if it exists
//         if (currentStoragePath != null) {
//           await _supabaseClient.storage
//               .from('avatars')
//               .remove([currentStoragePath]);
//         }
//       }

//       // Step 3: Update the user's profile picture in the database
//       await _supabaseClient
//           .from('users')
//           .update({'profile_picture': profilePictureUrl}).eq('uid', _user!.uid);

//       return true;
//     } catch (e) {
//       print("Failed to update/delete profile picture: $e");
//       return false;
//     }
//   }

//   /// **Reset Password**
//   Future<bool> resetPassword(String email) async {
//     try {
//       await _supabaseClient.auth.resetPasswordForEmail(
//         email,
//         redirectTo:
//             "myapp://reset-password", // Optional: Add redirect URL for web apps if needed
//       );
//       print("Password reset email sent to: $email");
//       return true;
//     } catch (e) {
//       print("Failed to send password reset email: $e");
//       return false;
//     }
//   }

//   /// **Logout**
//   Future<void> logout() async {
//     try {
//       await _supabaseClient.auth.signOut();
//       _clearUserState();
//     } catch (e) {
//       print("Logout failed: $e");
//     }
//   }

//   /// **Change Username**
//   Future<bool> changeUsername(String newUsername) async {
//     if (_user == null) return false;

//     try {
//       await _supabaseClient
//           .from('users')
//           .update({'username': newUsername}).eq('uid', _user!.uid);
//       return true;
//     } catch (e) {
//       print("Failed to change username: $e");
//       return false;
//     }
//   }

//   /// **Check if Email is Registered**
//   Future<bool> isEmailRegistered(String email) async {
//     try {
//       final response = await _supabaseClient
//           .from('users')
//           .select('email')
//           .eq('email', email)
//           .limit(1);
//       return response.isNotEmpty;
//     } catch (e) {
//       print("Failed to check email registration: $e");
//       return false;
//     }
//   }

//   /// **Change Password**
//   Future<bool> changePassword(
//       String currentPassword, String newPassword) async {
//     if (_user == null) {
//       print("No user logged in");
//       return false;
//     }

//     try {
//       await _supabaseClient.auth.signInWithPassword(
//         email: _user!.email,
//         password: currentPassword,
//       );

//       await _supabaseClient.auth.updateUser(
//         UserAttributes(password: newPassword),
//       );
//       return true;
//     } catch (e) {
//       print("Failed to change password: $e");
//       return false;
//     }
//   }

//   /// **Listen to User Changes**
//   void listenToUserChanges() {
//     final currentUser = _supabaseClient.auth.currentUser;
//     if (currentUser == null) {
//       print("No current user for real-time subscription");
//       return;
//     }

//     _cancelSubscription();
//     _subscription = _supabaseClient
//         .channel('users:${currentUser.id}')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: 'users',
//           filter: PostgresChangeFilter(
//             type: PostgresChangeFilterType.eq,
//             column: 'uid',
//             value: currentUser.id,
//           ),
//           callback: (payload) {
//             print("Real-time update: $payload");
//             if (payload.eventType == PostgresChangeEvent.delete) {
//               _userStreamController.add(null);
//             } else if (payload.newRecord.isNotEmpty) {
//               final newUser = AppUser.User.fromMap(payload.newRecord);
//               _userStreamController.add(newUser);
//             }
//           },
//         )
//         .subscribe((status, [error]) {
//       print(
//           "Subscription status: $status${error != null ? ' Error: $error' : ''}");
//     });
//   }

//   /// **Clear User State**
//   void _clearUserState() {
//     _user = null;
//     _userStreamController.add(null);
//     _cancelSubscription();
//     notifyListeners();
//   }

//   /// **Cancel Subscription**
//   void _cancelSubscription() {
//     if (_subscription != null) {
//       _supabaseClient.removeChannel(_subscription!);
//       _subscription = null;
//     }
//   }

//   @override
//   void dispose() {
//     _cancelSubscription();
//     _userStreamController.close();
//     super.dispose();
//   }
// }
