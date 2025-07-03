// lib/services/game_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/game_models.dart';
import 'config_service.dart';

class GameService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  GameState? _gameState;
  MapSection? _currentMapSection;
  final List<Tower> _placedTowers = [];
  final List<Wall> _placedWalls = [];
  final List<CombatUnit> _activeCombatUnits = [];
  bool _isInSetupPhase = true;
  bool _isInCombatPhase = false;
  Timer? _combatTimer;
  int _combatTickCount = 0;
  final Map<String, Unit> _loadedUnits = {};

  // Getters for game state properties
  GameState? get gameState => _gameState;
  MapSection? get currentMapSection => _currentMapSection;
  List<Tower> get placedTowers => _placedTowers;
  List<Wall> get placedWalls => _placedWalls;
  List<CombatUnit> get activeCombatUnits => _activeCombatUnits;
  bool get isInSetupPhase => _isInSetupPhase;
  bool get isInCombatPhase => _isInCombatPhase;

  Future<void> initializeGame() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('gameStates').doc(user.uid).get();
      
      if (doc.exists) {
        _gameState = GameState.fromJson(doc.data()!);
      } else {
        _gameState = GameState(
          playerId: user.uid,
          playerFaction: Faction.saxons,
          currentSection: 0,
          silver: 30,
          conqueredSections: {},
          kingdomProgress: {
            'wessex': 0,
            'mercia': 0,
            'eastAnglia': 0,
            'northumbria': 0,
          },
        );
        await saveGameState();
      }
      
      await loadCurrentMapSection();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing game: $e');
    }
  }

  Future<void> loadCurrentMapSection() async {
    if (_gameState == null) return;

    try {
      final sections = await ConfigService.loadMapSections();
      if (_gameState!.currentSection < sections.length) {
        _currentMapSection = sections[_gameState!.currentSection];
        _resetLevel();
      }
    } catch (e) {
      debugPrint('Error loading map section: $e');
    }
  }

  void _resetLevel() {
    _placedTowers.clear();
    _placedWalls.clear();
    _isInSetupPhase = true;
    _isInCombatPhase = false;
    notifyListeners();
  }

  Future<void> saveGameState() async {
    if (_gameState == null) return;

    try {
      await _firestore
          .collection('gameStates')
          .doc(_gameState!.playerId)
          .set(_gameState!.toJson());
    } catch (e) {
      debugPrint('Error saving game state: $e');
    }
  }

  bool canPlaceTower(Tower tower) {
    if (!_isInSetupPhase) return false;
    if (_gameState == null) return false;
    return _gameState!.silver >= tower.cost;
  }

  Future<bool> placeTower(Tower tower) async {
    if (!canPlaceTower(tower)) return false;

    _placedTowers.add(tower);
    _gameState = _gameState!.copyWith(
      silver: _gameState!.silver - tower.cost,
    );
    
    await saveGameState();
    notifyListeners();
    return true;
  }

  bool canPlaceWall(List<math.Point<double>> points) {
    if (!_isInSetupPhase) return false;
    if (_gameState == null) return false;
    
    final cost = calculateWallCost(points);
    return _gameState!.silver >= cost;
  }

  int calculateWallCost(List<math.Point<double>> points) {
    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      totalDistance += math.Point(p2.x - p1.x, p2.y - p1.y).magnitude;
    }
    return (totalDistance / 10).ceil(); // 1 silver per 10 units
  }

  Future<bool> placeWall(List<math.Point<double>> points) async {
    if (!canPlaceWall(points)) return false;

    final cost = calculateWallCost(points);
    final wall = Wall(
      id: 'wall_${DateTime.now().millisecondsSinceEpoch}',
      points: points,
      cost: cost,
    );

    _placedWalls.add(wall);
    _gameState = _gameState!.copyWith(
      silver: _gameState!.silver - cost,
    );
    
    await saveGameState();
    notifyListeners();
    return true;
  }

  void startCombatPhase() {
    if (!_isInSetupPhase) return;
    
    _isInSetupPhase = false;
    _isInCombatPhase = true;
    _combatTickCount = 0;
    _activeCombatUnits.clear();
    notifyListeners();
    
    // Start combat simulation with 60 FPS updates
    _combatTimer = Timer.periodic(const Duration(milliseconds: 16), _updateCombat);
  }

  void _updateCombat(Timer timer) {
    _combatTickCount++;
    
    // Spawn units from towers
    _spawnUnitsFromTowers();
    
    // Update unit movements and combat
    _updateCombatUnits();
    
    // Check for victory/defeat conditions
    _checkWinConditions();
    
    notifyListeners();
  }

  void _spawnUnitsFromTowers() {
    final allTowers = [..._currentMapSection!.towers, ..._placedTowers];
    
    for (final tower in allTowers) {
      if (tower.type != TowerType.spawn) continue;
      
      // Check if it's time to spawn (based on spawn rate)
      final spawnInterval = (tower.spawnRate * 60).round(); // Convert to ticks
      if (_combatTickCount % spawnInterval == 0) {
        _spawnUnitFromTower(tower);
      }
    }
  }

  void _spawnUnitFromTower(Tower tower) {
    final factionUnits = _loadedUnits.values.where((u) => 
        u.faction == tower.faction && u.tier == tower.tier).toList();
    
    if (factionUnits.isNotEmpty) {
      final unit = factionUnits.first;
      final combatUnit = CombatUnit(
        id: 'unit_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}',
        unit: unit,
        position: tower.position,
        targetTowerId: _selectTargetTower(tower),
        isPlayerControlled: tower.isPlayerControlled,
        health: unit.strength,
      );
      
      _activeCombatUnits.add(combatUnit);
    }
  }

  String? _selectTargetTower(Tower sourceTower) {
    final allTowers = [..._currentMapSection!.towers, ..._placedTowers];
    final enemyTowers = allTowers.where((t) => 
        t.isPlayerControlled != sourceTower.isPlayerControlled &&
        t.type == TowerType.spawn).toList();
    
    if (enemyTowers.isEmpty) return null;
    
    // Simple AI: target closest enemy tower
    enemyTowers.sort((a, b) {
      final distA = _distanceBetweenPoints(sourceTower.position, a.position);
      final distB = _distanceBetweenPoints(sourceTower.position, b.position);
      return distA.compareTo(distB);
    });
    
    return enemyTowers.first.id;
  }

  double _distanceBetweenPoints(math.Point<double> a, math.Point<double> b) {
    return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
  }

  void _updateCombatUnits() {
    final unitsToRemove = <CombatUnit>[];
    
    for (final unit in _activeCombatUnits) {
      // Move unit towards target
      if (unit.targetTowerId != null) {
        final targetTower = _findTowerById(unit.targetTowerId!);
        if (targetTower != null) {
          _moveUnitTowardsTarget(unit, targetTower);
          
          // Check if unit reached target
          final distance = _distanceBetweenPoints(unit.position, targetTower.position);
          if (distance < 25) { // Tower radius
            _unitReachedTower(unit, targetTower);
            unitsToRemove.add(unit);
          }
        }
      }
    }
    
    // Handle unit vs unit combat
    _handleUnitCombat();
    
    // Remove units that reached their targets
    for (final unit in unitsToRemove) {
      _activeCombatUnits.remove(unit);
    }
  }

  Tower? _findTowerById(String id) {
    final allTowers = [..._currentMapSection!.towers, ..._placedTowers];
    try {
      return allTowers.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  void _moveUnitTowardsTarget(CombatUnit unit, Tower target) {
    final direction = math.Point(
      target.position.x - unit.position.x,
      target.position.y - unit.position.y,
    );
    final distance = math.sqrt(direction.x * direction.x + direction.y * direction.y);
    
    if (distance > 0) {
      final normalizedDirection = math.Point(
        direction.x / distance,
        direction.y / distance,
      );
      
      final speed = unit.unit.speed * 0.5; // Adjust speed for 60 FPS
      unit.position = math.Point(
        unit.position.x + normalizedDirection.x * speed,
        unit.position.y + normalizedDirection.y * speed,
      );
    }
  }

  void _unitReachedTower(CombatUnit unit, Tower tower) {
    // Reduce tower lifeline
    final damage = unit.unit.strength;
    final newLifeline = math.max(0, tower.lifeline - damage);
    
    // Update tower (this is simplified - in production you'd need better state management)
    if (tower.lifeline != newLifeline) {
      final updatedTower = tower.copyWith(lifeline: newLifeline);
      
      // Replace tower in appropriate list
      final mapIndex = _currentMapSection!.towers.indexOf(tower);
      if (mapIndex != -1) {
        _currentMapSection!.towers[mapIndex] = updatedTower;
      } else {
        final placedIndex = _placedTowers.indexOf(tower);
        if (placedIndex != -1) {
          _placedTowers[placedIndex] = updatedTower;
        }
      }
    }
  }

  void _handleUnitCombat() {
    final combatPairs = <List<CombatUnit>>[];
    
    // Find units that are close to each other and on opposite sides
    for (int i = 0; i < _activeCombatUnits.length; i++) {
      for (int j = i + 1; j < _activeCombatUnits.length; j++) {
        final unit1 = _activeCombatUnits[i];
        final unit2 = _activeCombatUnits[j];
        
        if (unit1.isPlayerControlled != unit2.isPlayerControlled) {
          final distance = _distanceBetweenPoints(unit1.position, unit2.position);
          if (distance < 20) { // Combat range
            combatPairs.add([unit1, unit2]);
          }
        }
      }
    }
    
    // Resolve combat
    for (final pair in combatPairs) {
      final unit1 = pair[0];
      final unit2 = pair[1];
      
      // Units deal damage to each other
      unit1.health -= unit2.unit.strength;
      unit2.health -= unit1.unit.strength;
      
      // Remove dead units
      if (unit1.health <= 0) _activeCombatUnits.remove(unit1);
      if (unit2.health <= 0) _activeCombatUnits.remove(unit2);
    }
  }

  void _checkWinConditions() {
    final allTowers = [..._currentMapSection!.towers, ..._placedTowers];
    final enemyTowers = allTowers.where((t) => 
        !t.isPlayerControlled && t.type == TowerType.spawn && t.lifeline > 0).toList();
    final playerTowers = allTowers.where((t) => 
        t.isPlayerControlled && t.type == TowerType.spawn && t.lifeline > 0).toList();
    
    if (enemyTowers.isEmpty) {
      // Player wins
      _completeCombat(true);
    } else if (playerTowers.isEmpty) {
      // Player loses
      _completeCombat(false);
    }
  }

  void _completeCombat(bool victory) {
    _combatTimer?.cancel();
    _isInCombatPhase = false;
    
    if (victory) {
      final sectionId = _currentMapSection?.id ?? '';
      final currentKingdom = _currentMapSection?.kingdom ?? '';
      final newProgress = Map<String, int>.from(_gameState!.kingdomProgress);
      newProgress[currentKingdom] = (newProgress[currentKingdom] ?? 0) + 1;
      
      _gameState = _gameState!.copyWith(
        conqueredSections: {..._gameState!.conqueredSections, sectionId},
        currentSection: _gameState!.currentSection + 1,
        kingdomProgress: newProgress,
        silver: _gameState!.silver + 5, // Bonus silver for victory
      );
      saveGameState();
    }
    
    notifyListeners();
  }

  Future<void> selectFaction(Faction faction) async {
    if (_gameState == null) return;
    
    _gameState = _gameState!.copyWith(playerFaction: faction);
    await saveGameState();
    notifyListeners();
  }

  Future<void> nextLevel() async {
    if (_gameState == null) return;
    
    _gameState = _gameState!.copyWith(
      currentSection: _gameState!.currentSection + 1,
    );
    
    await saveGameState();
    await loadCurrentMapSection();
  }

  Future<void> addSilver(int amount) async {
    if (_gameState == null) return;
    
    _gameState = _gameState!.copyWith(
      silver: _gameState!.silver + amount,
    );
    
    await saveGameState();
    notifyListeners();
  }

  /// Handles the purchase of ad removal
  Future<void> purchaseRemoveAds() async {
    if (_gameState == null) {
      debugPrint('Cannot purchase remove ads: no game state');
      return;
    }
    
    try {
      // Update game state to reflect ad removal purchase
      _gameState = _gameState!.copyWith(hasRemoveAds: true);
      
      // Save to Firebase
      await saveGameState();
      
      // Notify listeners to update UI
      notifyListeners();
      
      debugPrint('Remove ads purchase completed successfully');
    } catch (e) {
      debugPrint('Error completing remove ads purchase: $e');
      rethrow; // Re-throw so UI can handle the error
    }
  }
}