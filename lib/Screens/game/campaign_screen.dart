// lib/screens/game/campaign_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/game_service.dart';
import 'battle_screen.dart';

class CampaignScreen extends StatelessWidget {
  const CampaignScreen({super.key});

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
            actions: [
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
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campaign Progress',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (gameState.currentSection + 1) / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Section ${gameState.currentSection + 1} of 100'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Current section info
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                currentSection.isCastle 
                                    ? Icons.castle 
                                    : Icons.location_city,
                                size: 32,
                                color: currentSection.isCastle 
                                    ? const Color(0xFF8B0000) 
                                    : const Color(0xFFD4AF37),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentSection.name,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    Text(
                                      currentSection.kingdom.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF5D4037),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            currentSection.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          const Text(
                            'Objectives:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('• ${currentSection.objectives['primary']}'),
                          if (currentSection.objectives['secondary'] != null)
                            Text('• ${currentSection.objectives['secondary']}'),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            'Enemy Towers: ${currentSection.towers.where((t) => !t.isPlayerControlled).length}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Starting Silver: ${currentSection.startingSilver}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          
                          const Spacer(),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BattleScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: currentSection.isCastle 
                                    ? const Color(0xFF8B0000) 
                                    : const Color(0xFF3E2723),
                              ),
                              child: Text(
                                currentSection.isCastle 
                                    ? 'ASSAULT CASTLE' 
                                    : 'BEGIN BATTLE',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}