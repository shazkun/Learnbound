class User {
  int? id;
  String username;
  String email;
  String password;
  String? profilePicture;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    this.profilePicture,
  });

  // Convert User object to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'profile_picture': profilePicture,
    };
  }

  // Create a User object from a Map (SQLite)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      profilePicture: map['profile_picture'],
    );
  }

  // Convert User object to JSON for socket communication
  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'password': password,
        'profilePicture': profilePicture,
      };

  // Create a User object from JSON (socket communication)
  factory User.fromJson(Map<String, dynamic> json) => User(
      id: json['id'],
      username: json['username']?.toString() ?? 'Player ${json['id'] ?? 0}',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      profilePicture: json['profilePicture']);

  String get nickname => username; // Default to username if nickname not set
}
// class User {
//   String uid; // Firebase UID instead of local ID
//   String username;
//   String email;
//   String? profilePicture;

//   User({
//     required this.uid,
//     required this.username,
//     required this.email,
//     this.profilePicture,
//   });

//   /// **Convert User object to Map for Firestore**
//   Map<String, dynamic> toMap() {
//     return {
//       'uid': uid,
//       'username': username,
//       'email': email,
//       'profile_picture': profilePicture,
//     };
//   }

//   /// **Create User object from Firestore Map**
//   factory User.fromMap(Map<String, dynamic> map) {
//     return User(
//       uid: map['uid'],
//       username: map['username'],
//       email: map['email'],
//       profilePicture: map['profile_picture'],
//     );
//   }
// }
