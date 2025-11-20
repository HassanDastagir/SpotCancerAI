import 'package:flutter/material.dart';
import 'dart:io';
import '../../constants/app_constants.dart';
import '../../models/scan_result.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResultScreen extends StatefulWidget {
  final String? imagePath;
  final Uint8List? imageBytes;

  const ResultScreen({
    super.key,
    this.imagePath,
    this.imageBytes,
  }) : assert(imagePath != null || imageBytes != null, 'Provide either imagePath or imageBytes');

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isAnalyzing = true;
  ScanResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      setState(() {
        _isAnalyzing = true;
        _error = null;
      });

      final Uri uri = Uri.parse('${AppConstants.baseUrl}/predict');

      final request = http.MultipartRequest('POST', uri);

      if (kIsWeb && widget.imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', widget.imageBytes!, filename: 'upload.png'),
        );
      } else if (widget.imagePath != null) {
        final file = File(widget.imagePath!);
        final bytes = await file.readAsBytes();
        final filename = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'upload.jpg';
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename),
        );
      } else {
        throw Exception('No image provided');
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        throw Exception('API ${streamed.statusCode}: $body');
      }
      final data = json.decode(body) as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Analysis failed');
      }

      final List<dynamic>? probsDyn = data['probabilities'];
      final List<dynamic>? labelsDyn = data['labels'];
      String prediction;
      double confidence;
      Map<String, dynamic>? additional;

      if (probsDyn != null && probsDyn.isNotEmpty) {
        final probs = probsDyn.map((e) => (e as num).toDouble()).toList();
        final labels = labelsDyn?.map((e) => e.toString()).toList();
        final int topIndex = (data['top_index'] ?? 0) as int;
        final String topLabel = (data['top_label'] ?? (labels != null && topIndex < labels.length ? labels[topIndex] : 'Unknown')).toString();
        prediction = topLabel;
        confidence = probs[topIndex];
        additional = {
          'probabilities': probs,
          'labels': labels,
        };
      } else {
        prediction = (data['label'] ?? 'Unknown').toString();
        confidence = (data['probability'] as num?)?.toDouble() ?? 0.0;
        additional = null;
      }

      final risk = _deriveRiskLevel(prediction, confidence);
      final recs = _defaultRecommendations(risk);

      setState(() {
        _isAnalyzing = false;
        _result = ScanResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'user123',
          imagePath: widget.imagePath ?? '',
          imageUrl: '',
          confidence: confidence,
          prediction: prediction,
          riskLevel: risk,
          recommendations: recs,
          scanDate: DateTime.now(),
          additionalData: additional,
        );
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = e.toString();
      });
    }
  }

  String _deriveRiskLevel(String prediction, double confidence) {
    final p = prediction.toLowerCase();
    if ((p.contains('melanoma') || p.contains('carcinoma')) && confidence >= 0.6) {
      return 'high';
    }
    if ((p.contains('actinic') || p.contains('keratosis')) && confidence >= 0.6) {
      return 'medium';
    }
    return confidence >= 0.8 ? 'medium' : 'low';
  }

  List<String> _defaultRecommendations(String risk) {
    switch (risk) {
      case 'high':
        return [
          'Consult a dermatologist urgently',
          'Avoid sun exposure and use high SPF sunscreen',
          'Monitor the lesion for changes and photograph regularly',
        ];
      case 'medium':
        return [
          'Schedule a dermatology appointment within 1–2 weeks',
          'Use sunscreen daily and avoid tanning',
          'Monitor the lesion for size, color, or border changes',
        ];
      default:
        return [
          'Continue regular skin monitoring',
          'Use sunscreen daily',
          'Consider routine dermatologist check-up',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Analysis Result',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isAnalyzing) {
      return _buildAnalyzingView();
    }

    if (_error != null) {
      return _buildErrorView();
    }

    return _buildResultView();
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image preview
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildPreviewImage(),
            ),
          ),
          const SizedBox(height: 40),
          
          // Loading animation
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(AppConstants.primaryColorValue),
            ),
          ),
          const SizedBox(height: 20),
          
          const Text(
            'Analyzing Image...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          
          Text(
            'Our AI is examining your image for potential skin abnormalities',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isAnalyzing = true;
                });
                _analyzeImage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColorValue),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry Analysis'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    if (_result == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and basic info
          Container(
            width: double.infinity,
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
              children: [
                // Image
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildPreviewImage(),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Result summary
                Text(
                  'Analysis Complete',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getRiskColor(_result!.riskLevelEnum),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Prediction: ${_result!.prediction}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Confidence and Risk Level
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  title: 'Confidence',
                  value: _result!.confidencePercentage,
                  icon: Icons.analytics,
                  color: const Color(AppConstants.primaryColorValue),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _InfoCard(
                  title: 'Risk Level',
                  value: _result!.riskLevelString,
                  icon: Icons.security,
                  color: _getRiskColor(_result!.riskLevelEnum),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildProbabilitiesView(),

          const SizedBox(height: 20),

          // Recommendations
          Container(
            width: double.infinity,
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
                const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Color(AppConstants.primaryColorValue),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Recommendations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ...(_result!.recommendations ?? []).map((recommendation) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 8, right: 10),
                          decoration: const BoxDecoration(
                            color: Color(AppConstants.primaryColorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Save result
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Result'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColorValue),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Share result
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(AppConstants.primaryColorValue),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Disclaimer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Important Disclaimer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'This analysis is for informational purposes only and should not replace professional medical advice. Please consult a dermatologist for proper diagnosis.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewImage() {
    if (widget.imageBytes != null) {
      return Image.memory(
        widget.imageBytes!,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(widget.imagePath ?? ''),
      fit: BoxFit.cover,
    );
  }

  Widget _buildProbabilitiesView() {
    final add = _result?.additionalData;
    final labels = (add?['labels'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? [];
    final probs = (add?['probabilities'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    if (labels.isEmpty || probs.isEmpty || labels.length != probs.length) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
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
          const Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: Color(AppConstants.primaryColorValue),
              ),
              SizedBox(width: 10),
              Text(
                'Class Probabilities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          for (int i = 0; i < labels.length; i++) ...[
            Text(
              '${labels[i]} — ${(probs[i] * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: probs[i].clamp(0.0, 1.0),
                minHeight: 10,
                color: const Color(AppConstants.primaryColorValue),
                backgroundColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
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
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}