import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';

class AuthService {
  static const String _baseUrl = AppConstants.baseUrl;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.tokenKey);
    } catch (e) {
      return null;
    }
  }

  // Store token
  Future<bool> storeToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(AppConstants.tokenKey, token);
    } catch (e) {
      return false;
    }
  }

  // Clear stored data (logout)
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Register user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Store token and user data on successful registration
        final user = User.fromJson(data['user']);
        await storeToken(data['token']);
        await storeUser(user);
        return {
          'success': true,
          'token': data['token'],
          'user': user,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('DEBUG: Attempting login with email: $email');
      print('DEBUG: Using base URL: $_baseUrl');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');
      final isJson = (response.headers['content-type'] ?? '')
          .toLowerCase()
          .contains('application/json');
      Map<String, dynamic> data = {};
      if (isJson && response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (decodeError) {
          print('DEBUG: JSON decode failed: ${decodeError.toString()}');
        }
      }

      if (response.statusCode == 200) {
        // Store token and user data on successful login
        final user = User.fromJson(data['user']);
        await storeToken(data['token']);
        await storeUser(user);
        print('DEBUG: Login successful, user stored');
        return {
          'success': true,
          'token': data['token'],
          'user': user,
          'message': data['message'],
        };
      } else {
        final errorMsg = data['error'] ??
            (response.body.isEmpty
                ? 'Empty response from server (status ${response.statusCode})'
                : 'Login failed');
        print('DEBUG: Login failed with error: $errorMsg');
        return {
          'success': false,
          'error': errorMsg,
        };
      }
    } catch (e) {
      print('DEBUG: Network error during login: ${e.toString()}');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'statistics': data['statistics'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update profile
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found',
        };
      }

      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth.toIso8601String();
      if (preferences != null) body['preferences'] = preferences;

      final response = await http.put(
        Uri.parse('$_baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found',
        };
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/users/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get current user from stored data
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Store user data
  Future<bool> storeUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
    } catch (e) {
      return false;
    }
  }

  // Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      print('DEBUG: Checking if user is admin');
      final user = await getCurrentUser();
      print('DEBUG: Current user: ${user?.email}, isAdmin: ${user?.isAdmin}');
      return user?.isAdmin ?? false;
    } catch (e) {
      print('DEBUG: Error checking admin status: ${e.toString()}');
      return false;
    }
  }

  // Admin: Get dashboard data
  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch dashboard data',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Admin: Get all users
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'users': (data['users'] as List).map((user) => User.fromJson(user)).toList(),
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch users',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Admin: Delete user
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found',
        };
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to delete user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Admin: Suspend user
  Future<Map<String, dynamic>> suspendUser(String userId, {int days = 7, String? reason}) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found',
        };
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/admin/users/$userId/suspend'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'days': days,
          'reason': reason,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'suspensionExpiry': data['suspensionExpiry'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to suspend user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Admin: Unsuspend user
  Future<Map<String, dynamic>> unsuspendUser(String userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found',
        };
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/admin/users/$userId/unsuspend'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to unsuspend user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}