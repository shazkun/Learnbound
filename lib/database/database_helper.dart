import 'dart:core';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart'; // Import for join function
import 'package:path_provider/path_provider.dart'; // Required for getApplicationDocumentsDirectory

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the path to the phone's Downloads folder
    final directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path,
        'user_database.db'); // Appending 'Download' subdirectory

    return await openDatabase(
      path,
      version: 2, // Increment version number
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT,
          email TEXT UNIQUE,
          password TEXT,
          profile_picture TEXT,
          points INTEGER DEFAULT 0
        )
      ''');
      },
    );
  }

  Future<int?> getUserIdByEmailAndPassword(
      String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['id'], // Specify the columns to return
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int; // Return the user ID
    }
    return null; // Return null if no user found
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<String?> getProfilePicture(int uid) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['profile_picture'],
      where: 'id = ?',
      whereArgs: [uid],
    );
    if (result.isNotEmpty) {
      return result.first['profile_picture'] as String;
    }
    return null;
  }

  Future<String?> getUsername(int uid) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['username'],
      where: 'id = ?',
      whereArgs: [uid],
    );
    if (result.isNotEmpty) {
      return result.first['username'] as String;
    }
    return null;
  }

  Future<String?> getPassword(int uid) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['password'],
      where: 'id = ?',
      whereArgs: [uid],
    );
    if (result.isNotEmpty) {
      return result.first['password'] as String;
    }
    return null;
  }

  Future<void> updatePassword(String email, String newPassword) async {
    final db = await database;
    await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<void> changePasswordDb(
      int uid, String currentPassword, String newPassword) async {
    final db = await database;
    final pass = await getPassword(uid);
    if (currentPassword == pass) {
      await db.update(
        'users',
        {'password': newPassword},
        where: 'id = ?',
        whereArgs: [uid],
      );
    } else {
      print('password does not match');
    }
  }

  Future<void> changeUsername(
      int uid, String newUsername) async {
    final db = await database;
  
      await db.update(
        'users',
        {'username': newUsername},
        where: 'id = ?',
        whereArgs: [uid],
      );
  }

  void updateProfilePicture(int uid, String imagePath) async {
    final db = await database;
    await db.update(
      'users',
      {'profile_picture': imagePath},
      where: 'id = ?',
      whereArgs: [uid],
    );
  }
}
