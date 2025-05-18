import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/user.dart';

class DatabaseHelper {
  static const String _dbName = "users.db";
  static const String _userTable = "users";

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
      username TEXT,
      email TEXT UNIQUE,
      password TEXT,
      profile_picture TEXT,
      reset_code TEXT,
      reset_time INTEGER 
    )
  ''');
  }

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
      _userTable,
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query(_userTable);
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<User?> getUser(String email) async {
    final db = await database;
    final result = await db.query(
      _userTable,
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? User.fromMap(result.first) : null;
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    final existingUser = await getUser(user.email);
    if (existingUser == null) {
      await db.insert(_userTable, user.toMap());
    }
  }

  Future<void> updateProfilePicture(int userId, String imagePath) async {
    final db = await database;
    await db.update(
      _userTable,
      {'profile_picture': imagePath},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updatePassword(int userId, String newPassword) async {
    final db = await database;
    await db.update(
      _userTable,
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateUsername(int userId, String newUsername) async {
    final db = await database;
    await db.update(
      _userTable,
      {'username': newUsername},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

/////////////////////////////////
  ///
  ///
  ///
  ///
  Future<void> setResetCode(String email, String code) async {
    final db = await database;
    await db.update(
      _userTable,
      {'reset_code': code},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<bool> verifyResetCode(String email, String code) async {
    final db = await database;
    final result = await db.query(
      _userTable,
      where: 'email = ? AND reset_code = ?',
      whereArgs: [email, code],
    );
    return result.isNotEmpty;
  }

  Future<void> clearResetCode(String email) async {
    final db = await database;
    await db.update(
      _userTable,
      {'reset_code': null},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<int?> getResetTime(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['reset_time'],
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return result.first['reset_time'] as int?;
    }
    return null;
  }

  Future<void> setResetTime(String email, int timestamp) async {
    final db = await database;
    await db.update(
      'users',
      {'reset_time': timestamp},
      where: 'email = ?',
      whereArgs: [email],
    );
  }
}
