import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/scan_result.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult> _scanHistory = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // Simulate loading from backend
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data - In real app, this would fetch from backend
    setState(() {
      _scanHistory = [
        ScanResult(
          id: '1',
          userId: 'user123',
          imagePath: '',
          imageUrl: 'https://example.com/image1.jpg',
          confidence: 0.92,
          prediction: 'Benign',
          riskLevel: 'low',
          recommendations: ['Continue monitoring', 'Use sunscreen'],
          scanDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ScanResult(
          id: '2',
          userId: 'user123',
          imagePath: '',
          imageUrl: 'https://example.com/image2.jpg',
          confidence: 0.78,
          prediction: 'Suspicious',
          riskLevel: 'medium',
          recommendations: ['Consult dermatologist', 'Monitor changes'],
          scanDate: DateTime.now().subtract(const Duration(days: 3)),
        ),
        ScanResult(
          id: '3',
          userId: 'user123',
          imagePath: '',
          imageUrl: 'https://example.com/image3.jpg',
          confidence: 0.85,
          prediction: 'Benign',
          riskLevel: 'low',
          recommendations: ['Regular check-ups', 'Skin protection'],
          scanDate: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];
      _isLoading = false;
    });
  }

  List<ScanResult> get _filteredHistory {
    if (_selectedFilter == 'All') return _scanHistory;
    
    return _scanHistory.where((result) {
      switch (_selectedFilter) {
        case 'Low Risk':
          return result.riskLevel == RiskLevel.low;
        case 'Medium Risk':
          return result.riskLevel == RiskLevel.medium;
        case 'High Risk':
          return result.riskLevel == RiskLevel.high;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Scan History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list, color: Colors.white),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppConstants.primaryColorValue),
          ),
        ),
      );
    }

    if (_scanHistory.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Filter chips
        if (_scanHistory.isNotEmpty) _buildFilterChips(),
        
        // Statistics card
        if (_scanHistory.isNotEmpty) _buildStatisticsCard(),
        
        // History list
        Expanded(
          child: _buildHistoryList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No Scan History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your scan results will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to camera
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take First Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryColorValue),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Low Risk', 'Medium Risk', 'High Risk'];
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: const Color(AppConstants.primaryColorValue).withOpacity(0.2),
              checkmarkColor: const Color(AppConstants.primaryColorValue),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final totalScans = _scanHistory.length;
    final lowRisk = _scanHistory.where((r) => r.riskLevel == RiskLevel.low).length;
    final mediumRisk = _scanHistory.where((r) => r.riskLevel == RiskLevel.medium).length;
    final highRisk = _scanHistory.where((r) => r.riskLevel == RiskLevel.high).length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total Scans',
                  value: totalScans.toString(),
                  color: const Color(AppConstants.primaryColorValue),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Low Risk',
                  value: lowRisk.toString(),
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Medium Risk',
                  value: mediumRisk.toString(),
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'High Risk',
                  value: highRisk.toString(),
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final filteredResults = _filteredHistory;
    
    if (filteredResults.isEmpty) {
      return Center(
        child: Text(
          'No results for selected filter',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final result = filteredResults[index];
        return _HistoryCard(
          result: result,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => HistoryDetailScreen(result: result),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'All',
            'Low Risk',
            'Medium Risk',
            'High Risk',
          ].map((filter) => RadioListTile<String>(
            title: Text(filter),
            value: filter,
            groupValue: _selectedFilter,
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
              });
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                
                // Result info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.prediction,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${result.confidencePercentage}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(result.scanDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Risk level indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRiskColor(result.riskLevelEnum).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.riskLevelString,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getRiskColor(result.riskLevelEnum),
                    ),
                  ),
                ),
                
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}