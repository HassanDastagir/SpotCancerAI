class AppConstants {
  // API Configuration - point to backend during dev (Flutter web-server)
  static const String baseUrl = 'http://192.168.100.11:5000/api';
  static const String authEndpoint = '$baseUrl/auth';
  static const String imagesEndpoint = '$baseUrl/images';
  static const String scansEndpoint = '$baseUrl/scans';
  static const String profileEndpoint = '$baseUrl/profile';

  // App Configuration
  static const String appName = 'SpotCancerAI';
  static const String appVersion = '1.0.0';
  
  // Image Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  
  // Risk Levels
  static const String riskHigh = 'high';
  static const String riskMedium = 'medium';
  static const String riskLow = 'low';
  
  // Colors
  static const int primaryColorValue = 0xFF2196F3;
  static const int accentColorValue = 0xFF03DAC6;
  static const int errorColorValue = 0xFFB00020;
  static const int warningColorValue = 0xFFFF9800;
  static const int successColorValue = 0xFF4CAF50;
  
  // Brand Gradient (red → deep purple)
  static const int gradientStartColorValue = 0xFFD81B60; // Pink 600
  static const int gradientEndColorValue = 0xFF4A148C;   // Purple 900
  
  // Neutral background used behind cards
  static const int lightBackgroundColorValue = 0xFFF7F7F7;
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String settingsKey = 'app_settings';
}

// Risk Level Enum
enum RiskLevel {
  low,
  medium,
  high,
}

extension RiskLevelExtension on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
    }
  }
  
  String get value {
    switch (this) {
      case RiskLevel.low:
        return 'low';
      case RiskLevel.medium:
        return 'medium';
      case RiskLevel.high:
        return 'high';
    }
  }
  
  static RiskLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      default:
        return RiskLevel.low;
    }
  }
}