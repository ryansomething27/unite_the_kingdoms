// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/game_service.dart';
import 'services/config_service.dart';
import 'services/ads_service.dart';
import 'services/achievements_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MobileAds.instance.initialize();
  runApp(const UniteKingdomsApp());
}

class UniteKingdomsApp extends StatelessWidget {
  const UniteKingdomsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => GameService()),
        ChangeNotifierProvider(create: (_) => ConfigService()),
        ChangeNotifierProvider(create: (_) => AdsService()),
        ChangeNotifierProvider(create: (_) => AchievementsService()),
      ],
      child: MaterialApp(
        title: 'Unite the Kingdoms',
        theme: AppTheme.medievalTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}