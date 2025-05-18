import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learnbound/database/helper/sqlite_helper.dart';
import 'package:learnbound/util/encryption.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
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

////////////////////////////////////////////////////////////////
  /// Generate a random 6-digit code
  String _generateResetCode() {
    // Generate a 6-digit code
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString();
  }

  Future<String?> loadEmail() async {
    String content = await rootBundle.loadString('googleapp.txt');
    List<String> lines = content.split('\n');

    for (var line in lines) {
      if (line.startsWith('email:')) {
        return line.split(':')[1].trim(); // return 'test'
      }
    }

    return null; // if not found
  }

  Future<String?> loadPass() async {
    String content = await rootBundle.loadString('googleapp.txt');
    List<String> lines = content.split('\n');

    for (var line in lines) {
      if (line.startsWith('pass:')) {
        return line.split(':')[1].trim(); // return 'test'
      }
    }

    return null; // if not found
  }

  /// Send reset code to email (you still need PHP/hosting to send the actual email)
  Future<String?> sendResetCode(String email) async {
    final isRegistered = await _dbHelper.isEmailRegistered(email);
    if (!isRegistered) return null;

    final int? lastResetTime = await _dbHelper.getResetTime(email);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastResetTime != null) {
      final diff = now - lastResetTime;
      const tenMinutes = 10 * 60 * 1000;

      if (diff < tenMinutes) {
        return 'cooldown'; // special value for cooldown
      }
    }

    // generate code and send email (same as before)
    final code = _generateResetCode();
    await _dbHelper.setResetCode(email, code);
    await _dbHelper.setResetTime(email, now);

    // 📧 SMTP Email send
    final String? username = await loadEmail();
    final String? password = await loadPass();

    final smtpServer = gmail(username!, password!);

    final message = Message()
      ..from = Address(username, 'Learnbound')
      ..recipients.add(email)
      ..subject = 'Password Reset Code'
      ..text = 'Your password reset code is: $code'
      ..html = '<p>Your password reset code is: <strong>$code</strong></p>';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
      notifyListeners();
      return code;
    } catch (e) {
      print('Error sending reset code: $e');
      return null;
    }
  }

  /// Verify reset code and update password
  Future<bool> resetPasswordWithCode(
      String email, String code, String newPassword) async {
    final isValid = await _dbHelper.verifyResetCode(email, code);
    if (!isValid) return false;

    final user = await _dbHelper.getUser(email);
    if (user != null) {
      final hashed = hashPassword(newPassword);
      await _dbHelper.updatePassword(user.id!, hashed);
      await _dbHelper.clearResetCode(email);
      return true;
    }

    return false;
  }
}
