// lib/widgets/enhanced_game_map_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../services/game_service.dart';
import '../services/particle_system.dart';
import '../services/performance_monitor.dart';
import '../services/sound_service.dart';
import 'dart:math' as math;

class EnhancedGameMapWidget extends StatefulWidget {
  final MapSection mapSection;
  final List<Tower> placedTowers;
  final List<Wall> placedWalls;
  final bool isSetupPhase;

  const EnhancedGameMapWidget({
    super.key,
    required this.mapSection,
    required this.placedTowers,
    required this.placedWalls,
    required this.isSetupPhase,
  });

  @override
  State<EnhancedGameMapWidget> createState() => _EnhancedGameMapWidgetState();
}

class _EnhancedGameMapWidgetState extends State<EnhancedGameMapWidget> 
    with TickerProviderStateMixin {
  Tower? _selectedTowerType;
  List<math.Point<double>> _wallPoints = [];
  bool _isDrawingWall = false;
  late AnimationController _animationController;
  final ParticleSystem _particleSystem = ParticleSystem();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    _performanceMonitor.startMonitoring();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _performanceMonitor.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, gameService, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF8FBC8F),
            border: Border.all(color: const Color(0xFF3E2723), width: 2),
          ),
          child: GestureDetector(
            onTapDown: widget.isSetupPhase ? _handleTap : null,
            onPanStart: widget.isSetupPhase ? _handlePanStart : null,
            onPanUpdate: widget.isSetupPhase ? _handlePanUpdate : null,
            onPanEnd: widget.isSetupPhase ? _handlePanEnd : null,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                _performanceMonitor.recordFrame();
                
                return CustomPaint(
                  painter: EnhancedGameMapPainter(
                    mapSection: widget.mapSection,
                    placedTowers: widget.placedTowers,
                    placedWalls: widget.placedWalls,
                    wallPoints: _wallPoints,
                    isDrawingWall: _isDrawingWall,
                    combatUnits: gameService.activeCombatUnits,
                    animationValue: _animationController.value,
                    particleSystem: _particleSystem,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTap(TapDownDetails details) async {
    if (_selectedTowerType != null) {
      final position = math.Point(details.localPosition.dx, details.localPosition.dy);
      
      // Check if position is valid (not too close to other towers)
      if (_isValidTowerPosition(position)) {
        final tower = _selectedTowerType!.copyWith(
          id: 'tower_${DateTime.now().millisecondsSinceEpoch}',
          position: position,
          isPlayerControlled: true,
        );
        
        final success = await context.read<GameService>().placeTower(tower);
        if (success) {
          SoundService().playSound(SoundType.towerPlace);
          _particleSystem.addImpact(position.x, position.y, color: Colors.green);
        }
        _selectedTowerType = null;
      }
    }
  }

  bool _isValidTowerPosition(math.Point<double> position) {
    final allTowers = [...widget.mapSection.towers, ...widget.placedTowers];
    
    for (final tower in allTowers) {
      final distance = math.sqrt(
        math.pow(position.x - tower.position.x, 2) + 
        math.pow(position.y - tower.position.y, 2)
      );
      if (distance < 50) return false; // Minimum distance between towers
    }
    
    return true;
  }

  void _handlePanStart(DragStartDetails details) {
    if (_selectedTowerType == null) {
      _isDrawingWall = true;
      _wallPoints = [math.Point(details.localPosition.dx, details.localPosition.dy)];
      setState(() {});
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isDrawingWall) {
      _wallPoints.add(math.Point(details.localPosition.dx, details.localPosition.dy));
      setState(() {});
    }
  }

  Future<void> _handlePanEnd(DragEndDetails details) async {
    if (_isDrawingWall && _wallPoints.length > 1) {
      final success = await context.read<GameService>().placeWall(_wallPoints);
      if (success) {
        SoundService().playSound(SoundType.wallBuild);
      }
    }
    _isDrawingWall = false;
    _wallPoints.clear();
    setState(() {});
  }

  void selectTowerType(Tower tower) {
    setState(() {
      _selectedTowerType = tower;
    });
  }
}

class EnhancedGameMapPainter extends CustomPainter {
  final MapSection mapSection;
  final List<Tower> placedTowers;
  final List<Wall> placedWalls;
  final List<math.Point<double>> wallPoints;
  final bool isDrawingWall;
  final List<CombatUnit> combatUnits;
  final double animationValue;
  final ParticleSystem particleSystem;

  EnhancedGameMapPainter({
    required this.mapSection,
    required this.placedTowers,
    required this.placedWalls,
    required this.wallPoints,
    required this.isDrawingWall,
    required this.combatUnits,
    required this.animationValue,
    required this.particleSystem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update particle system
    particleSystem.update(1/60); // Assume 60 FPS
    
    // Draw terrain with more detail
    _drawEnhancedTerrain(canvas, size);
    
    // Draw tower ranges first (so they appear behind towers)
    _drawTowerRanges(canvas);
    
    // Draw walls with shadows
    for (final wall in placedWalls) {
      _drawEnhancedWall(canvas, wall.points);
    }
    
    if (isDrawingWall && wallPoints.isNotEmpty) {
      _drawEnhancedWall(canvas, wallPoints, isTemporary: true);
    }
    
    // Draw towers with enhanced graphics
    for (final tower in mapSection.towers) {
      _drawEnhancedTower(canvas, tower, tower.isPlayerControlled);
    }
    
    for (final tower in placedTowers) {
      _drawEnhancedTower(canvas, tower, true);
    }
    
    // Draw combat units with trails
    for (final unit in combatUnits) {
      _drawEnhancedCombatUnit(canvas, unit);
    }
    
    // Draw particles last (on top)
    particleSystem.paint(canvas);
    
    // Update performance metrics
    PerformanceMonitor().updateGameMetrics(
      particleCount: particleSystem.particles.length,
      unitCount: combatUnits.length,
    );
  }

  void _drawEnhancedTerrain(Canvas canvas, Size size) {
    // Create a more realistic terrain with gradients and textures
    const terrainGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Color(0xFF9ACD32),
        Color(0xFF228B22),
        Color(0xFF006400),
      ],
    );
    
    final terrainPaint = Paint()
      ..shader = terrainGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), terrainPaint);
    
    // Add some terrain features (hills, rocks, etc.)
    final random = math.Random(42); // Fixed seed for consistent terrain
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 10 + random.nextDouble() * 30;
      
      final featurePaint = Paint()
        ..color = const Color(0xFF228B22).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(Offset(x, y), radius, featurePaint);
    }
  }

  void _drawEnhancedTower(Canvas canvas, Tower tower, bool isPlayerControlled) {
    // Enhanced tower with 3D effect and better graphics
    final shadowPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.fill;
    
    final radius = tower.type == TowerType.spawn ? 20.0 : 15.0;
    
    // Draw shadow
    canvas.drawCircle(
      Offset(tower.position.x + 3, tower.position.y + 3),
      radius,
      shadowPaint,
    );
    
    // Create gradient for 3D effect
    final gradient = RadialGradient(
      colors: isPlayerControlled 
          ? [const Color(0xFF66BB6A), const Color(0xFF2E7D32)]
          : [const Color(0xFFE57373), const Color(0xFFC62828)],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(
          center: Offset(tower.position.x, tower.position.y), 
          radius: radius,
        ),
      );
    
    // Add pulsing effect for damaged towers
    final healthPercent = tower.lifeline / (tower.type == TowerType.spawn ? 30.0 : 1.0);
    final pulseRadius = healthPercent < 0.3 
        ? radius + math.sin(animationValue * math.pi * 4) * 3
        : radius;
    
    canvas.drawCircle(
      Offset(tower.position.x, tower.position.y),
      pulseRadius,
      paint,
    );
    
    // Draw border
    final borderPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(
      Offset(tower.position.x, tower.position.y),
      radius,
      borderPaint,
    );
    
    // Draw enhanced tower icons
    if (tower.type == TowerType.archer) {
      _drawEnhancedArcherIcon(canvas, tower.position, radius * 0.6);
    } else {
      _drawEnhancedSpawnIcon(canvas, tower.position, radius * 0.6, tower.tier);
    }
    
    // Draw lifeline bar with better graphics
    if (tower.type == TowerType.spawn) {
      _drawEnhancedLifelineBar(canvas, tower, radius);
    }
  }

  void _drawEnhancedArcherIcon(Canvas canvas, math.Point<double> center, double size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Draw bow with more detail
    final path = Path();
    path.moveTo(center.x - size * 0.5, center.y - size * 0.3);
    path.quadraticBezierTo(
      center.x - size * 0.7, center.y,
      center.x - size * 0.5, center.y + size * 0.3,
    );
    canvas.drawPath(path, paint);
    
    // Draw bowstring
    canvas.drawLine(
      Offset(center.x - size * 0.5, center.y - size * 0.3),
      Offset(center.x - size * 0.5, center.y + size * 0.3),
      paint,
    );
    
    // Draw arrow with fletching
    canvas.drawLine(
      Offset(center.x - size * 0.3, center.y),
      Offset(center.x + size * 0.3, center.y),
      paint,
    );
    
    // Arrow head
    canvas.drawLine(
      Offset(center.x + size * 0.3, center.y),
      Offset(center.x + size * 0.2, center.y - size * 0.1),
      paint,
    );
    canvas.drawLine(
      Offset(center.x + size * 0.3, center.y),
      Offset(center.x + size * 0.2, center.y + size * 0.1),
      paint,
    );
  }

  void _drawEnhancedSpawnIcon(Canvas canvas, math.Point<double> center, double size, UnitTier? tier) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Draw different icons based on tier
    switch (tier) {
      case UnitTier.tier1:
        // Simple sword
        canvas.drawLine(
          Offset(center.x, center.y - size * 0.5),
          Offset(center.x, center.y + size * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(center.x - size * 0.2, center.y - size * 0.3),
          Offset(center.x + size * 0.2, center.y - size * 0.3),
          paint,
        );
        break;
      case UnitTier.tier2:
        // Sword and shield
        canvas.drawLine(
          Offset(center.x + size * 0.1, center.y - size * 0.5),
          Offset(center.x + size * 0.1, center.y + size * 0.5),
          paint,
        );
        canvas.drawCircle(
          Offset(center.x - size * 0.2, center.y),
          size * 0.3,
          paint,
        );
        break;
      case UnitTier.tier3:
        // Crossed weapons
        canvas.drawLine(
          Offset(center.x - size * 0.3, center.y - size * 0.3),
          Offset(center.x + size * 0.3, center.y + size * 0.3),
          paint,
        );
        canvas.drawLine(
          Offset(center.x + size * 0.3, center.y - size * 0.3),
          Offset(center.x - size * 0.3, center.y + size * 0.3),
          paint,
        );
        break;
      default:
        // Default icon
        canvas.drawLine(
          Offset(center.x, center.y - size * 0.5),
          Offset(center.x, center.y + size * 0.5),
          paint,
        );
    }
  }

  void _drawEnhancedLifelineBar(Canvas canvas, Tower tower, double radius) {
    const barWidth = 40.0;
    const barHeight = 8.0;
    final barX = tower.position.x - barWidth / 2;
    final barY = tower.position.y + radius + 10;

    // Draw background with rounded corners
    final backgroundRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      const Radius.circular(4),
    );
    
    canvas.drawRRect(
      backgroundRRect,
      Paint()..color = Colors.black54,
    );

    // Calculate health percentage
    final maxLifeline = tower.type == TowerType.spawn ? 30.0 : 1.0;
    final lifelinePercent = tower.lifeline / maxLifeline;
    
    // Choose color based on health
    Color healthColor;
    if (lifelinePercent > 0.6) {
      healthColor = Colors.green;
    } else if (lifelinePercent > 0.3) {
      healthColor = Colors.orange;
    } else {
      healthColor = Colors.red;
    }

    // Draw health bar with gradient
    final healthGradient = LinearGradient(
      colors: [healthColor, healthColor.withValues(alpha: 0.7)],
    );
    
    final healthRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barX + 1, barY + 1, (barWidth - 2) * lifelinePercent, barHeight - 2),
      const Radius.circular(3),
    );
    
    canvas.drawRRect(
      healthRRect,
      Paint()..shader = healthGradient.createShader(healthRRect.outerRect),
    );

    // Draw border
    canvas.drawRRect(
      backgroundRRect,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Draw health text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${tower.lifeline}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        tower.position.x - textPainter.width / 2,
        barY - textPainter.height - 2,
      ),
    );
  }

  void _drawEnhancedWall(Canvas canvas, List<math.Point<double>> points, {bool isTemporary = false}) {
    if (points.length < 2) return;

    final shadowPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final paint = Paint()
      ..color = isTemporary 
          ? const Color(0xFF9E9E9E).withValues(alpha: 0.7)
          : const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final shadowPath = Path();
    
    path.moveTo(points.first.x, points.first.y);
    shadowPath.moveTo(points.first.x + 2, points.first.y + 2);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
      shadowPath.lineTo(points[i].x + 2, points[i].y + 2);
    }
    
    // Draw shadow first
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Draw wall
    canvas.drawPath(path, paint);
    
    // Add stone texture effect
    if (!isTemporary) {
      final texturePaint = Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(path, texturePaint);
    }
  }

  void _drawEnhancedCombatUnit(Canvas canvas, CombatUnit unit) {
    // Add trail effect
    particleSystem.addTrail(
      unit.position.x, 
      unit.position.y, 
      0, 0, // Velocity would be calculated from previous position
      color: unit.isPlayerControlled ? Colors.blue : Colors.red,
    );
    
    final gradient = RadialGradient(
      colors: unit.isPlayerControlled 
          ? [const Color(0xFF42A5F5), const Color(0xFF1976D2)]
          : [const Color(0xFFFF7043), const Color(0xFFD32F2F)],
    );

    final radius = 8.0 + math.sin(animationValue * math.pi * 2) * 1;
    
    canvas.drawCircle(
      Offset(unit.position.x, unit.position.y),
      radius,
      Paint()..shader = gradient.createShader(
        Rect.fromCircle(
          center: Offset(unit.position.x, unit.position.y),
          radius: radius,
        ),
      ),
    );
    
    // Draw unit border
    canvas.drawCircle(
      Offset(unit.position.x, unit.position.y),
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Draw faction symbol
    _drawUnitSymbol(canvas, unit);
    
    // Draw health indicator if damaged
    if (unit.health < unit.unit.strength) {
      final healthPaint = Paint()
        ..color = unit.health > unit.unit.strength * 0.5 
            ? Colors.yellow 
            : Colors.red
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(unit.position.x, unit.position.y - radius - 8),
        4,
        healthPaint,
      );
    }
  }

  void _drawUnitSymbol(Canvas canvas, CombatUnit unit) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    final center = unit.position;
    const size = 4.0;
    
    if (unit.unit.faction == Faction.saxons) {
      // Draw cross for Saxons
      canvas.drawLine(
        Offset(center.x, center.y - size),
        Offset(center.x, center.y + size),
        paint,
      );
      canvas.drawLine(
        Offset(center.x - size, center.y),
        Offset(center.x + size, center.y),
        paint,
      );
    } else {
      // Draw hammer for Danes
      canvas.drawLine(
        Offset(center.x, center.y - size),
        Offset(center.x, center.y + size),
        paint,
      );
      canvas.drawLine(
        Offset(center.x - size * 0.7, center.y - size * 0.5),
        Offset(center.x + size * 0.7, center.y - size * 0.5),
        paint,
      );
    }
  }

  void _drawTowerRanges(Canvas canvas) {
    final allTowers = [...mapSection.towers, ...placedTowers];
    
    for (final tower in allTowers) {
      if (tower.type == TowerType.archer && tower.range != null) {
        final gradient = RadialGradient(
          colors: tower.isPlayerControlled 
              ? [Colors.green.withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.0)]
              : [Colors.red.withValues(alpha: 0.1), Colors.red.withValues(alpha: 0.0)],
        );

        canvas.drawCircle(
          Offset(tower.position.x, tower.position.y),
          tower.range!,
          Paint()..shader = gradient.createShader(
            Rect.fromCircle(
              center: Offset(tower.position.x, tower.position.y),
              radius: tower.range!,
            ),
          ),
        );
        
        // Draw range border with dashed effect
        final borderPaint = Paint()
          ..color = tower.isPlayerControlled 
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawCircle(
          Offset(tower.position.x, tower.position.y),
          tower.range!,
          borderPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}