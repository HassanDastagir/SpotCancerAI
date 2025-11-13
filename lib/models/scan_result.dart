import '../constants/app_constants.dart';

class ScanResult {
  final String id;
  final String userId;
  final String imagePath;
  final String imageUrl;
  final double confidence;
  final String prediction;
  final String riskLevel;
  final List<String> recommendations;
  final DateTime scanDate;
  final Map<String, dynamic>? additionalData;

  ScanResult({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.imageUrl,
    required this.confidence,
    required this.prediction,
    required this.riskLevel,
    required this.recommendations,
    required this.scanDate,
    this.additionalData,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] ?? json['_id'],
      userId: json['userId'],
      imagePath: json['imagePath'],
      imageUrl: json['imageUrl'],
      confidence: json['confidence'].toDouble(),
      prediction: json['prediction'],
      riskLevel: json['riskLevel'],
      recommendations: List<String>.from(json['recommendations']),
      scanDate: DateTime.parse(json['scanDate']),
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'confidence': confidence,
      'prediction': prediction,
      'riskLevel': riskLevel,
      'recommendations': recommendations,
      'scanDate': scanDate.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
  
  String get riskLevelString {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return 'Low Risk';
      case 'medium':
        return 'Medium Risk';
      case 'high':
        return 'High Risk';
      default:
        return 'Unknown Risk';
    }
  }
  
  RiskLevel get riskLevelEnum => RiskLevelExtension.fromString(riskLevel);
  
  bool get isHighRisk => riskLevel.toLowerCase() == 'high';
  bool get isMediumRisk => riskLevel.toLowerCase() == 'medium';
  bool get isLowRisk => riskLevel.toLowerCase() == 'low';
}