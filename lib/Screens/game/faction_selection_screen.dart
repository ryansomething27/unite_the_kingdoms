// lib/screens/game/faction_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_models.dart';
import '../../services/game_service.dart';
import 'campaign_screen.dart';

class FactionSelectionScreen extends StatelessWidget {
  const FactionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Faction'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Choose your faction to begin the campaign',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _FactionCard(
                      faction: Faction.saxons,
                      title: 'Saxons',
                      subtitle: 'Kingdom of Wessex',
                      description: 'Disciplined and defensive. Strong in formation fighting with reliable troops.',
                      units: const [
                        'Fyrd - Peasant spearmen',
                        'Militia - Professional guards',
                        'Royal Guard - Elite warriors',
                      ],
                      onSelected: () => _selectFaction(context, Faction.saxons),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _FactionCard(
                      faction: Faction.danes,
                      title: 'Danes',
                      subtitle: 'Northern Raiders',
                      description: 'Aggressive and fast. Excels in raids and fierce combat.',
                      units: const [
                        'Raiders - Swift looters',
                        'Heathen Outlaws - Veteran mercenaries',
                        'Blood Warriors - Fanatical berserkers',
                      ],
                      onSelected: () => _selectFaction(context, Faction.danes),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFaction(BuildContext context, Faction faction) async {
    await context.read<GameService>().selectFaction(faction);
    
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const CampaignScreen(),
        ),
      );
    }
  }
}

class _FactionCard extends StatelessWidget {
  final Faction faction;
  final String title;
  final String subtitle;
  final String description;
  final List<String> units;
  final VoidCallback onSelected;

  const _FactionCard({
    required this.faction,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.units,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                faction == Faction.saxons ? Icons.shield : Icons.local_fire_department,
                size: 64,
                color: const Color(0xFFD4AF37),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Units:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...units.map(
                (unit) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $unit',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSelected,
                  child: const Text('SELECT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}