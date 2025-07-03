// lib/services/game_balance_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameBalanceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic> _balanceData = {};
  final Map<String, double> _difficultyMultipliers = {};
  final Map<String, WinRateData> _winRates = {};
  
  Map<String, dynamic> get balanceData => _balanceData;
  Map<String, double> get difficultyMultipliers => _difficultyMultipliers;

  Future<void> initialize() async {
    await _loadBalanceData();
    await _calculateDifficultyMultipliers();
    await _analyzeWinRates();
  }

  Future<void> _loadBalanceData() async {
    try {
      final doc = await _firestore.collection('gameBalance').doc('current').get();
      if (doc.exists) {
        _balanceData = doc.data() ?? {};
      } else {
        _balanceData = _getDefaultBalance();
        await _saveBalanceData();
      }
    } catch (e) {
      debugPrint('Error loading balance data: $e');
      _balanceData = _getDefaultBalance();
    }
  }

  Future<void> _saveBalanceData() async {
    try {
      await _firestore.collection('gameBalance').doc('current').set(_balanceData);
    } catch (e) {
      debugPrint('Error saving balance data: $e');
    }
  }

  Map<String, dynamic> _getDefaultBalance() {
    return {
      'towerCosts': {
        'spawn_tier1': 5,
        'spawn_tier2': 10,
        'spawn_tier3': 15,
        'archer_tier1': 8,
        'archer_tier2': 12,
        'archer_tier3': 18,
      },
      'unitStats': {
        'saxon_fyrd': {'strength': 1, 'speed': 1.0},
        'saxon_militia': {'strength': 2, 'speed': 1.2},
        'saxon_royal_guard': {'strength': 3, 'speed': 1.5},
        'dane_raiders': {'strength': 1, 'speed': 1.1},
        'dane_outlaws': {'strength': 2, 'speed': 1.3},
        'dane_blood_warriors': {'strength': 3, 'speed': 1.4},
      },
      'economySettings': {
        'startingSilver': 30,
        'victoryBonus': 5,
        'wallCostPerUnit': 1,
      },
      'difficultyScaling': {
        'enemyHealthMultiplier': 1.0,
        'enemyDamageMultiplier': 1.0,
        'silverPenalty': 0.0,
      },
    };
  }

  Future<void> _calculateDifficultyMultipliers() async {
    try {
      // Analyze completion rates by level
      final completionData = await _firestore
          .collection('levelAnalytics')
          .get();

      for (final doc in completionData.docs) {
        final levelId = doc.id;
        final data = doc.data();
        final attempts = data['attempts'] ?? 1;
        final completions = data['completions'] ?? 0;
        final completionRate = completions / attempts;

        // Adjust difficulty based on completion rate
        double multiplier = 1.0;
        if (completionRate < 0.3) {
          multiplier = 0.8; // Make easier
        } else if (completionRate > 0.9) {
          multiplier = 1.2; // Make harder
        }

        _difficultyMultipliers[levelId] = multiplier;
      }
    } catch (e) {
      debugPrint('Error calculating difficulty multipliers: $e');
    }
  }

  Future<void> _analyzeWinRates() async {
    try {
      // Analyze win rates by faction and level
      final gameEvents = await _firestore
          .collection('gameEvents')
          .where('eventName', isEqualTo: 'level_complete')
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
          .get();

      final Map<String, Map<String, List<bool>>> factionResults = {};
      
      for (final event in gameEvents.docs) {
        final faction = event.data()['faction'] as String? ?? 'unknown';
        final levelId = event.data()['level_id'] as String? ?? 'unknown';
        final victory = event.data()['success'] as bool? ?? false;

        factionResults[faction] = factionResults[faction] ?? {};
        factionResults[faction]![levelId] = factionResults[faction]![levelId] ?? [];
        factionResults[faction]![levelId]!.add(victory);
      }

      // Calculate win rates
      for (final faction in factionResults.keys) {
        for (final levelId in factionResults[faction]!.keys) {
          final results = factionResults[faction]![levelId]!;
          final winRate = results.where((r) => r).length / results.length;
          
          _winRates['${faction}_$levelId'] = WinRateData(
            faction: faction,
            levelId: levelId,
            winRate: winRate,
            sampleSize: results.length,
          );
        }
      }
    } catch (e) {
      debugPrint('Error analyzing win rates: $e');
    }
  }

  // Dynamic balance adjustments
  int getAdjustedTowerCost(String towerType, String tier, String levelId) {
    final baseCost = _balanceData['towerCosts']['${towerType}_$tier'] ?? 10;
    final multiplier = _difficultyMultipliers[levelId] ?? 1.0;
    return (baseCost / multiplier).round();
  }

  Map<String, dynamic> getAdjustedUnitStats(String unitId, String levelId) {
    final baseStats = _balanceData['unitStats'][unitId] ?? {'strength': 1, 'speed': 1.0};
    final multiplier = _difficultyMultipliers[levelId] ?? 1.0;
    
    return {
      'strength': baseStats['strength'],
      'speed': (baseStats['speed'] as double) * multiplier,
    };
  }

  int getAdjustedStartingSilver(String levelId, String faction) {
    final baseSilver = _balanceData['economySettings']['startingSilver'] ?? 30;
    final levelMultiplier = _difficultyMultipliers[levelId] ?? 1.0;
    
    // Faction-specific adjustments
    double factionMultiplier = 1.0;
    final winRateKey = '${faction}_$levelId';
    if (_winRates.containsKey(winRateKey)) {
      final winRate = _winRates[winRateKey]!.winRate;
      if (winRate < 0.4) {
        factionMultiplier = 1.2; // Give more silver if struggling
      } else if (winRate > 0.8) {
        factionMultiplier = 0.9; // Give less silver if dominating
      }
    }
    
    return (baseSilver * levelMultiplier * factionMultiplier).round();
  }

  // Balance analysis and reporting
  Map<String, dynamic> generateBalanceReport() {
    final report = <String, dynamic>{};
    
    // Faction balance
    final factionWinRates = <String, double>{};
    for (final winRateData in _winRates.values) {
      if (factionWinRates.containsKey(winRateData.faction)) {
        factionWinRates[winRateData.faction] = 
            (factionWinRates[winRateData.faction]! + winRateData.winRate) / 2;
      } else {
        factionWinRates[winRateData.faction] = winRateData.winRate;
      }
    }
    
    report['factionBalance'] = factionWinRates;
    
    // Difficulty progression
    final difficultyProgression = <String, double>{};
    final sortedLevels = _difficultyMultipliers.keys.toList()..sort();
    for (final levelId in sortedLevels) {
      difficultyProgression[levelId] = _difficultyMultipliers[levelId]!;
    }
    
    report['difficultyProgression'] = difficultyProgression;
    
    // Recommendations
    final recommendations = <String>[];
    
    if (factionWinRates['saxons'] != null && factionWinRates['danes'] != null) {
      final saxonWinRate = factionWinRates['saxons']!;
      final daneWinRate = factionWinRates['danes']!;
      final difference = (saxonWinRate - daneWinRate).abs();
      
      if (difference > 0.1) {
        recommendations.add(
          'Faction imbalance detected: ${difference > 0 ? 'Saxons' : 'Danes'} '
          'have ${(difference * 100).toStringAsFixed(1)}% higher win rate'
        );
      }
    }
    
    // Check for difficulty spikes
    for (int i = 1; i < sortedLevels.length; i++) {
      final prevMultiplier = _difficultyMultipliers[sortedLevels[i-1]]!;
      final currMultiplier = _difficultyMultipliers[sortedLevels[i]]!;
      
      if (currMultiplier - prevMultiplier > 0.3) {
        recommendations.add(
          'Difficulty spike detected at level ${sortedLevels[i]}'
        );
      }
    }
    
    report['recommendations'] = recommendations;
    report['generatedAt'] = DateTime.now().toIso8601String();
    
    return report;
  }

  // Live balance updates
  Future<void> updateTowerCost(String towerType, String tier, int newCost) async {
    _balanceData['towerCosts']['${towerType}_$tier'] = newCost;
    await _saveBalanceData();
    notifyListeners();
  }

  Future<void> updateUnitStats(String unitId, Map<String, dynamic> newStats) async {
    _balanceData['unitStats'][unitId] = newStats;
    await _saveBalanceData();
    notifyListeners();
  }

  Future<void> updateEconomySetting(String setting, dynamic value) async {
    _balanceData['economySettings'][setting] = value;
    await _saveBalanceData();
    notifyListeners();
  }

  // A/B testing for balance
  Future<void> startBalanceTest(String testId, Map<String, dynamic> testConfig) async {
    try {
      await _firestore.collection('balanceTests').doc(testId).set({
        'config': testConfig,
        'startDate': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      debugPrint('Error starting balance test: $e');
    }
  }

  Future<void> endBalanceTest(String testId, bool applyChanges) async {
    try {
      final testDoc = await _firestore.collection('balanceTests').doc(testId).get();
      if (!testDoc.exists) return;

      if (applyChanges) {
        final testConfig = testDoc.data()!['config'] as Map<String, dynamic>;
        _balanceData.addAll(testConfig);
        await _saveBalanceData();
      }

      await _firestore.collection('balanceTests').doc(testId).update({
        'endDate': FieldValue.serverTimestamp(),
        'isActive': false,
        'applied': applyChanges,
      });
    } catch (e) {
      debugPrint('Error ending balance test: $e');
    }
  }
}

class WinRateData {
  final String faction;
  final String levelId;
  final double winRate;
  final int sampleSize;

  WinRateData({
    required this.faction,
    required this.levelId,
    required this.winRate,
    required this.sampleSize,
  });
}