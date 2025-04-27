import 'package:learnbound/database/helper/sqlite_helper.dart';
import 'package:flutter/material.dart';
import 'package:learnbound/util/encryption.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  User? get user => _user;

  /// **Login**
  Future<bool> loginUser(String email, String password) async {
    final hashedPassword = hashPassword(password);
    final userId =
        await _dbHelper.getUserIdByEmailAndPassword(email, hashedPassword);
    if (userId != null) {
      _user = await _dbHelper.getUser(email);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// **Register user (Ignore if Exists)**
  Future<void> registerUser(User user) async {
    user.password = hashPassword(user.password);
    await _dbHelper.insertUser(user);
    _user = user;
    notifyListeners();
  }

  Future<bool> isEmailRegistered(String email) async {
    return await _dbHelper.isEmailRegistered(email);
  }

  /// **Logout**
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }

  /// **Update Profile Picture**
  Future<bool> updateProfilePicture(String imagePath) async {
    if (_user != null) {
      await _dbHelper.updateProfilePicture(_user!.id!, imagePath);
      _user!.profilePicture = imagePath;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// **Check if User is Logged In**
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    notifyListeners();
    return prefs.getBool('isLoggedIn') ??
        false; // Returns true/false based on stored value
  }

  /// **Change Password**
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    if (_user != null) {
      final currentHashed = hashPassword(currentPassword);
      if (_user!.password == currentHashed) {
        final newHashed = hashPassword(newPassword);
        await _dbHelper.updatePassword(_user!.id!, newHashed);
        _user!.password = newHashed;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  /// **Change Username**
  Future<void> changeUsername(String newUsername) async {
    if (_user != null) {
      await _dbHelper.updateUsername(_user!.id!, newUsername);
      _user!.username = newUsername;
      notifyListeners();
    }
  }
}
