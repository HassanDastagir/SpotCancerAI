import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/admin_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.textLight,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Logo
                Image.asset(
                  "assets/SpotCancerAI.png",
                  height: 150,
                  width: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),

                // 🔹 User Button
                _buildGradientButton(
                  context,
                  "User",
                  [AppColors.primary, AppColors.secondary],
                  '/login_user',
                ),
                const SizedBox(height: 15),

                // 🔹 Admin Button
                _buildGradientButton(
                  context,
                  "Admin",
                  [AppColors.danger, Colors.redAccent],
                  '/login_admin',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Gradient Button Widget
  Widget _buildGradientButton(
      BuildContext context, String role, List<Color> colors, String route) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            role, // "User" or "Admin"
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
