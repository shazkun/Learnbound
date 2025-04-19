import 'dart:core';

import 'package:path/path.dart'; // Import for join function
import 'package:path_provider/path_provider.dart'; // Required for getApplicationDocumentsDirectory
import 'package:sqflite/sqflite.dart';

class SettingsDb {
  static final _instance = SettingsDb._internal();
  factory SettingsDb() => _instance;

  static Database? _database;

  SettingsDb._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'user_database.db');
    return await openDatabase(
      path,
      version: 2, // Increment version number
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE settings(
          mode TEXT DEFAULT 'Chat'
        )
        ''');
      },
    );
  }

  // Create or Update the mode setting
  Future<int> setMode(String mode) async {
    final db = await database;

    // Check if the mode exists, if so update it, otherwise insert it.
    var result = await db.query(
      'settings',
    );

    if (result.isEmpty) {
      // Insert new mode
      return await db.insert('settings', {'mode': mode});
    } else {
      // Update existing mode (since only one mode exists, it can be updated)
      return await db.update(
        'settings',
        {'mode': mode},
      );
    }
  }

  // Get the mode setting
  Future<String?> getMode() async {
    final db = await database;
    var result = await db.query(
      'settings',
    );

    if (result.isEmpty) {
      return null; // No mode found
    } else {
      return result.first['mode'] as String?;
    }
  }

  // Update the mode setting
  Future<int> updateMode(String mode) async {
    final db = await database;
    return await db.update(
      'settings',
      {'mode': mode},
    );
  }

  // Delete the mode setting
  Future<int> deleteMode() async {
    final db = await database;
    return await db.delete('settings');
  }
}
