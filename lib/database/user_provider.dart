import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  User? get user => _user;

  /// **Login**
  Future<bool> loginUser(String email, String password) async {
    final userId = await _dbHelper.getUserIdByEmailAndPassword(email, password);
    if (userId != null) {
      _user = await _dbHelper.getUser(email);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// **Register user (Ignore if Exists)**
  Future<void> registerUser(User user) async {
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
  Future<void> updateProfilePicture(String imagePath) async {
    if (_user != null) {
      await _dbHelper.updateProfilePicture(_user!.id!, imagePath);
      _user!.profilePicture = imagePath;
      notifyListeners();
    }
  }

  /// **Change Password**
  Future<void> changePassword(String newPassword) async {
    if (_user != null) {
      await _dbHelper.updatePassword(_user!.id!, newPassword);
      _user!.password = newPassword;
      notifyListeners();
    }
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
