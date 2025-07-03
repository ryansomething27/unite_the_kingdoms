import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundType {
  towerPlace,
  unitSpawn,
  combat,
  victory,
  defeat,
  silverEarn,
  wallBuild,
  buttonClick,
  achievement,
  background,
}

class SoundService extends ChangeNotifier {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 0.7;
  double _musicVolume = 0.5;
  
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _musicEnabled = prefs.getBool('music_enabled') ?? true;
    _soundVolume = prefs.getDouble('sound_volume') ?? 0.7;
    _musicVolume = prefs.getDouble('music_volume') ?? 0.5;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('music_enabled', _musicEnabled);
    await prefs.setDouble('sound_volume', _soundVolume);
    await prefs.setDouble('music_volume', _musicVolume);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await _saveSettings();
    notifyListeners();
    
    if (!enabled) {
      stopBackgroundMusic();
    }
  }

  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume;
    await _saveSettings();
    notifyListeners();
  }

  void playSound(SoundType type) {
    if (!_soundEnabled) return;
    
    switch (type) {
      case SoundType.towerPlace:
      case SoundType.combat:
      case SoundType.victory:
      case SoundType.defeat:
        HapticFeedback.mediumImpact();
        break;
      case SoundType.buttonClick:
      case SoundType.silverEarn:
        HapticFeedback.lightImpact();
        break;
      case SoundType.achievement:
        HapticFeedback.heavyImpact();
        break;
      default:
        break;
    }
    
    debugPrint('Playing sound: ${type.name}');
  }

  void playBackgroundMusic() {
    if (!_musicEnabled) return;
    debugPrint('Starting background music');
  }

  void stopBackgroundMusic() {
    debugPrint('Stopping background music');
  }

  void pauseBackgroundMusic() {
    debugPrint('Pausing background music');
  }

  void resumeBackgroundMusic() {
    if (!_musicEnabled) return;
    debugPrint('Resuming background music');
  }
}