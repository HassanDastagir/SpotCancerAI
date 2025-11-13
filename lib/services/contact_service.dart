import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import '../constants/app_constants.dart';

class ContactService {
  static const String baseUrl = AppConstants.baseUrl;

  // Get authentication token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Submit a new contact query
  Future<Map<String, dynamic>> submitQuery({
    required String subject,
    required String message,
    String priority = 'medium',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/contact/submit'),
        headers: headers,
        body: jsonEncode({
          'subject': subject,
          'message': message,
          'priority': priority,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Query submitted successfully',
          'contact': data['contact'] != null ? Contact.fromJson(data['contact']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit query',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user's contact queries
  Future<Map<String, dynamic>> getUserQueries({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();
      
      String url = '$baseUrl/contact/my-queries?page=$page&limit=$limit';
      if (status != null && status.isNotEmpty) {
        url += '&status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<Contact> contacts = (data['contacts'] as List)
            .map((contact) => Contact.fromJson(contact))
            .toList();

        return {
          'success': true,
          'contacts': contacts,
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch queries',
          'contacts': <Contact>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'contacts': <Contact>[],
      };
    }
  }

  // Get all contact queries (Admin only)
  Future<Map<String, dynamic>> getAllQueries({
    int page = 1,
    int limit = 10,
    String? status,
    String? priority,
  }) async {
    try {
      final headers = await _getHeaders();
      
      String url = '$baseUrl/contact/all?page=$page&limit=$limit';
      if (status != null && status.isNotEmpty) {
        url += '&status=$status';
      }
      if (priority != null && priority.isNotEmpty) {
        url += '&priority=$priority';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<Contact> contacts = (data['contacts'] as List)
            .map((contact) => Contact.fromJson(contact))
            .toList();

        return {
          'success': true,
          'contacts': contacts,
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch queries',
          'contacts': <Contact>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'contacts': <Contact>[],
      };
    }
  }

  // Update contact status (Admin only)
  Future<Map<String, dynamic>> updateStatus(String contactId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/contact/$contactId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Status updated successfully',
          'contact': data['contact'] != null ? Contact.fromJson(data['contact']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Reply to contact query (Admin only)
  Future<Map<String, dynamic>> replyToQuery(String contactId, String replyMessage) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/contact/$contactId/reply'),
        headers: headers,
        body: jsonEncode({'message': replyMessage}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Reply sent successfully',
          'contact': data['contact'] != null ? Contact.fromJson(data['contact']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send reply',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get contact statistics (Admin only)
  Future<Map<String, dynamic>> getContactStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/contact/stats'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'stats': data['stats'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch statistics',
          'stats': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'stats': null,
      };
    }
  }

  // Get recent contact messages for admin dashboard
  Future<Map<String, dynamic>> getRecentMessages({int limit = 5}) async {
    try {
      final headers = await _getHeaders();
      if (headers == null) {
        return {'success': false, 'error': 'Authentication required'};
      }

      // Use the existing /all endpoint with limit parameter
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/contact/all?limit=$limit&page=1'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Transform the contacts into the format expected by the admin dashboard
          final contacts = data['contacts'] as List;
          final messages = contacts.map((contact) {
            return {
              'title': contact['subject'] ?? 'No Subject',
              'description': 'by ${contact['userId']?['username'] ?? 'Unknown User'} | ${contact['message']?.substring(0, 50) ?? ''}${(contact['message']?.length ?? 0) > 50 ? '...' : ''}',
              'timestamp': _formatTimestamp(contact['createdAt']),
            };
          }).toList();
          
          return {
            'success': true,
            'messages': messages,
          };
        }
      }
      
      return {
        'success': false,
        'error': 'Failed to fetch recent messages: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Helper method to format timestamp
  String _formatTimestamp(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown date';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString; // Return original string if parsing fails
    }
  }
}