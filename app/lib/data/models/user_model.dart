class User {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'avatar_url': avatarUrl,
    'created_at': createdAt?.toIso8601String(),
  };
}
