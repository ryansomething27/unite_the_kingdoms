// lib/services/analytics_dashboard_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsDashboardService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic> _dashboardData = {};
  DateTime _lastUpdate = DateTime.now();
  
  Map<String, dynamic> get dashboardData => _dashboardData;
  DateTime get lastUpdate => _lastUpdate;

  Future<void> updateDashboard() async {
    if (kDebugMode) return; // Only run in production
    
    try {
      final data = await Future.wait([
        _getPlayerMetrics(),
        _getGameplayMetrics(),
        _getMonetizationMetrics(),
        _getPerformanceMetrics(),
        _getABTestMetrics(),
      ]);

      _dashboardData = {
        'playerMetrics': data[0],
        'gameplayMetrics': data[1],
        'monetizationMetrics': data[2],
        'performanceMetrics': data[3],
        'abTestMetrics': data[4],
        'lastUpdate': DateTime.now().toIso8601String(),
      };

      _lastUpdate = DateTime.now();
      notifyListeners();

      // Save to Firestore for developer dashboard
      await _firestore.collection('analyticsDashboard').doc('current').set(_dashboardData);
    } catch (e) {
      debugPrint('Error updating analytics dashboard: $e');
    }
  }

  Future<Map<String, dynamic>> _getPlayerMetrics() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final lastWeek = now.subtract(const Duration(days: 7));
    final lastMonth = now.subtract(const Duration(days: 30));

    // Daily Active Users
    final dauQuery = await _firestore
        .collection('userSessions')
        .where('timestamp', isGreaterThan: yesterday)
        .get();

    // Weekly Active Users
    final wauQuery = await _firestore
        .collection('userSessions')
        .where('timestamp', isGreaterThan: lastWeek)
        .get();

    // Monthly Active Users
    final mauQuery = await _firestore
        .collection('userSessions')
        .where('timestamp', isGreaterThan: lastMonth)
        .get();

    // New Users Today
    final newUsersQuery = await _firestore
        .collection('users')
        .where('createdAt', isGreaterThan: yesterday)
        .get();

    // Retention Rates
    final retentionData = await _calculateRetentionRates();

    return {
      'dau': dauQuery.docs.length,
      'wau': wauQuery.docs.length,
      'mau': mauQuery.docs.length,
      'newUsers': newUsersQuery.docs.length,
      'retention': retentionData,
    };
  }

  Future<Map<String, dynamic>> _getGameplayMetrics() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Level completion rates
    final levelStarts = await _firestore
        .collection('gameEvents')
        .where('eventName', isEqualTo: 'level_start')
        .where('timestamp', isGreaterThan: yesterday)
        .get();

    final levelCompletions = await _firestore
        .collection('gameEvents')
        .where('eventName', isEqualTo: 'level_complete')
        .where('timestamp', isGreaterThan: yesterday)
        .get();

    // Faction distribution
    final factionQuery = await _firestore
        .collection('gameStates')
        .get();

    final factionDistribution = <String, int>{};
    for (final doc in factionQuery.docs) {
      final faction = doc.data()['playerFaction'] as String?;
      if (faction != null) {
        factionDistribution[faction] = (factionDistribution[faction] ?? 0) + 1;
      }
    }

    // Average session length
    final sessionData = await _calculateAverageSessionLength();

    // Tower usage statistics
    final towerUsage = await _getTowerUsageStats();

    return {
      'levelStartsToday': levelStarts.docs.length,
      'levelCompletionsToday': levelCompletions.docs.length,
      'completionRate': levelStarts.docs.isNotEmpty 
          ? levelCompletions.docs.length / levelStarts.docs.length 
          : 0,
      'factionDistribution': factionDistribution,
      'averageSessionLength': sessionData,
      'towerUsage': towerUsage,
    };
  }

  Future<Map<String, dynamic>> _getMonetizationMetrics() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Ad revenue
    final adEvents = await _firestore
        .collection('gameEvents')
        .where('eventName', isEqualTo: 'ad_watched')
        .where('timestamp', isGreaterThan: yesterday)
        .get();

    // Purchase events
    final purchases = await _firestore
        .collection('gameEvents')
        .where('eventName', isEqualTo: 'purchase_complete')
        .where('timestamp', isGreaterThan: yesterday)
        .get();

    double totalRevenue = 0;
    for (final purchase in purchases.docs) {
      totalRevenue += purchase.data()['price'] ?? 0;
    }

    // Conversion rates
    final conversionData = await _calculateConversionRates();

    return {
      'adsWatchedToday': adEvents.docs.length,
      'purchasesToday': purchases.docs.length,
      'revenueToday': totalRevenue,
      'conversionRates': conversionData,
    };
  }

  Future<Map<String, dynamic>> _getPerformanceMetrics() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Error rates
    final errors = await _firestore
        .collection('gameEvents')
        .where('eventName', isEqualTo: 'app_error')
        .where('timestamp', isGreaterThan: yesterday)
        .get();

    // Performance issues
    final performanceIssues = await _firestore
        .collection('gameEvents')
        .where('eventName', isEqualTo: 'performance_issue')
        .where('timestamp', isGreaterThan: yesterday)
        .get();

    // Average frame rate data
    final frameRateData = await _getAverageFrameRate();

    return {
      'errorsToday': errors.docs.length,
      'performanceIssues': performanceIssues.docs.length,
      'averageFrameRate': frameRateData,
      'crashRate': await _calculateCrashRate(),
    };
  }

  Future<Map<String, dynamic>> _getABTestMetrics() async {
    final activeTests = await _firestore
        .collection('abTests')
        .where('isActive', isEqualTo: true)
        .get();

    final testResults = <String, Map<String, dynamic>>{};

    for (final test in activeTests.docs) {
      final testId = test.id;
      final events = await _firestore
          .collection('abTestEvents')
          .where('testId', isEqualTo: testId)
          .get();

      final variantStats = <String, Map<String, int>>{};
      for (final event in events.docs) {
        final variant = event.data()['variant'] as String;
        final eventName = event.data()['eventName'] as String;
        
        variantStats[variant] = variantStats[variant] ?? {};
        variantStats[variant]![eventName] = (variantStats[variant]![eventName] ?? 0) + 1;
      }

      testResults[testId] = {
        'name': test.data()['name'],
        'variantStats': variantStats,
      };
    }

    return testResults;
  }

  Future<Map<String, double>> _calculateRetentionRates() async {
    // Calculate D1, D7, D30 retention rates
    final now = DateTime.now();
    
    final retention = <String, double>{};
    for (final days in [1, 7, 30]) {
      final cohortDate = now.subtract(Duration(days: days));
      final newUsers = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThan: cohortDate.subtract(const Duration(days: 1)))
          .where('createdAt', isLessThan: cohortDate)
          .get();

      if (newUsers.docs.isEmpty) {
        retention['D$days'] = 0.0;
        continue;
      }

      int activeUsers = 0;
      for (final user in newUsers.docs) {
        final sessions = await _firestore
            .collection('userSessions')
            .where('userId', isEqualTo: user.id)
            .where('timestamp', isGreaterThan: now.subtract(const Duration(days: 1)))
            .get();

        if (sessions.docs.isNotEmpty) {
          activeUsers++;
        }
      }

      retention['D$days'] = activeUsers / newUsers.docs.length;
    }

    return retention;
  }

  Future<double> _calculateAverageSessionLength() async {
    final sessions = await _firestore
        .collection('userSessions')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
        .get();

    if (sessions.docs.isEmpty) return 0.0;

    double totalDuration = 0;
    for (final session in sessions.docs) {
      final duration = session.data()['duration'] ?? 0;
      totalDuration += duration;
    }

    return totalDuration / sessions.docs.length;
  }

  Future<Map<String, int>> _getTowerUsageStats() async {
    final towerEvents = await _firestore
        .collection('gameEvents')
        .where('eventName', isEqualTo: 'tower_placed')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
        .get();

    final usage = <String, int>{};
    for (final event in towerEvents.docs) {
      final towerType = event.data()['tower_type'] as String;
      final tier = event.data()['tier'] as String;
      final key = '${towerType}_$tier';
      usage[key] = (usage[key] ?? 0) + 1;
    }

    return usage;
  }

  Future<Map<String, double>> _calculateConversionRates() async {
    final allUsers = await _firestore.collection('users').count().get();
    final purchaseUsers = await _firestore
        .collection('gameEvents')
        .where('eventName', isEqualTo: 'purchase_complete')
        .get();

    final uniquePurchasers = purchaseUsers.docs.map((doc) => doc.data()['userId']).toSet();

    return {
      'overallConversion': uniquePurchasers.length / (allUsers.count ?? 1),
      'adToSilver': await _calculateAdConversion(),
    };
  }

  Future<double> _calculateAdConversion() async {
    final adViews = await _firestore
        .collection('gameEvents')
        .where('eventName', isEqualTo: 'ad_watched')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
        .get();

    final sessions = await _firestore
        .collection('userSessions')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
        .get();

    if (sessions.docs.isEmpty) return 0.0;
    return adViews.docs.length / sessions.docs.length;
  }

  Future<double> _getAverageFrameRate() async {
    final performanceEvents = await _firestore
        .collection('gameEvents')
        .where('eventName', isEqualTo: 'performance_metrics')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 1)))
        .get();

    if (performanceEvents.docs.isEmpty) return 60.0;

    double totalFrameRate = 0;
    for (final event in performanceEvents.docs) {
      totalFrameRate += event.data()['frameRate'] ?? 60.0;
    }

    return totalFrameRate / performanceEvents.docs.length;
  }

  Future<double> _calculateCrashRate() async {
    final crashes = await _firestore
        .collection('gameEvents')
        .where('eventName', isEqualTo: 'app_error')
        .where('fatal', isEqualTo: true)
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 1)))
        .get();

    final sessions = await _firestore
        .collection('userSessions')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 1)))
        .get();

    if (sessions.docs.isEmpty) return 0.0;
    return crashes.docs.length / sessions.docs.length;
  }

  Map<String, dynamic> generateInsights() {
    if (_dashboardData.isEmpty) return {};

    final insights = <String, dynamic>{};
    
    // Player insights
    final playerMetrics = _dashboardData['playerMetrics'] as Map<String, dynamic>?;
    if (playerMetrics != null) {
      final retention = playerMetrics['retention'] as Map<String, double>?;
      if (retention != null) {
        if (retention['D1'] != null && retention['D1']! < 0.4) {
          insights['lowRetention'] = 'Day 1 retention is below 40%. Consider improving onboarding.';
        }
        if (retention['D7'] != null && retention['D7']! > 0.2) {
          insights['goodWeeklyRetention'] = 'Strong weekly retention indicates good core gameplay.';
        }
      }
    }

    // Gameplay insights
    final gameplayMetrics = _dashboardData['gameplayMetrics'] as Map<String, dynamic>?;
    if (gameplayMetrics != null) {
      final completionRate = gameplayMetrics['completionRate'] as double?;
      if (completionRate != null && completionRate < 0.7) {
        insights['lowCompletion'] = 'Level completion rate is low. Consider adjusting difficulty.';
      }
    }

    // Performance insights
    final performanceMetrics = _dashboardData['performanceMetrics'] as Map<String, dynamic>?;
    if (performanceMetrics != null) {
      final avgFrameRate = performanceMetrics['averageFrameRate'] as double?;
      if (avgFrameRate != null && avgFrameRate < 45) {
        insights['performanceIssue'] = 'Average frame rate is below 45 FPS. Optimization needed.';
      }
    }

    return insights;
  }
}