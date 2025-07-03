// lib/widgets/accessibility_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';

class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String semanticsLabel;
  final String? semanticsHint;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    required this.semanticsLabel,
    this.semanticsHint,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, accessibilityService, _) {
        return Semantics(
          label: semanticsLabel,
          hint: semanticsHint,
          button: true,
          enabled: onPressed != null,
          child: ElevatedButton(
            onPressed: onPressed == null ? null : () {
              accessibilityService.hapticFeedback();
              onPressed!();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: accessibilityService.simplifiedUI 
                  ? const Size(60, 60)
                  : const Size(48, 48),
            ),
            child: DefaultTextStyle(
              style: DefaultTextStyle.of(context).style.copyWith(
                fontSize: DefaultTextStyle.of(context).style.fontSize! * 
                    accessibilityService.textScale,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, accessibilityService, _) {
        return Semantics(
          label: semanticsLabel,
          button: onTap != null,
          child: Card(
            elevation: accessibilityService.simplifiedUI ? 2 : 4,
            child: InkWell(
              onTap: onTap == null ? null : () {
                accessibilityService.hapticFeedback();
                onTap!();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.all(accessibilityService.simplifiedUI ? 12 : 8),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AccessibleGameMap extends StatelessWidget {
  final Widget child;
  final String currentPhase;
  final int silverAmount;
  final int enemyTowers;
  final int playerTowers;

  const AccessibleGameMap({
    super.key,
    required this.child,
    required this.currentPhase,
    required this.silverAmount,
    required this.enemyTowers,
    required this.playerTowers,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityService>(
      builder: (context, accessibilityService, _) {
        final semanticsLabel = 'Game map. $currentPhase phase. '
            'You have $silverAmount silver, $playerTowers towers. '
            'Enemy has $enemyTowers towers.';
        
        return Semantics(
          label: semanticsLabel,
          liveRegion: true,
          child: ExcludeSemantics(
            excluding: !accessibilityService.screenReaderMode,
            child: child,
          ),
        );
      },
    );
  }
}