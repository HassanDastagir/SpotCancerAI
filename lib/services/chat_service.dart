import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/chat.dart';

class ChatService {
  static const String baseUrl = AppConstants.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get chat messages with pagination
  Future<List<ChatMessage>> getMessages({int page = 1, int limit = 50}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/messages?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> messagesJson = data['messages'] ?? [];
          return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
        }
      }
      
      throw Exception('Failed to load messages: ${response.statusCode}');
    } catch (e) {
      print('Error fetching messages: $e');
      throw Exception('Failed to load messages: $e');
    }
  }

  // Send a new message
  Future<ChatMessage> sendMessage(String message) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/send'),
        headers: headers,
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ChatMessage.fromJson(data['data']);
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send message');
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Get recent messages (for real-time updates)
  Future<List<ChatMessage>> getRecentMessages({DateTime? since}) async {
    try {
      final headers = await _getHeaders();
      String url = '$baseUrl/chat/recent';
      
      if (since != null) {
        url += '?since=${since.toIso8601String()}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> messagesJson = data['messages'] ?? [];
          return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching recent messages: $e');
      return [];
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/chat/message/$messageId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      
      return false;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  // Get chat statistics
  Future<ChatStats?> getChatStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ChatStats.fromJson(data);
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching chat stats: $e');
      return null;
    }
  }

  // Get current user info for message ownership
  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      if (userJson != null) {
        final userData = json.decode(userJson);
        return userData['_id'] ?? userData['id'];
      }
      return null;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  Future<String?> getCurrentUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      if (userJson != null) {
        final userData = json.decode(userJson);
        return userData['username'];
      }
      return null;
    } catch (e) {
      print('Error getting current username: $e');
      return null;
    }
  }

  // Check if a message belongs to current user
  Future<bool> isMyMessage(ChatMessage message) async {
    final currentUserId = await getCurrentUserId();
    return currentUserId != null && message.senderId == currentUserId;
  }
}