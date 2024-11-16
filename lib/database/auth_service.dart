// auth_service.dart

import 'package:image_picker/image_picker.dart';

import 'database_helper.dart';
final DatabaseHelper _dbHelper = DatabaseHelper();
class AuthService {
 
  String? _profilePicturePath;

  Future<bool> register(String username, String email, String password,
      String profilepath) async {
    try {
      // Check if the email is already registered
      final existingUser = await _dbHelper.getUser(email);
      if (existingUser != null) {
        return false; // Email already exists
      }

      await _dbHelper.insertUser({
        'username': username,
        'email': email,
        'password': password,
        'profile_picture': profilepath
      });
      return true;
    } catch (e) {
      print("Error during registration: $e");
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await _dbHelper.getUser(email);
      if (user != null) {
        // Hash the provided password
        if (user['password'] == password) {
          return true; // Successful login
        } else {
          return false; // Incorrect password
        }
      } else {
        return false; // User not found
      }
    } catch (e) {
      print("Error during login: $e");
      return false; // Indicate a failed login
    }
  }

  Future<bool> resetPassword(String email, String newPassword) async {
    final user = await _dbHelper.getUser(email);
    if (user != null) {
      await _dbHelper.updatePassword(email, newPassword);
      return true;
    }
    return false;
  }

  Future<void> updateProfilePicture(int uid, String imagePath) async {
    _dbHelper.updateProfilePicture(uid, imagePath);
  }

  Future<void> changeProfilePicture(int uid) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _profilePicturePath = pickedFile.path;
      _dbHelper.updateProfilePicture(uid, pickedFile.path);
      // Here, you would typically upload the image to your backend
      // and update the user's profile picture URL in your database
    }
  }

  String? get profilePicturePath => _profilePicturePath;

  Future<Map<String, dynamic>?> getUser(String email) async {
    return await _dbHelper.getUser(email);
  }

  Future<void> changePassword(int id,
      String currentPassword, String newPassword) async {
    if (currentPassword.isNotEmpty && newPassword.isNotEmpty) {
      _dbHelper.changePasswordDb(id, currentPassword, newPassword);
      
    } else {
      throw Exception("Passwords cannot be empty");
    }
  
  }

  Future<void> logout() async {
    // Placeholder for actual logout logic
    // Here, you would typically clear the user's session data
    print("User logged out.");
    await Future.delayed(Duration(seconds: 1)); // Simulate logout process
  }
}
