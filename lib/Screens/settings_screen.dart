// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../services/achievements_service.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthService, GameService, AchievementsService>(
      builder: (context, authService, gameService, achievementsService, child) {
        final unlockedAchievements = achievementsService.unlockedAchievements.length;
        final totalAchievements = achievementsService.achievements.length;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Email: ${authService.currentUser?.email ?? 'Unknown'}'),
                        Text('Name: ${authService.currentUser?.displayName ?? 'Unknown'}'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Game info
                if (gameService.gameState != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Game Progress',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Faction: ${gameService.gameState!.playerFaction.name.toUpperCase()}'),
                          Text('Current Section: ${gameService.gameState!.currentSection + 1}/100'),
                          Text('Silver: ${gameService.gameState!.silver}'),
                          Text('Conquered Sections: ${gameService.gameState!.conqueredSections.length}'),
                          Text('Achievements: $unlockedAchievements/$totalAchievements'),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Game Statistics
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (gameService.gameState != null) ...[
                          Text('Campaign Progress: ${((gameService.gameState!.currentSection + 1) / 100 * 100).round()}%'),
                          Text('Kingdoms Conquered: ${gameService.gameState!.kingdomProgress.values.where((v) => v >= 25).length}/4'),
                          Text('Total Silver Earned: ${gameService.gameState!.silver + gameService.gameState!.conqueredSections.length * 5}'),
                        ],
                        Text('Achievement Progress: ${totalAchievements > 0 ? (unlockedAchievements / totalAchievements * 100).round() : 0}%'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Monetization
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Purchases',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (gameService.gameState?.hasRemoveAds == true)
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Ads Removed'),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => _purchaseRemoveAds(context),
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('Remove Ads - \$2.99'),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Sign out
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _signOut(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _purchaseRemoveAds(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Ads'),
        content: const Text('Remove all advertisements for \$2.99?\n\nThis will also support the developers and help improve the game!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<GameService>().purchaseRemoveAds();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ads removed! Thank you for your support!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?\n\nYour progress will be saved and available when you sign back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthService>().signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}