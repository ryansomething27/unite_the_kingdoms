// lib/services/config_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/game_models.dart';
import 'dart:math' as math;

class ConfigService extends ChangeNotifier {
  static Map<String, Unit>? _units;
  static Map<String, dynamic>? _towerStats;
  static List<MapSection>? _mapSections;
  static Map<String, dynamic>? _costs;

  static Future<Map<String, Unit>> loadUnits() async {
    if (_units != null) return _units!;

    try {
      final jsonString = await rootBundle.loadString('assets/config/unit_stats.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      
      _units = {};
      for (final entry in jsonData.entries) {
        _units![entry.key] = Unit.fromJson(entry.value);
      }
      
      return _units!;
    } catch (e) {
      debugPrint('Error loading units: $e');
      return _generateDefaultUnits();
    }
  }

  static Future<Map<String, dynamic>> loadTowerStats() async {
    if (_towerStats != null) return _towerStats!;

    try {
      final jsonString = await rootBundle.loadString('assets/config/tower_stats.json');
      _towerStats = json.decode(jsonString) as Map<String, dynamic>;
      return _towerStats!;
    } catch (e) {
      debugPrint('Error loading tower stats: $e');
      return _generateDefaultTowerStats();
    }
  }

  static Future<List<MapSection>> loadMapSections() async {
    if (_mapSections != null) return _mapSections!;

    try {
      final jsonString = await rootBundle.loadString('assets/config/map_sections.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      
      _mapSections = [];
      for (final sectionData in jsonData['sections']) {
        _mapSections!.add(MapSection.fromJson(sectionData));
      }
      
      return _mapSections!;
    } catch (e) {
      debugPrint('Error loading map sections: $e');
      return _generateDefaultMapSections();
    }
  }

  static Future<Map<String, dynamic>> loadCosts() async {
    if (_costs != null) return _costs!;

    try {
      final jsonString = await rootBundle.loadString('assets/config/costs.json');
      _costs = json.decode(jsonString) as Map<String, dynamic>;
      return _costs!;
    } catch (e) {
      debugPrint('Error loading costs: $e');
      return _generateDefaultCosts();
    }
  }

  static Map<String, Unit> _generateDefaultUnits() {
    return {
      'saxon_fyrd': Unit(
        id: 'saxon_fyrd',
        name: 'Fyrd',
        tier: UnitTier.tier1,
        faction: Faction.saxons,
        strength: 1,
        speed: 1.0,
        description: 'Peasants with spears',
      ),
      'saxon_militia': Unit(
        id: 'saxon_militia',
        name: 'Militia',
        tier: UnitTier.tier2,
        faction: Faction.saxons,
        strength: 2,
        speed: 1.2,
        description: 'Guards with short swords',
      ),
      'saxon_royal_guard': Unit(
        id: 'saxon_royal_guard',
        name: 'Royal Guard',
        tier: UnitTier.tier3,
        faction: Faction.saxons,
        strength: 3,
        speed: 1.5,
        description: 'Elite swordsmen and axemen',
      ),
      'dane_raiders': Unit(
        id: 'dane_raiders',
        name: 'Raiders',
        tier: UnitTier.tier1,
        faction: Faction.danes,
        strength: 1,
        speed: 1.1,
        description: 'Aggressive looters',
      ),
      'dane_outlaws': Unit(
        id: 'dane_outlaws',
        name: 'Heathen Outlaws',
        tier: UnitTier.tier2,
        faction: Faction.danes,
        strength: 2,
        speed: 1.3,
        description: 'Veteran mercenaries',
      ),
      'dane_blood_warriors': Unit(
        id: 'dane_blood_warriors',
        name: 'Blood Warriors',
        tier: UnitTier.tier3,
        faction: Faction.danes,
        strength: 3,
        speed: 1.4,
        description: 'Fanatical berserkers',
      ),
    };
  }

  static Map<String, dynamic> _generateDefaultTowerStats() {
    return {
      'spawn_towers': {
        'tier1': {'cost': 5, 'lifeline': 10, 'maxTargets': 1, 'spawnRate': 2.0},
        'tier2': {'cost': 10, 'lifeline': 20, 'maxTargets': 2, 'spawnRate': 1.5},
        'tier3': {'cost': 15, 'lifeline': 30, 'maxTargets': 3, 'spawnRate': 1.0},
      },
      'archer_towers': {
        'tier1': {'cost': 8, 'range': 100, 'damage': 1, 'accuracy': 0.7, 'fireRate': 1.5},
        'tier2': {'cost': 12, 'range': 120, 'damage': 2, 'accuracy': 0.8, 'fireRate': 1.2},
        'tier3': {'cost': 18, 'range': 150, 'damage': 3, 'accuracy': 0.9, 'fireRate': 1.0},
      },
    };
  }

  static List<MapSection> _generateDefaultMapSections() {
    return List.generate(100, (index) {
      final kingdom = ['wessex', 'mercia', 'eastAnglia', 'northumbria'][index ~/ 25];
      final isLastInKingdom = (index + 1) % 25 == 0;
      
      return MapSection(
        id: 'section_$index',
        name: isLastInKingdom ? '$kingdom Castle' : '$kingdom Section ${(index % 25) + 1}',
        kingdom: kingdom,
        isCastle: isLastInKingdom,
        towers: _generateDefaultTowers(3 + (index ~/ 10)),
        startingSilver: 30 + (index ~/ 5),
        description: isLastInKingdom 
            ? 'The final stronghold of $kingdom. Defeat the castle to claim the kingdom!'
            : 'A strategic position in $kingdom territory.',
        objectives: {
          'primary': 'Capture all enemy towers',
          'secondary': 'Complete within 10 minutes',
        },
      );
    });
  }

  static List<Tower> _generateDefaultTowers(int count) {
    final towers = <Tower>[];
    for (int i = 0; i < count; i++) {
      towers.add(Tower(
        id: 'tower_$i',
        type: TowerType.spawn,
        tier: UnitTier.values[i % 3],
        faction: i == 0 ? Faction.saxons : Faction.danes,
        cost: 5 + (i % 3) * 5,
        lifeline: 10 + (i % 3) * 10,
        maxTargets: 1 + (i % 3),
        spawnRate: 2.0 - (i % 3) * 0.5,
        position: math.Point(50.0 + i * 100, 50.0 + (i % 2) * 100),
        isPlayerControlled: i == 0,
      ));
    }
    return towers;
  }

  static Map<String, dynamic> _generateDefaultCosts() {
    return {
      'towers': {
        'spawn': {'tier1': 5, 'tier2': 10, 'tier3': 15},
        'archer': {'tier1': 8, 'tier2': 12, 'tier3': 18},
      },
      'walls': {'perUnit': 1},
      'monetization': {
        'removeAds': 299, // cents
        'silverReward': 10,
      },
    };
  }
}