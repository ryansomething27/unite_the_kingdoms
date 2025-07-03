import 'dart:math' as math;
import '../models/game_models.dart';

class AIDecision {
  final AIAction action;
  final Map<String, dynamic> parameters;
  final double confidence;

  AIDecision({
    required this.action,
    required this.parameters,
    required this.confidence,
  });
}

enum AIAction {
  placeTower,
  upgradeTower,
  buildWall,
  focusTarget,
  defend,
  rush,
  waitForResources,
}

enum AIDifficulty { easy, medium, hard, expert }

class AIService {
  final math.Random _random = math.Random();
  
  AIDecision makeDecision({
    required MapSection mapSection,
    required List<Tower> playerTowers,
    required List<Tower> aiTowers,
    required List<Wall> walls,
    required int availableSilver,
    required AIDifficulty difficulty,
    required List<CombatUnit> activeCombatUnits,
  }) {
    
    // Simple AI logic - you can expand this
    if (availableSilver >= 10) {
      return AIDecision(
        action: AIAction.placeTower,
        parameters: {'towerType': 'spawn', 'tier': 1},
        confidence: 0.8,
      );
    }
    
    return AIDecision(
      action: AIAction.waitForResources,
      parameters: {},
      confidence: 1.0,
    );
  }
}