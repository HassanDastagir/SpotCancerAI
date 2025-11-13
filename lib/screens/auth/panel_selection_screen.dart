import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_constants.dart';
import 'login_screen.dart';
import 'admin_login_screen.dart';

class PanelSelectionScreen extends StatelessWidget {
  const PanelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Unified Card with Logo and Panel Selection
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 450),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Large Logo at the top of the unified card
                          Container(
                            width: 350,
                            height: 280,
                            margin: const EdgeInsets.only(bottom: 40),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(25.0),
                              child: SvgPicture.asset(
                                'assets/images/Untitled design.svg',
                                fit: BoxFit.contain,
                                width: 300,
                                height: 230,
                              ),
                            ),
                          ),
                          
                          const Text(
                            'Select Panel',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E3A59),
                            ),
                          ),
                          const SizedBox(height: 35),
                          
                          // User Panel Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                print('🔵 PanelSelection: User Panel button clicked');
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                                print('🔵 PanelSelection: Navigated to LoginScreen');
                              },
                              icon: const Icon(
                                Icons.person,
                                size: 26,
                              ),
                              label: const Text(
                                'User Panel',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(AppConstants.primaryColorValue),
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          
                          // Admin Panel Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                print('🔴 PanelSelection: Admin Panel button clicked');
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const AdminLoginScreen(),
                                  ),
                                );
                                print('🔴 PanelSelection: Navigated to AdminLoginScreen');
                              },
                              icon: const Icon(
                                Icons.admin_panel_settings,
                                size: 26,
                              ),
                              label: const Text(
                                'Admin Panel',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(AppConstants.errorColorValue),
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}