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
