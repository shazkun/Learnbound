import 'dart:async';
import 'package:Learnbound/models/user.dart' as AppUser;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider with ChangeNotifier {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  AppUser.User? _user; // Store the user data fetched from Supabase.

  AppUser.User? get user => _user;

  /// **Listen to Auth State Changes**
  UserProvider() {
    // Listen for authentication state changes (login/logout).
    _supabaseClient.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        // User is logged in
        fetchUserData(
            session.user.id); // No need for ! since session is non-null
      } else {
        // User is logged out
        _user = null;
        notifyListeners();
      }
    });
  }

  /// **Register User**
  Future<bool> registerUser(
      String username, String email, String password, String pathImg) async {
    try {
      // Register in Supabase Authentication
      final response = await _supabaseClient.auth.signUp(
        password: password, // Updated syntax: password first
        email: email,
      );

      if (response.user == null) {
        print("Error registering user: No user returned");
        return false;
      }

      // After successful registration, insert user data into Supabase.
      final user = response.user!;
      final uid = user.id;
      final insertResponse = await _supabaseClient.from('users').insert({
        'uid': uid,
        'username': username,
        'email': email,
        'profile_picture': pathImg,
      });

      if (insertResponse.error != null) {
        print("Error inserting user data: ${insertResponse.error?.message}");
        return false;
      }

      // Fetch and update user provider
      await fetchUserData(uid);
      return true;
    } catch (e) {
      print("Error during registration: $e");
      return false;
    }
  }

  /// **Login User**
  Future<bool> loginUser(String email, String password) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print("Error logging in user: No user returned");
        return false;
      }

      // After successful login, fetch user data
      final uid = response.user!.id;
      await fetchUserData(uid);
      return true;
    } catch (e) {
      print("Error during login: $e");
      return false;
    }
  }

  /// **Fetch User Data**
  Future<void> fetchUserData(String uid) async {
    try {
      final response =
          await _supabaseClient.from('users').select().eq('uid', uid).single();

      // Populate the user data from the response
      _user = AppUser.User.fromMap(response);
      notifyListeners();
    } catch (e) {
      print("Error during fetching user data: $e");
    }
  }

  /// **Update Profile Picture**
  Future<void> updateProfilePicture(String imageUrl) async {
    if (_user == null) return;

    try {
      final response = await _supabaseClient
          .from('users')
          .update({'profile_picture': imageUrl}).eq('uid', _user!.uid);

      if (response.error != null) {
        print("Error updating profile picture: ${response.error?.message}");
        return;
      }

      // Update the user profile picture in the provider
      _user = AppUser.User(
        uid: _user!.uid,
        username: _user!.username,
        email: _user!.email,
        profilePicture: imageUrl,
      );
      notifyListeners();
    } catch (e) {
      print("Error updating profile picture: $e");
    }
  }

  /// **Logout**
  Future<void> logout() async {
    await _supabaseClient.auth.signOut();
    _user = null;
    notifyListeners();
  }

  /// **Change Username**
  Future<bool> changeUsername(String newUsername) async {
    if (_user == null) return false;

    try {
      final response = await _supabaseClient
          .from('users')
          .update({'username': newUsername}).eq('uid', _user!.uid);

      if (response.error != null) {
        print("Error changing username: ${response.error?.message}");
        return false;
      }

      // Update username in the provider
      _user = AppUser.User(
        uid: _user!.uid,
        username: newUsername,
        email: _user!.email,
        profilePicture: _user!.profilePicture,
      );
      notifyListeners();
      return true;
    } catch (e) {
      print("Error changing username: $e");
      return false;
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('email')
          .eq('email', email);

      // response is a List<Map<String, dynamic>> if data exists, empty otherwise
      return response.isNotEmpty; // Returns true if the email exists
    } catch (e) {
      print("Error checking email registration: $e");
      return false; // Assume false on error to avoid blocking registration
    }
  }
}
