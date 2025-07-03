import 'package:flutter/material.dart';
import 'dart:math' as math;

class VisualEffect {
  final String id;
  final EffectType type;
  final Offset position;
  final double duration;
  final double startTime;
  final Map<String, dynamic> parameters;

  VisualEffect({
    required this.id,
    required this.type,
    required this.position,
    required this.duration,
    required this.startTime,
    required this.parameters,
  });

  double get progress => (DateTime.now().millisecondsSinceEpoch - startTime) / (duration * 1000);
  bool get isComplete => progress >= 1.0;
}

enum EffectType {
  explosion,
  healing,
  lightning,
  smoke,
  magic,
  impact,
  levelUp,
  victory,
  defeat,
  silverGain,
  criticalHit,
}

class VisualEffectsService extends ChangeNotifier {
  final List<VisualEffect> _activeEffects = [];
  final math.Random _random = math.Random();

  List<VisualEffect> get activeEffects => _activeEffects;

  void update() {
    _activeEffects.removeWhere((effect) => effect.isComplete);
    notifyListeners();
  }

  void addExplosion(Offset position, {Color color = Colors.orange, double intensity = 1.0}) {
    final effect = VisualEffect(
      id: _generateId(),
      type: EffectType.explosion,
      position: position,
      duration: 0.8 * intensity,
      startTime: DateTime.now().millisecondsSinceEpoch.toDouble(),
      parameters: {
        'color': color,
        'intensity': intensity,
        'particleCount': (20 * intensity).round(),
        'radius': 30 * intensity,
      },
    );
    _activeEffects.add(effect);
    notifyListeners();
  }

  void addFloatingText(Offset position, String text, Color color, {double size = 16}) {
    final effect = VisualEffect(
      id: _generateId(),
      type: EffectType.silverGain,
      position: position,
      duration: 1.5,
      startTime: DateTime.now().millisecondsSinceEpoch.toDouble(),
      parameters: {
        'text': text,
        'color': color,
        'fontSize': size,
        'velocity': const Offset(0, -50),
      },
    );
    _activeEffects.add(effect);
    notifyListeners();
  }

  String _generateId() {
    return 'effect_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
  }

  void clear() {
    _activeEffects.clear();
    notifyListeners();
  }
}