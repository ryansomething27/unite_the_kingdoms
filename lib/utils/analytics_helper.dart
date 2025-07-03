// lib/utils/analytics_helper.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsHelper {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = 
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Game Events
  static Future<void> logLevelStart(String levelId, String kingdom) async {
    await _analytics.logEvent(
      name: 'level_start',
      parameters: {
        'level_id': levelId,
        'kingdom': kingdom,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logLevelComplete(
    String levelId, 
    bool victory, 
    Duration duration,
    int silverEarned,
  ) async {
    await _analytics.logEvent(
      name: 'level_complete',
      parameters: {
        'level_id': levelId,
        'success': victory,
        'duration_seconds': duration.inSeconds,
        'silver_earned': silverEarned,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logTowerPlaced(String towerType, String tier, int cost) async {
    await _analytics.logEvent(
      name: 'tower_placed',
      parameters: {
        'tower_type': towerType,
        'tier': tier,
        'cost': cost,
      },
    );
  }

  static Future<void> logCombatStart(String levelId, int playerTowers, int enemyTowers) async {
    await _analytics.logEvent(
      name: 'combat_start',
      parameters: {
        'level_id': levelId,
        'player_towers': playerTowers,
        'enemy_towers': enemyTowers,
      },
    );
  }

  static Future<void> logAchievementUnlocked(String achievementId) async {
    await _analytics.logEvent(
      name: 'achievement_unlocked',
      parameters: {
        'achievement_id': achievementId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // User Behavior Events
  static Future<void> logFactionSelected(String faction) async {
    await _analytics.logEvent(
      name: 'faction_selected',
      parameters: {'faction': faction},
    );
  }

  static Future<void> logTutorialStep(int step, String action) async {
    await _analytics.logEvent(
      name: 'tutorial_progress',
      parameters: {
        'step': step,
        'action': action,
      },
    );
  }

  static Future<void> logSettingsChanged(String setting, dynamic value) async {
    await _analytics.logEvent(
      name: 'settings_changed',
      parameters: {
        'setting': setting,
        'value': value.toString(),
      },
    );
  }

  // Monetization Events
  static Future<void> logAdWatched(String adType, String placement) async {
    await _analytics.logEvent(
      name: 'ad_watched',
      parameters: {
        'ad_type': adType,
        'placement': placement,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logPurchaseAttempt(String productId, double price) async {
    await _analytics.logEvent(
      name: 'purchase_attempt',
      parameters: {
        'product_id': productId,
        'price': price,
        'currency': 'USD',
      },
    );
  }

  static Future<void> logPurchaseComplete(String productId, double price) async {
    await _analytics.logPurchase(
      value: price,
      currency: 'USD',
      parameters: {
        'product_id': productId,
      },
    );
  }

  // Performance Events
  static Future<void> logPerformanceIssue(String type, Map<String, dynamic> metrics) async {
    if (kDebugMode) return; // Don't log in debug mode
    
    await _analytics.logEvent(
      name: 'performance_issue',
      parameters: {
        'issue_type': type,
        ...metrics,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logError(String errorType, String description) async {
    if (kDebugMode) return; // Don't log in debug mode
    
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'description': description,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Custom Events
  static Future<void> logCustomEvent(String eventName, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: {
        ...parameters,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Set User Properties
  static Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  // Screen Tracking
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
}