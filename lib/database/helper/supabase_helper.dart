import 'dart:io'; // For File handling
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// **Register User**
  static Future<String?> registerUser(
      String email, String password, String username, String pathimg) async {
    try {
      // Register with Supabase Authentication
      final response = await _supabase.auth.signUp(
        password: password,
        email: email,
        data: {'username': username}, // Add user metadata
      );

      // Get the user object from the response
      final user = response.user;
      if (user == null) {
        print("Error: No user returned after sign-up");
        return null;
      }

      final uid = user.id; // Get UID from Supabase Auth

      // Upload profile picture to Supabase Storage
      final file = File(pathimg); // Assuming pathimg is a local file path
      final storagePath =
          'profile_pictures/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageResponse = await _supabase.storage
          .from('avatars') // Replace 'avatars' with your bucket name
          .upload(storagePath, file);

      // Get the public URL or file path
      final profilePictureUrl =
          _supabase.storage.from('avatars').getPublicUrl(storagePath);

      // Save user details in the 'users' table with the Storage URL
      try {
        await _supabase.from('users').insert({
          'uid': uid,
          'username': username,
          'email': email,
          'profile_picture': profilePictureUrl, // Store the URL
        });
      } catch (insertError) {
        print("Error inserting user data: $insertError");
        // Cleanup: Delete the auth user and uploaded file if table insert fails
        await _supabase.storage.from('avatars').remove([storagePath]);
        await _supabase.auth.admin.deleteUser(uid);
        return null;
      }

      return uid; // Return UID after successful registration
    } on PostgrestException catch (e) {
      if (e.code == '42P01') {
        print("Error: 'users' table does not exist in the database");
      } else if (e.code == '23505') {
        print("Error: Email '$email' is already registered");
      } else {
        print("Postgrest error during registration: $e");
      }
      return null;
    } on AuthException catch (e) {
      print("Authentication error: ${e.message}");
      return null;
    } catch (e) {
      print("Unexpected error in registerUser: $e");
      return null;
    }
  }

  /// **Login User**
  static Future<String?> loginUser(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response.user?.id; // Return UID if login is successful
    } catch (e) {
      print("Error in loginUser: $e");
      return null;
    }
  }

  /// **Get User Details**
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final response =
          await _supabase.from('users').select().eq('uid', uid).maybeSingle();

      return response; // Return user data (can be null if no record found)
    } catch (e) {
      print("Error in getUser: $e");
      return null;
    }
  }

  /// **Update Profile Picture**
  static Future<bool> updateProfilePicture(String uid, String imagePath) async {
    try {
      // Upload new profile picture to Supabase Storage
      final file = File(imagePath);
      final storagePath =
          'profile_pictures/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('avatars').upload(storagePath, file);

      // Get the public URL
      final profilePictureUrl =
          _supabase.storage.from('avatars').getPublicUrl(storagePath);

      // Update the 'users' table with the new URL
      await _supabase
          .from('users')
          .update({'profile_picture': profilePictureUrl}).eq('uid', uid);

      return true;
    } catch (e) {
      print("Error in updateProfilePicture: $e");
      return false;
    }
  }

  /// **Change Password**
  static Future<bool> updatePassword(String newPassword) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return true;
    } catch (e) {
      print("Error in updatePassword: $e");
      return false;
    }
  }

  /// **Change Username**
  static Future<bool> updateUsername(String uid, String newUsername) async {
    try {
      await _supabase
          .from('users')
          .update({'username': newUsername}).eq('uid', uid);

      return true;
    } catch (e) {
      print("Error in updateUsername: $e");
      return false;
    }
  }

  /// **Logout User**
  static Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print("Error in logout: $e");
    }
  }
}
