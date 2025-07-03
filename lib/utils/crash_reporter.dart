// lib/utils/crash_reporter.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReporter {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  static Future<void> initialize() async {
    // Enable crashlytics collection
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    
    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        // In debug mode, use Flutter's default error handling
        FlutterError.presentError(details);
      } else {
        // In release mode, report to Crashlytics
        _crashlytics.recordFlutterFatalError(details);
      }
    };

    // Set up async error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      if (!kDebugMode) {
        _crashlytics.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }

  static Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  }) async {
    if (kDebugMode) {
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
      return;
    }

    await _crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      information: context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
    );
  }

  static Future<void> logMessage(String message) async {
    if (kDebugMode) {
      debugPrint('Crashlytics Log: $message');
      return;
    }

    await _crashlytics.log(message);
  }

  static Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  static Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  static Future<void> setGameContext({
    String? currentLevel,
    String? faction,
    int? silver,
    int? towersPlaced,
    String? gamePhase,
  }) async {
    if (currentLevel != null) await setCustomKey('current_level', currentLevel);
    if (faction != null) await setCustomKey('faction', faction);
    if (silver != null) await setCustomKey('silver', silver);
    if (towersPlaced != null) await setCustomKey('towers_placed', towersPlaced);
    if (gamePhase != null) await setCustomKey('game_phase', gamePhase);
  }
}