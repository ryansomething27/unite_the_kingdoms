// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/config_service.dart';
import '../services/ads_service.dart';
import 'auth/login_screen.dart';
import 'main_menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load configurations
    await Future.wait([
      ConfigService.loadUnits(),
      ConfigService.loadTowerStats(),
      ConfigService.loadMapSections(),
      ConfigService.loadCosts(),
    ]);

    // Initialize ads
    context.read<AdsService>().initialize();

    // Wait for auth state
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final authService = context.read<AuthService>();
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => authService.isSignedIn 
              ? const MainMenuScreen()
              : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3E2723),
              Color(0xFF5D4037),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.castle,
                size: 120,
                color: Color(0xFFD4AF37),
              ),
              SizedBox(height: 24),
              Text(
                'Unite the Kingdoms',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                  fontFamily: 'Serif',
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Medieval Strategy & Tower Defense',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFF5E6D3),
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}