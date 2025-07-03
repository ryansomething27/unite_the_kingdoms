// lib/screens/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/achievements_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementsService>(
      builder: (context, achievementsService, child) {
        final achievements = achievementsService.achievements;
        final unlockedCount = achievements.where((a) => a.isUnlocked).length;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Achievements'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Progress Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                color: const Color(0xFFF5E6D3),
                child: Column(
                  children: [
                    Text(
                      'Progress: $unlockedCount/${achievements.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: unlockedCount / achievements.length,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${((unlockedCount / achievements.length) * 100).round()}% Complete',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Achievements List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return _AchievementCard(achievement: achievement);
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

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: achievement.isUnlocked ? 4 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: achievement.isUnlocked
              ? LinearGradient(
                  colors: [
                    const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    const Color(0xFFD4AF37).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Achievement Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: achievement.isUnlocked 
                      ? const Color(0xFFD4AF37)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  achievement.icon,
                  size: 30,
                  color: achievement.isUnlocked ? Colors.white : Colors.grey[600],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Achievement Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: achievement.isUnlocked 
                            ? const Color(0xFF3E2723)
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: achievement.isUnlocked 
                            ? const Color(0xFF5D4037)
                            : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          size: 16,
                          color: achievement.isUnlocked 
                              ? const Color(0xFFD4AF37)
                              : Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${achievement.silverReward} Silver',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: achievement.isUnlocked 
                                ? const Color(0xFFD4AF37)
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    if (achievement.isUnlocked && achievement.unlockedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Unlocked: ${_formatDate(achievement.unlockedAt!)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF5D4037),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Status Indicator
              if (achievement.isUnlocked)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 24,
                )
              else
                Icon(
                  Icons.lock,
                  color: Colors.grey[400],
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}