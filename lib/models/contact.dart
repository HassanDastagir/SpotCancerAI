class Contact {
  final String id;
  final String userId;
  final String subject;
  final String message;
  final String status;
  final String priority;
  final AdminReply? adminReply;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user; // For admin view

  Contact({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    this.adminReply,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['_id'] ?? '',
      userId: json['userId'] is String ? json['userId'] : json['userId']['_id'] ?? '',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      adminReply: json['adminReply'] != null && json['adminReply']['message'] != null
          ? AdminReply.fromJson(json['adminReply'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      user: json['userId'] is Map<String, dynamic> 
          ? User.fromJson(json['userId'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'subject': subject,
      'message': message,
      'status': status,
      'priority': priority,
      'adminReply': adminReply?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Unknown';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      default:
        return 'Medium';
    }
  }

  bool get hasReply => adminReply != null && adminReply!.message.isNotEmpty;
}

class AdminReply {
  final String message;
  final String? repliedBy;
  final DateTime? repliedAt;
  final User? admin; // For displaying admin info

  AdminReply({
    required this.message,
    this.repliedBy,
    this.repliedAt,
    this.admin,
  });

  factory AdminReply.fromJson(Map<String, dynamic> json) {
    return AdminReply(
      message: json['message'] ?? '',
      repliedBy: json['repliedBy'] is String ? json['repliedBy'] : json['repliedBy']?['_id'],
      repliedAt: json['repliedAt'] != null 
          ? DateTime.parse(json['repliedAt'])
          : null,
      admin: json['repliedBy'] is Map<String, dynamic>
          ? User.fromJson(json['repliedBy'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'repliedBy': repliedBy,
      'repliedAt': repliedAt?.toIso8601String(),
    };
  }
}

class User {
  final String id;
  final String username;
  final String email;

  User({
    required this.id,
    required this.username,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
    };
  }
}