// lib/services/achievements_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int silverReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.silverReward,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    int? silverReward,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      silverReward: silverReward ?? this.silverReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

class AchievementsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Achievement> _achievements = [];
  
  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => 
      _achievements.where((a) => a.isUnlocked).toList();

  Future<void> initialize() async {
    _achievements = _getDefaultAchievements();
    await _loadPlayerAchievements();
    notifyListeners();
  }

  List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(
        id: 'first_victory',
        title: 'First Blood',
        description: 'Win your first battle',
        icon: Icons.military_tech,
        silverReward: 10,
      ),
      Achievement(
        id: 'castle_conqueror',
        title: 'Castle Conqueror',
        description: 'Capture your first castle',
        icon: Icons.castle,
        silverReward: 25,
      ),
      Achievement(
        id: 'kingdom_uniter',
        title: 'Kingdom Uniter',
        description: 'Conquer an entire kingdom',
        icon: Icons.emoji_events,
        silverReward: 50,
      ),
      Achievement(
        id: 'silver_hoarder',
        title: 'Silver Hoarder',
        description: 'Accumulate 500 silver',
        icon: Icons.monetization_on,
        silverReward: 20,
      ),
      Achievement(
        id: 'tower_master',
        title: 'Tower Master',
        description: 'Place 100 towers across all battles',
        icon: Icons.add_business,
        silverReward: 30,
      ),
      Achievement(
        id: 'wall_builder',
        title: 'Wall Builder',
        description: 'Build 50 wall segments',
        icon: Icons.fence,
        silverReward: 15,
      ),
      Achievement(
        id: 'rapid_victory',
        title: 'Lightning Strike',
        description: 'Win a battle in under 2 minutes',
        icon: Icons.flash_on,
        silverReward: 25,
      ),
      Achievement(
        id: 'perfect_defense',
        title: 'Perfect Defense',
        description: 'Win without losing any towers',
        icon: Icons.shield,
        silverReward: 40,
      ),
    ];
  }

  Future<void> _loadPlayerAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('achievements')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final unlockedIds = Set<String>.from(data['unlocked'] ?? []);
        final unlockDates = Map<String, dynamic>.from(data['unlockDates'] ?? {});

        _achievements = _achievements.map((achievement) {
          final isUnlocked = unlockedIds.contains(achievement.id);
          final unlockDate = unlockDates[achievement.id] != null
              ? DateTime.fromMillisecondsSinceEpoch(unlockDates[achievement.id])
              : null;

          return achievement.copyWith(
            isUnlocked: isUnlocked,
            unlockedAt: unlockDate,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  Future<void> checkAchievement(String achievementId, {Map<String, dynamic>? context}) async {
    final achievement = _achievements.firstWhere((a) => a.id == achievementId);
    
    if (achievement.isUnlocked) return;

    bool shouldUnlock = false;

    switch (achievementId) {
      case 'first_victory':
        shouldUnlock = context?['victory'] == true;
        break;
      case 'castle_conqueror':
        shouldUnlock = context?['isCastle'] == true && context?['victory'] == true;
        break;
      case 'kingdom_uniter':
        shouldUnlock = context?['kingdomComplete'] == true;
        break;
      case 'silver_hoarder':
        shouldUnlock = (context?['silver'] ?? 0) >= 500;
        break;
      case 'tower_master':
        shouldUnlock = (context?['towersPlaced'] ?? 0) >= 100;
        break;
      case 'wall_builder':
        shouldUnlock = (context?['wallSegments'] ?? 0) >= 50;
        break;
      case 'rapid_victory':
        final duration = context?['battleDuration'] as Duration?;
        shouldUnlock = duration != null && duration.inMinutes < 2;
        break;
      case 'perfect_defense':
        shouldUnlock = context?['towersLost'] == 0 && context?['victory'] == true;
        break;
    }

    if (shouldUnlock) {
      await _unlockAchievement(achievementId);
    }
  }

  Future<void> _unlockAchievement(String achievementId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      
      await _firestore.collection('achievements').doc(user.uid).set({
        'unlocked': FieldValue.arrayUnion([achievementId]),
        'unlockDates': {
          achievementId: now.millisecondsSinceEpoch,
        },
      }, SetOptions(merge: true));

      // Update local state
      final index = _achievements.indexWhere((a) => a.id == achievementId);
      if (index != -1) {
        _achievements[index] = _achievements[index].copyWith(
          isUnlocked: true,
          unlockedAt: now,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }
}