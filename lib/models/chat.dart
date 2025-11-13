class ChatMessage {
  final String id;
  final String message;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final DateTime timestamp;
  final bool isDeleted;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.timestamp,
    this.isDeleted = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      message: json['message'] ?? '',
      senderId: json['sender']['_id'] ?? '',
      senderName: json['sender']['username'] ?? json['senderName'] ?? '',
      senderEmail: json['sender']['email'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'message': message,
      'sender': {
        '_id': senderId,
        'username': senderName,
        'email': senderEmail,
      },
      'senderName': senderName,
      'timestamp': timestamp.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  bool get isMyMessage => false; // Will be set by the service based on current user

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get detailedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class ChatStats {
  final int totalMessages;
  final int todayMessages;
  final int activeUsers;

  ChatStats({
    required this.totalMessages,
    required this.todayMessages,
    required this.activeUsers,
  });

  factory ChatStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? {};
    return ChatStats(
      totalMessages: stats['totalMessages'] ?? 0,
      todayMessages: stats['todayMessages'] ?? 0,
      activeUsers: stats['activeUsers'] ?? 0,
    );
  }
}