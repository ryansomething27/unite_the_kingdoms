// lib/screens/accessibility_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, accessibilityService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Accessibility Settings'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Visual Accessibility
              const _SectionHeader(title: 'Visual Accessibility'),
              SwitchListTile(
                title: const Text('High Contrast Mode'),
                subtitle: const Text('Increases contrast for better visibility'),
                value: accessibilityService.highContrastMode,
                onChanged: (value) => accessibilityService.setHighContrastMode(value),
              ),
              SwitchListTile(
                title: const Text('Simplified UI'),
                subtitle: const Text('Larger buttons and simplified interface'),
                value: accessibilityService.simplifiedUI,
                onChanged: (value) => accessibilityService.setSimplifiedUI(value),
              ),
              
              // Text Size
              const _SectionHeader(title: 'Text Size'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text Scale: ${(accessibilityService.textScale * 100).round()}%',
                      style: TextStyle(
                        fontSize: 16 * accessibilityService.textScale,
                      ),
                    ),
                    Slider(
                      value: accessibilityService.textScale,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      onChanged: (value) => accessibilityService.setTextScale(value),
                    ),
                    const Text(
                      'Sample text: The quick brown fox jumps over the lazy dog.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              // Motion Accessibility
              const _SectionHeader(title: 'Motion & Animation'),
              SwitchListTile(
                title: const Text('Reduce Animations'),
                subtitle: const Text('Minimize motion for motion sensitivity'),
                value: accessibilityService.reduceAnimations,
                onChanged: (value) => accessibilityService.setReduceAnimations(value),
              ),
              
              // Screen Reader
              const _SectionHeader(title: 'Screen Reader'),
              SwitchListTile(
                title: const Text('Screen Reader Mode'),
                subtitle: const Text('Optimized for TalkBack and VoiceOver'),
                value: accessibilityService.screenReaderMode,
                onChanged: (value) => accessibilityService.setScreenReaderMode(value),
              ),
              
              // Color Blind Support
              const _SectionHeader(title: 'Color Vision'),
              SwitchListTile(
                title: const Text('Color Blind Support'),
                subtitle: const Text('Adjust colors for color vision differences'),
                value: accessibilityService.colorBlindMode,
                onChanged: (value) => accessibilityService.setColorBlindMode(
                  value, 
                  accessibilityService.colorBlindType,
                ),
              ),
              if (accessibilityService.colorBlindMode)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: DropdownButtonFormField<ColorBlindType>(
                    value: accessibilityService.colorBlindType,
                    decoration: const InputDecoration(
                      labelText: 'Color Vision Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ColorBlindType.protanopia,
                        child: Text('Protanopia (Red-blind)'),
                      ),
                      DropdownMenuItem(
                        value: ColorBlindType.deuteranopia,
                        child: Text('Deuteranopia (Green-blind)'),
                      ),
                      DropdownMenuItem(
                        value: ColorBlindType.tritanopia,
                        child: Text('Tritanopia (Blue-blind)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        accessibilityService.setColorBlindMode(true, value);
                      }
                    },
                  ),
                ),
              
              // Test Section
              const _SectionHeader(title: 'Test Your Settings'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Game UI Preview',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize! * 
                              accessibilityService.textScale,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: accessibilityService.adjustColorForAccessibility(Colors.green),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Player Tower',
                            style: TextStyle(
                              fontSize: 14 * accessibilityService.textScale,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: accessibilityService.adjustColorForAccessibility(Colors.red),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Enemy Tower',
                            style: TextStyle(
                              fontSize: 14 * accessibilityService.textScale,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            accessibilityService.announceForScreenReader(
                              'Accessibility settings test button pressed',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Test button works correctly!'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: accessibilityService.simplifiedUI 
                                ? const Size(0, 60)
                                : const Size(0, 48),
                          ),
                          child: Text(
                            'Test Button',
                            style: TextStyle(
                              fontSize: 16 * accessibilityService.textScale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, accessibilityService, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! *
                  accessibilityService.textScale,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }
}