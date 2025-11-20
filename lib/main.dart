import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/panel_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/admin_login_screen.dart';

void main() {
  runApp(const SpotCancerAIApp());
}

class SpotCancerAIApp extends StatelessWidget {
  const SpotCancerAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpotCancerAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // 🔹 Initial screen
      home: const SplashScreen(),

      // 🔹 Named routes
      routes: {
        '/role_selection': (context) => RoleSelectionScreen(),
        '/login_user': (context) => const LoginScreen(userType: "User"),
        '/login_admin': (context) => const AdminLoginScreen(userType: "Admin"),
      },
    );
  }
}
