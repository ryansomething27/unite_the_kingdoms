// lib/models/game_models.dart
import 'dart:math';

enum Faction { saxons, danes }
enum UnitTier { tier1, tier2, tier3 }
enum TowerType { spawn, archer }

class Unit {
  final String id;
  final String name;
  final UnitTier tier;
  final Faction faction;
  final int strength;
  final double speed;
  final String description;

  Unit({
    required this.id,
    required this.name,
    required this.tier,
    required this.faction,
    required this.strength,
    required this.speed,
    required this.description,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      name: json['name'],
      tier: UnitTier.values[json['tier'] - 1],
      faction: Faction.values.firstWhere((f) => f.name == json['faction']),
      strength: json['strength'],
      speed: json['speed'].toDouble(),
      description: json['description'],
    );
  }
}

class Tower {
  final String id;
  final TowerType type;
  final UnitTier? tier;
  final Faction faction;
  final int cost;
  final int lifeline;
  final int maxTargets;
  final double spawnRate;
  final double? range;
  final int? damage;
  final double? accuracy;
  final double? fireRate;
  Point<double> position;
  List<String> targetTowerIds;
  bool isPlayerControlled;

  Tower({
    required this.id,
    required this.type,
    this.tier,
    required this.faction,
    required this.cost,
    required this.lifeline,
    required this.maxTargets,
    required this.spawnRate,
    this.range,
    this.damage,
    this.accuracy,
    this.fireRate,
    required this.position,
    this.targetTowerIds = const [],
    this.isPlayerControlled = false,
  });

  Tower copyWith({
    String? id,
    TowerType? type,
    UnitTier? tier,
    Faction? faction,
    int? cost,
    int? lifeline,
    int? maxTargets,
    double? spawnRate,
    double? range,
    int? damage,
    double? accuracy,
    double? fireRate,
    Point<double>? position,
    List<String>? targetTowerIds,
    bool? isPlayerControlled,
  }) {
    return Tower(
      id: id ?? this.id,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      faction: faction ?? this.faction,
      cost: cost ?? this.cost,
      lifeline: lifeline ?? this.lifeline,
      maxTargets: maxTargets ?? this.maxTargets,
      spawnRate: spawnRate ?? this.spawnRate,
      range: range ?? this.range,
      damage: damage ?? this.damage,
      accuracy: accuracy ?? this.accuracy,
      fireRate: fireRate ?? this.fireRate,
      position: position ?? this.position,
      targetTowerIds: targetTowerIds ?? this.targetTowerIds,
      isPlayerControlled: isPlayerControlled ?? this.isPlayerControlled,
    );
  }
}

class Wall {
  final String id;
  final List<Point<double>> points;
  final int cost;

  Wall({
    required this.id,
    required this.points,
    required this.cost,
  });
}

class MapSection {
  final String id;
  final String name;
  final String kingdom;
  final bool isCastle;
  final List<Tower> towers;
  final int startingSilver;
  final String description;
  final Map<String, dynamic> objectives;

  MapSection({
    required this.id,
    required this.name,
    required this.kingdom,
    required this.isCastle,
    required this.towers,
    required this.startingSilver,
    required this.description,
    required this.objectives,
  });

  factory MapSection.fromJson(Map<String, dynamic> json) {
    return MapSection(
      id: json['id'],
      name: json['name'],
      kingdom: json['kingdom'],
      isCastle: json['isCastle'] ?? false,
      towers: (json['towers'] as List)
          .map((t) => Tower(
                id: t['id'],
                type: TowerType.values.firstWhere((type) => type.name == t['type']),
                tier: t['tier'] != null ? UnitTier.values[t['tier'] - 1] : null,
                faction: Faction.values.firstWhere((f) => f.name == t['faction']),
                cost: t['cost'],
                lifeline: t['lifeline'],
                maxTargets: t['maxTargets'],
                spawnRate: t['spawnRate'].toDouble(),
                range: t['range']?.toDouble(),
                damage: t['damage'],
                accuracy: t['accuracy']?.toDouble(),
                fireRate: t['fireRate']?.toDouble(),
                position: Point(t['position']['x'].toDouble(), t['position']['y'].toDouble()),
                isPlayerControlled: t['isPlayerControlled'] ?? false,
              ))
          .toList(),
      startingSilver: json['startingSilver'],
      description: json['description'],
      objectives: json['objectives'],
    );
  }
}

class GameState {
  final String playerId;
  final Faction playerFaction;
  final int currentSection;
  final int silver;
  final Set<String> conqueredSections;
  final Map<String, int> kingdomProgress;
  final bool hasRemoveAds;

  GameState({
    required this.playerId,
    required this.playerFaction,
    required this.currentSection,
    required this.silver,
    required this.conqueredSections,
    required this.kingdomProgress,
    this.hasRemoveAds = false,
  });

  GameState copyWith({
    String? playerId,
    Faction? playerFaction,
    int? currentSection,
    int? silver,
    Set<String>? conqueredSections,
    Map<String, int>? kingdomProgress,
    bool? hasRemoveAds,
  }) {
    return GameState(
      playerId: playerId ?? this.playerId,
      playerFaction: playerFaction ?? this.playerFaction,
      currentSection: currentSection ?? this.currentSection,
      silver: silver ?? this.silver,
      conqueredSections: conqueredSections ?? this.conqueredSections,
      kingdomProgress: kingdomProgress ?? this.kingdomProgress,
      hasRemoveAds: hasRemoveAds ?? this.hasRemoveAds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerFaction': playerFaction.name,
      'currentSection': currentSection,
      'silver': silver,
      'conqueredSections': conqueredSections.toList(),
      'kingdomProgress': kingdomProgress,
      'hasRemoveAds': hasRemoveAds,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      playerId: json['playerId'],
      playerFaction: Faction.values.firstWhere((f) => f.name == json['playerFaction']),
      currentSection: json['currentSection'],
      silver: json['silver'],
      conqueredSections: Set<String>.from(json['conqueredSections']),
      kingdomProgress: Map<String, int>.from(json['kingdomProgress']),
      hasRemoveAds: json['hasRemoveAds'] ?? false,
    );
  }
}

class CombatUnit {
  final String id;
  final Unit unit;
  Point<double> position;
  final String? targetTowerId;
  final bool isPlayerControlled;
  int health;
  double animationOffset;

  CombatUnit({
    required this.id,
    required this.unit,
    required this.position,
    this.targetTowerId,
    required this.isPlayerControlled,
    required this.health,
    this.animationOffset = 0,
  });
}

class BattleResult {
  final bool victory;
  final int silverEarned;
  final int unitsLost;
  final int enemiesDefeated;
  final Duration battleDuration;

  BattleResult({
    required this.victory,
    required this.silverEarned,
    required this.unitsLost,
    required this.enemiesDefeated,
    required this.battleDuration,
  });
}