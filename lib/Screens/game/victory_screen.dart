// lib/screens/game/victory_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_models.dart';
import '../../services/game_service.dart';
import '../main_menu_screen.dart';
import 'campaign_screen.dart';

class VictoryScreen extends StatelessWidget {
  final BattleResult battleResult;
  final bool isCastleVictory;

  const VictoryScreen({
    super.key,
    required this.battleResult,
    this.isCastleVictory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: battleResult.victory
                ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                : [const Color(0xFF8B0000), const Color(0xFF5D0000)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Victory/Defeat Icon
                Icon(
                  battleResult.victory 
                      ? (isCastleVictory ? Icons.castle : Icons.military_tech)
                      : Icons.dangerous,
                  size: 120,
                  color: Colors.white,
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  battleResult.victory 
                      ? (isCastleVictory ? 'KINGDOM CONQUERED!' : 'VICTORY!')
                      : 'DEFEAT!',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Serif',
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  battleResult.victory
                      ? (isCastleVictory 
                          ? 'The castle falls before your might!'
                          : 'Your strategy has triumphed!')
                      : 'Your forces have been overwhelmed!',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Battle Statistics
                Card(
                  color: Colors.white.withValues(alpha: 0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Battle Statistics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatRow(
                          label: 'Silver Earned',
                          value: '+${battleResult.silverEarned}',
                          icon: Icons.monetization_on,
                          color: const Color(0xFFD4AF37),
                        ),
                        _StatRow(
                          label: 'Enemies Defeated',
                          value: '${battleResult.enemiesDefeated}',
                          icon: Icons.offline_bolt,
                          color: const Color(0xFF8B0000),
                        ),
                        _StatRow(
                          label: 'Units Lost',
                          value: '${battleResult.unitsLost}',
                          icon: Icons.person_remove,
                          color: const Color(0xFF5D4037),
                        ),
                        _StatRow(
                          label: 'Battle Duration',
                          value: _formatDuration(battleResult.battleDuration),
                          icon: Icons.timer,
                          color: const Color(0xFF2196F3),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Action Buttons
                if (battleResult.victory) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _nextBattle(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF3E2723),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isCastleVictory ? 'CONTINUE CAMPAIGN' : 'NEXT BATTLE',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _returnToMenu(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'RETURN TO MENU',
                      style: TextStyle(
                        fontSize: 16,
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
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  void _nextBattle(BuildContext context) {
    final gameService = context.read<GameService>();
    gameService.nextLevel();
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CampaignScreen()),
      ModalRoute.withName('/'),
    );
  }

  void _returnToMenu(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      (route) => false,
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF3E2723),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}