import 'package:sqflite/sqflite.dart';

class PointsManager {
  final Database database;

  PointsManager({required this.database});

  // Add points to a participant
  Future<void> addPoints(String participant, int points) async {
    // Update points in the database
    await database.rawUpdate(
      '''
      UPDATE users
      SET points = points + ?
      WHERE username = ?
      ''',
      [points, participant],
    );

    // Optionally, log the action as a message (if you have a messages table)
    await database.insert('messages', {
      'text': '$participant received $points points!',
      'nickname': 'System',
      'isImage': 0, // Assuming isImage is a boolean stored as an integer
    });
  }

  // Remove points from a participant
  Future<void> removePoints(String participant, int points) async {
    // Reduce points in the database and ensure it doesn't go below zero
    await database.rawUpdate(
      '''
      UPDATE users
      SET points = MAX(0, points - ?)
      WHERE username = ?
      ''',
      [points, participant],
    );

    // Optionally, log the action
    await database.insert('messages', {
      'text': '$participant lost $points points!',
      'nickname': 'System',
      'isImage': 0,
    });
  }

  // Reset points for all participants
  Future<void> resetPoints() async {
    // Set all participants' points to zero
    await database.rawUpdate(
      '''
      UPDATE users
      SET points = 0
      '''
    );

    // Optionally, log the reset
    await database.insert('messages', {
      'text': 'All points have been reset.',
      'nickname': 'System',
      'isImage': 0,
    });
  }
}
