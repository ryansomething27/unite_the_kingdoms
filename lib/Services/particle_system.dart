// lib/services/particle_system.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class Particle {
  double x, y;
  double vx, vy;
  double life;
  double maxLife;
  Color color;
  double size;
  double alpha;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
    this.alpha = 1.0,
  });

  void update(double deltaTime) {
    x += vx * deltaTime;
    y += vy * deltaTime;
    life -= deltaTime;
    alpha = life / maxLife;
  }

  bool get isDead => life <= 0;
}

class ParticleSystem {
  final List<Particle> particles = [];
  final math.Random random = math.Random();

  void update(double deltaTime) {
    particles.removeWhere((particle) => particle.isDead);
    
    for (final particle in particles) {
      particle.update(deltaTime);
    }
  }

  void addExplosion(double x, double y, {Color color = Colors.orange, int count = 20}) {
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 50 + random.nextDouble() * 100;
      
      particles.add(Particle(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        life: 0.5 + random.nextDouble() * 0.5,
        maxLife: 1.0,
        color: color,
        size: 2 + random.nextDouble() * 4,
      ));
    }
  }

  void addImpact(double x, double y, {Color color = Colors.yellow, int count = 10}) {
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * math.pi - math.pi / 2;
      final speed = 20 + random.nextDouble() * 40;
      
      particles.add(Particle(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        life: 0.3 + random.nextDouble() * 0.3,
        maxLife: 0.6,
        color: color,
        size: 1 + random.nextDouble() * 3,
      ));
    }
  }

  void addTrail(double x, double y, double vx, double vy, {Color color = Colors.white}) {
    particles.add(Particle(
      x: x + random.nextDouble() * 4 - 2,
      y: y + random.nextDouble() * 4 - 2,
      vx: vx * 0.1 + random.nextDouble() * 10 - 5,
      vy: vy * 0.1 + random.nextDouble() * 10 - 5,
      life: 0.2 + random.nextDouble() * 0.2,
      maxLife: 0.4,
      color: color,
      size: 1 + random.nextDouble() * 2,
    ));
  }

  void paint(Canvas canvas) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }

  void clear() {
    particles.clear();
  }
}