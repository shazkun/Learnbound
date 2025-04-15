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

  // Create a User object from a Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      profilePicture: map['profile_picture'],
    );
  }

  get nickname => null;
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
