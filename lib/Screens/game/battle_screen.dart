// lib/screens/game/battle_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/game_service.dart';
import '../../widgets/enhanced_game_map_widget.dart';
import '../../widgets/tower_placement_panel.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, gameService, child) {
        final gameState = gameService.gameState;
        final currentSection = gameService.currentMapSection;
        
        if (gameState == null || currentSection == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(currentSection.name),
            backgroundColor: gameService.isInCombatPhase 
                ? const Color(0xFF8B0000) 
                : const Color(0xFF3E2723),
            actions: [
              if (gameService.isInSetupPhase)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => gameService.startCombatPhase(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF3E2723),
                    ),
                    child: const Text('START BATTLE'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Silver: ${gameState.silver}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Phase indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                color: gameService.isInSetupPhase 
                    ? const Color(0xFF4CAF50) 
                    : const Color(0xFF8B0000),
                child: Text(
                  gameService.isInSetupPhase 
                      ? 'SETUP PHASE - Place towers and walls'
                      : 'COMBAT PHASE - Battle in progress',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Game map
              Expanded(
                flex: 3,
                child: EnhancedGameMapWidget(
                  mapSection: currentSection,
                  placedTowers: gameService.placedTowers,
                  placedWalls: gameService.placedWalls,
                  isSetupPhase: gameService.isInSetupPhase,
                ),
              ),
              
              // Tower placement panel
              if (gameService.isInSetupPhase)
                Expanded(
                  flex: 1,
                  child: TowerPlacementPanel(
                    faction: gameState.playerFaction,
                    availableSilver: gameState.silver,
                    onTowerSelected: (tower) {
                      // This will be handled by the GameMapWidget
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}