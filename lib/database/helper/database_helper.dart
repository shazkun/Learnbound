import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/user.dart';

class DatabaseHelper {
  static const String _dbName = "users.db";
  static const String _userTable = "users";

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// **Initialize Database**
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE $_userTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE,
      email TEXT UNIQUE,
      password TEXT,
      profile_picture TEXT
    )
  ''');
  }

  /// **Get User by Email and Password (Login)**
  Future<int?> getUserIdByEmailAndPassword(
      String email, String password) async {
    final db = await database;
    final result = await db.query(
      _userTable,
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first['id'] as int : null;
  }

  Future<bool> isEmailRegistered(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }


  /// **Get User by Email**
  Future<User?> getUser(String email) async {
    final db = await database;
    final result = await db.query(
      _userTable,
      where: 'email = ?',
      whereArgs: [email],
    );

    return result.isNotEmpty ? User.fromMap(result.first) : null;
  }

  /// **Register User (Ignore if Exists)**
  Future<void> insertUser(User user) async {
    final db = await database;
    final existingUser = await getUser(user.email);

    if (existingUser == null) {
      await db.insert(_userTable, user.toMap());
    }
  }

  /// **Update Profile Picture**
  Future<void> updateProfilePicture(int userId, String imagePath) async {
    final db = await database;
    await db.update(
      _userTable,
      {'profile_picture': imagePath},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// **Change Password**
  Future<void> updatePassword(int userId, String newPassword) async {
    final db = await database;
    await db.update(
      _userTable,
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// **Change Username**
  Future<void> updateUsername(int userId, String newUsername) async {
    final db = await database;
    await db.update(
      _userTable,
      {'username': newUsername},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
