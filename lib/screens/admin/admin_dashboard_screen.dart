import 'package:flutter/material.dart';
import 'package:spotcancerai/services/auth_service.dart';
import 'package:spotcancerai/services/contact_service.dart';
import 'package:spotcancerai/screens/admin/user_management_screen.dart';
import 'package:spotcancerai/screens/admin/contact_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ContactService _contactService = ContactService();
  late TabController _tabController;
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _analysisResults = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load dashboard data, users, and contact messages simultaneously
      final dashboardResult = await _authService.getAdminDashboard();
      final usersResult = await _authService.getAllUsers();
      final messagesResult = await _contactService.getRecentMessages(limit: 5);
      
      if (dashboardResult['success']) {
        setState(() {
          _dashboardData = dashboardResult['data'];
        });
      }
      
      if (usersResult['success']) {
        setState(() {
          _users = (usersResult['users'] as List).map((user) => {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'status': user.isActive ? (user.role == 'admin' ? 'Admin' : 'Active') : 'Inactive',
            'isActive': user.isActive,
            'role': user.role,
            'isSuspended': user.isSuspended ?? false,
          }).toList();
        });
      } else {
        // Fallback to mock data if API fails
        _loadMockData();
      }
      
      // Load real contact messages or fallback to mock
       if (messagesResult['success']) {
         setState(() {
           _messages = messagesResult['messages'] ?? [];
         });
       } else {
         // Fallback to mock messages if API fails
         _loadMockMessages();
       }
       
       // Load mock analysis data for now (can be updated later)
       if (_analysisResults.isEmpty) {
         _analysisResults = [
           // Add sample data here if needed
         ];
       }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadMockData(); // Load mock data if API fails
        _isLoading = false;
      });
    }
  }

  void _loadMockData() {
    // Mock user data (fallback)
    _users = [
      {
        'id': '1',
        'username': 'ali',
        'email': 'alisher3102@gmail.com',
        'status': 'Active',
        'isActive': true,
        'role': 'user',
        'isSuspended': false,
      },
      {
        'id': '2',
        'username': 'admin',
        'email': 'admin@spotcancerai.com',
        'status': 'Admin',
        'isActive': true,
        'role': 'admin',
        'isSuspended': false,
      },
    ];
    
    _loadMockMessages();
  }

  void _loadMockMessages() {
    // Mock messages data
    _messages = [
      {
        'title': 'Application Issue',
        'description': 'by Admin | Have a issue in image analyze',
        'timestamp': '2025-06-22 12:49:46',
      },
    ];
  }

  Future<void> _deleteUser(String userId, String username) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete user "$username"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final result = await _authService.deleteUser(userId);
        
        if (result['success']) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "$username" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Reload the user data
          _loadDashboardData();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'User Management'),
            Tab(text: 'Recent Messages'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildUserManagementTab(),
          _buildContactManagementTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildUserAccountsSection(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRecentMessagesSection(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecentAnalysisSection(),
        ],
      ),
    );
  }

  Widget _buildUserAccountsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.group, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'User Accounts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Username',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Email',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // User Rows
                ..._users.map((user) => _buildUserRow(user)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    final bool isAdmin = user['role'] == 'admin';
    final bool isSuspended = user['isSuspended'] ?? false;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(user['username']),
          ),
          Expanded(
            flex: 3,
            child: Text(user['email']),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(user['status'], isSuspended),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isSuspended ? 'Suspended' : user['status'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: isAdmin 
              ? const Text(
                  'Protected',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                )
              : ElevatedButton(
                  onPressed: () => _deleteUser(user['id'], user['username']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(60, 30),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, bool isSuspended) {
    if (isSuspended) return Colors.orange;
    switch (status.toLowerCase()) {
      case 'admin':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'live':
        return Colors.blue;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Widget _buildRecentMessagesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.message, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recent Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _messages.map((message) => _buildMessageItem(message)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message['title'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message['description'],
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message['timestamp'],
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAnalysisSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.analytics, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recent Analysis Results',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Result',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Confidence',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_analysisResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No analysis results available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ..._analysisResults.map((result) => _buildAnalysisRow(result)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(Map<String, dynamic> result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              result['user'] ?? '',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              result['date'] ?? '',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              result['result'] ?? '',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              result['confidence'] ?? '',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementTab() {
    return const UserManagementScreen();
  }

  Widget _buildContactManagementTab() {
    return const ContactManagementScreen();
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Text(
        'Analytics Tab\nComing Soon',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
      ),
    );
  }
}