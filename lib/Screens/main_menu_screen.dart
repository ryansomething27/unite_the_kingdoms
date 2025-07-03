// lib/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../services/ads_service.dart';
import '../services/achievements_service.dart';
import 'game/faction_selection_screen.dart';
import 'game/campaign_screen.dart';
import 'achievements_screen.dart';
import 'tutorial_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await context.read<GameService>().initializeGame();
    await context.read<AchievementsService>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<GameService, AuthService, AchievementsService>(
      builder: (context, gameService, authService, achievementsService, child) {
        final unlockedAchievements = achievementsService.unlockedAchievements.length;
        final totalAchievements = achievementsService.achievements.length;
        
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3E2723),
                  Color(0xFF5D4037),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${authService.currentUser?.displayName ?? 'Lord'}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (gameService.gameState != null)
                              Text(
                                'Silver: ${gameService.gameState!.silver}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFF5E6D3),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TutorialScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.help_outline,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.settings,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    const Icon(
                      Icons.castle,
                      size: 120,
                      color: Color(0xFFD4AF37),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unite the Kingdoms',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        fontFamily: 'Serif',
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Menu Options
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (gameService.gameState?.playerFaction == null)
                            _MenuButton(
                              title: 'Start Campaign',
                              subtitle: 'Choose your faction and begin',
                              icon: Icons.play_arrow,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const FactionSelectionScreen(),
                                  ),
                                );
                              },
                            )
                          else
                            _MenuButton(
                              title: 'Continue Campaign',
                              subtitle: 'Progress: ${gameService.gameState!.currentSection + 1}/100',
                              icon: Icons.forward,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CampaignScreen(),
                                  ),
                                );
                              },
                            ),
                          
                          const SizedBox(height: 16),
                          
                          _MenuButton(
                            title: 'Achievements',
                            subtitle: '$unlockedAchievements/$totalAchievements unlocked',
                            icon: Icons.emoji_events,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AchievementsScreen(),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          _MenuButton(
                            title: 'Free Silver',
                            subtitle: 'Watch ad for +10 silver',
                            icon: Icons.video_library,
                            onPressed: context.read<AdsService>().isRewardedAdReady
                                ? () => _watchAdForSilver()
                                : null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          const _MenuButton(
                            title: 'Multiplayer',
                            subtitle: 'Coming soon',
                            icon: Icons.people,
                            onPressed: null,
                          ),
                        ],
                      ),
                    ),
                    
                    // Progress Indicator
                    if (gameService.gameState != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Kingdom Progress',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...gameService.gameState!.kingdomProgress.entries.map(
                                (entry) => Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key.toUpperCase()),
                                    Text('${entry.value}/25'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _watchAdForSilver() async {
    final adsService = context.read<AdsService>();
    final gameService = context.read<GameService>();
    final achievementsService = context.read<AchievementsService>();

    final success = await adsService.showRewardedAd();
    if (success) {
      await gameService.addSilver(10);
      
      // Check silver hoarder achievement
      await achievementsService.checkAchievement('silver_hoarder', context: {
        'silver': gameService.gameState?.silver ?? 0,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You earned 10 silver!')),
        );
      }
    }
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onPressed;

  const _MenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: onPressed != null 
                      ? const Color(0xFFD4AF37) 
                      : Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: onPressed != null 
                              ? const Color(0xFF3E2723) 
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: onPressed != null 
                              ? const Color(0xFF5D4037) 
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onPressed != null)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF3E2723),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}