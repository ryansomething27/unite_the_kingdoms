// lib/services/performance_monitor.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class PerformanceMetrics {
  final double frameRate;
  final int memoryUsage;
  final int particleCount;
  final int unitCount;
  final double renderTime;

  PerformanceMetrics({
    required this.frameRate,
    required this.memoryUsage,
    required this.particleCount,
    required this.unitCount,
    required this.renderTime,
  });
}

class PerformanceMonitor extends ChangeNotifier {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  PerformanceMetrics? _currentMetrics;
  Timer? _monitoringTimer;
  final List<double> _frameRates = [];
  DateTime _lastFrameTime = DateTime.now();
  int _frameCount = 0;

  PerformanceMetrics? get currentMetrics => _currentMetrics;
  double get averageFrameRate => _frameRates.isEmpty 
      ? 0 
      : _frameRates.reduce((a, b) => a + b) / _frameRates.length;

  void startMonitoring() {
    if (_monitoringTimer != null) return;

    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateMetrics();
    });
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  void recordFrame() {
    final now = DateTime.now();
    final deltaTime = now.difference(_lastFrameTime).inMicroseconds / 1000000.0;
    
    if (deltaTime > 0) {
      final fps = 1.0 / deltaTime;
      _frameRates.add(fps);
      
      // Keep only last 60 frame rates
      if (_frameRates.length > 60) {
        _frameRates.removeAt(0);
      }
    }
    
    _lastFrameTime = now;
    _frameCount++;
  }

  void _updateMetrics() {
    final frameRate = _frameRates.isEmpty ? 0.0 : _frameRates.last;
    
    _currentMetrics = PerformanceMetrics(
      frameRate: frameRate,
      memoryUsage: _getMemoryUsage(),
      particleCount: 0, // Will be updated by game systems
      unitCount: 0,     // Will be updated by game systems
      renderTime: 0,    // Will be updated by render systems
    );
    
    notifyListeners();
    
    // Log performance warnings
    if (frameRate < 30 && frameRate > 0) {
      debugPrint('Performance Warning: Low FPS detected: ${frameRate.toStringAsFixed(1)}');
    }
  }

  int _getMemoryUsage() {
    // This is a simplified version - in production you'd use proper memory profiling
    return 0;
  }

  void updateGameMetrics({int? particleCount, int? unitCount, double? renderTime}) {
    if (_currentMetrics != null) {
      _currentMetrics = PerformanceMetrics(
        frameRate: _currentMetrics!.frameRate,
        memoryUsage: _currentMetrics!.memoryUsage,
        particleCount: particleCount ?? _currentMetrics!.particleCount,
        unitCount: unitCount ?? _currentMetrics!.unitCount,
        renderTime: renderTime ?? _currentMetrics!.renderTime,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}