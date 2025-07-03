// lib/services/content_manager.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_models.dart';

class ContentUpdate {
  final String version;
  final Map<String, dynamic> unitUpdates;
  final Map<String, dynamic> towerUpdates;
  final Map<String, dynamic> costUpdates;
  final List<MapSection> newMapSections;
  final DateTime releaseDate;
  final bool isRequired;

  ContentUpdate({
    required this.version,
    required this.unitUpdates,
    required this.towerUpdates,
    required this.costUpdates,
    required this.newMapSections,
    required this.releaseDate,
    required this.isRequired,
  });

  factory ContentUpdate.fromJson(Map<String, dynamic> json) {
    return ContentUpdate(
      version: json['version'],
      unitUpdates: json['unitUpdates'] ?? {},
      towerUpdates: json['towerUpdates'] ?? {},
      costUpdates: json['costUpdates'] ?? {},
      newMapSections: (json['newMapSections'] as List? ?? [])
          .map((section) => MapSection.fromJson(section))
          .toList(),
      releaseDate: DateTime.fromMillisecondsSinceEpoch(json['releaseDate']),
      isRequired: json['isRequired'] ?? false,
    );
  }
}

class ContentManager extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _currentVersion = '1.0.0';
  ContentUpdate? _latestUpdate;
  bool _hasUpdates = false;
  
  String get currentVersion => _currentVersion;
  ContentUpdate? get latestUpdate => _latestUpdate;
  bool get hasUpdates => _hasUpdates;

  Future<void> checkForUpdates() async {
    try {
      final doc = await _firestore
          .collection('contentUpdates')
          .orderBy('releaseDate', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        final updateData = doc.docs.first.data();
        final update = ContentUpdate.fromJson(updateData);
        
        if (_isNewerVersion(update.version, _currentVersion)) {
          _latestUpdate = update;
          _hasUpdates = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error checking for content updates: $e');
    }
  }

  bool _isNewerVersion(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      if (v1Parts[i] > v2Parts[i]) return true;
      if (v1Parts[i] < v2Parts[i]) return false;
    }
    
    return false;
  }

  Future<bool> applyUpdate(ContentUpdate update) async {
    try {
      // In a real implementation, you would:
      // 1. Download new content files
      // 2. Update local JSON configurations
      // 3. Validate the changes
      // 4. Apply them to the game
      
      _currentVersion = update.version;
      _latestUpdate = null;
      _hasUpdates = false;
      
      // Save the new version
      await _saveCurrentVersion();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error applying content update: $e');
      return false;
    }
  }

  Future<void> _saveCurrentVersion() async {
    // Save to local storage
    // In a real implementation, you would use SharedPreferences
  }

  Future<void> scheduleUpdate(ContentUpdate update) async {
    // Schedule the update for later
    // This could involve downloading content in the background
    // and applying it when the app restarts
  }

  Map<String, dynamic> generateBalanceReport() {
    // Analyze current game balance and generate report
    // This would be used by developers to understand game balance
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'version': _currentVersion,
      'analysis': {
        'unitUsage': 'Unit usage statistics would go here',
        'towerEffectiveness': 'Tower effectiveness data',
        'economicBalance': 'Economic balance metrics',
        'playerProgression': 'Player progression analytics',
      },
      'recommendations': [
        'Suggested balance changes based on data',
      ],
    };
  }
}