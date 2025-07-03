import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService extends ChangeNotifier {
  bool _highContrastMode = false;
  bool _reduceAnimations = false;
  bool _screenReaderMode = false;
  double _textScale = 1.0;
  bool _simplifiedUI = false;
  bool _colorBlindMode = false;
  ColorBlindType _colorBlindType = ColorBlindType.none;

  bool get highContrastMode => _highContrastMode;
  bool get reduceAnimations => _reduceAnimations;
  bool get screenReaderMode => _screenReaderMode;
  double get textScale => _textScale;
  bool get simplifiedUI => _simplifiedUI;
  bool get colorBlindMode => _colorBlindMode;
  ColorBlindType get colorBlindType => _colorBlindType;

  Future<void> initialize() async {
    await _loadSettings();
    _detectSystemSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _highContrastMode = prefs.getBool('high_contrast_mode') ?? false;
    _reduceAnimations = prefs.getBool('reduce_animations') ?? false;
    _screenReaderMode = prefs.getBool('screen_reader_mode') ?? false;
    _textScale = prefs.getDouble('text_scale') ?? 1.0;
    _simplifiedUI = prefs.getBool('simplified_ui') ?? false;
    _colorBlindMode = prefs.getBool('color_blind_mode') ?? false;
    _colorBlindType = ColorBlindType.values[prefs.getInt('color_blind_type') ?? 0];
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast_mode', _highContrastMode);
    await prefs.setBool('reduce_animations', _reduceAnimations);
    await prefs.setBool('screen_reader_mode', _screenReaderMode);
    await prefs.setDouble('text_scale', _textScale);
    await prefs.setBool('simplified_ui', _simplifiedUI);
    await prefs.setBool('color_blind_mode', _colorBlindMode);
    await prefs.setInt('color_blind_type', _colorBlindType.index);
  }

  void _detectSystemSettings() {
    final mediaQuery = MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first);
    
    if (mediaQuery.accessibleNavigation) {
      _screenReaderMode = true;
    }
    
    if (mediaQuery.disableAnimations) {
      _reduceAnimations = true;
    }
    
    if (mediaQuery.highContrast) {
      _highContrastMode = true;
    }
    
    _textScale = mediaQuery.textScaleFactor;
    notifyListeners();
  }

  Future<void> setHighContrastMode(bool enabled) async {
    _highContrastMode = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setReduceAnimations(bool enabled) async {
    _reduceAnimations = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setScreenReaderMode(bool enabled) async {
    _screenReaderMode = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale.clamp(0.5, 2.0);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setSimplifiedUI(bool enabled) async {
    _simplifiedUI = enabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setColorBlindMode(bool enabled, ColorBlindType type) async {
    _colorBlindMode = enabled;
    _colorBlindType = type;
    await _saveSettings();
    notifyListeners();
  }

  void announceForScreenReader(String message) {
    if (_screenReaderMode) {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  void hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  Color adjustColorForAccessibility(Color color) {
    if (!_colorBlindMode) return color;

    switch (_colorBlindType) {
      case ColorBlindType.protanopia:
        return _adjustForProtanopia(color);
      case ColorBlindType.deuteranopia:
        return _adjustForDeuteranopia(color);
      case ColorBlindType.tritanopia:
        return _adjustForTritanopia(color);
      case ColorBlindType.none:
        return color;
    }
  }

  Color _adjustForProtanopia(Color color) {
    return Color.fromARGB(
      color.alpha,
      (color.red * 0.567 + color.green * 0.433).round(),
      (color.red * 0.558 + color.green * 0.442).round(),
      color.blue,
    );
  }

  Color _adjustForDeuteranopia(Color color) {
    return Color.fromARGB(
      color.alpha,
      (color.red * 0.625 + color.green * 0.375).round(),
      (color.red * 0.7 + color.green * 0.3).round(),
      color.blue,
    );
  }

  Color _adjustForTritanopia(Color color) {
    return Color.fromARGB(
      color.alpha,
      color.red,
      (color.green * 0.967 + color.blue * 0.033).round(),
      (color.green * 0.183 + color.blue * 0.817).round(),
    );
  }

  ThemeData getAccessibleTheme(ThemeData baseTheme) {
    if (!_highContrastMode) return baseTheme;

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: Colors.black,
        secondary: Colors.white,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
      ),
    );
  }

  Duration getAnimationDuration(Duration baseDuration) {
    if (_reduceAnimations) {
      return Duration(milliseconds: (baseDuration.inMilliseconds * 0.3).round());
    }
    return baseDuration;
  }
}

enum ColorBlindType {
  none,
  protanopia,
  deuteranopia,
  tritanopia,
}