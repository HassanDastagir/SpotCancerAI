class User {
  final String id;
  final String username;
  final String email;
  final String role;
  final DateTime createdAt;
  final String? profileImage;
  final bool isActive;
  final bool isSuspended;
  final DateTime? suspensionExpiry;
  final String? suspensionReason;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
    this.profileImage,
    this.isActive = true,
    this.isSuspended = false,
    this.suspensionExpiry,
    this.suspensionReason,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      username: json['username'],
      email: json['email'],
      role: json['role'] ?? 'user',
      createdAt: DateTime.parse(json['createdAt']),
      profileImage: json['profileImage'],
      isActive: json['isActive'] ?? true,
      isSuspended: json['isSuspended'] ?? false,
      suspensionExpiry: json['suspensionExpiry'] != null 
          ? DateTime.parse(json['suspensionExpiry']) 
          : null,
      suspensionReason: json['suspensionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'profileImage': profileImage,
      'isActive': isActive,
      'isSuspended': isSuspended,
      'suspensionExpiry': suspensionExpiry?.toIso8601String(),
      'suspensionReason': suspensionReason,
    };
  }
}