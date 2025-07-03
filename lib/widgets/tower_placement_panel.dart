// lib/widgets/tower_placement_panel.dart
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/config_service.dart';
import 'dart:math' as math;

class TowerPlacementPanel extends StatefulWidget {
  final Faction faction;
  final int availableSilver;
  final Function(Tower) onTowerSelected;

  const TowerPlacementPanel({
    super.key,
    required this.faction,
    required this.availableSilver,
    required this.onTowerSelected,
  });

  @override
  State<TowerPlacementPanel> createState() => _TowerPlacementPanelState();
}

class _TowerPlacementPanelState extends State<TowerPlacementPanel> {
  Map<String, dynamic>? towerStats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTowerStats();
  }

  Future<void> _loadTowerStats() async {
    final stats = await ConfigService.loadTowerStats();
    setState(() {
      towerStats = stats;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || towerStats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFFF5E6D3),
        border: Border(
          top: BorderSide(color: Color(0xFF3E2723), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Place Towers & Walls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E2723),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                // Spawn towers
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Spawn Towers',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: [
                            for (int tier = 1; tier <= 3; tier++)
                              _buildTowerButton(
                                'Tier $tier Spawn',
                                towerStats!['spawn_towers']['tier$tier']['cost'],
                                () => _createSpawnTower(tier),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Archer towers
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Archer Towers',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: [
                            for (int tier = 1; tier <= 3; tier++)
                              _buildTowerButton(
                                'Tier $tier Archer',
                                towerStats!['archer_towers']['tier$tier']['cost'],
                                () => _createArcherTower(tier),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Wall tool
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Walls',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Drag to draw walls\n1 silver per 10 units',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTowerButton(String name, int cost, VoidCallback onPressed) {
    final canAfford = widget.availableSilver >= cost;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canAfford ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canAfford 
                ? const Color(0xFF3E2723) 
                : Colors.grey,
            foregroundColor: const Color(0xFFD4AF37),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '$cost silver',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Tower _createSpawnTower(int tier) {
    final tierKey = 'tier$tier';
    final stats = towerStats!['spawn_towers'][tierKey];
    
    return Tower(
      id: 'temp_spawn_$tier',
      type: TowerType.spawn,
      tier: UnitTier.values[tier - 1],
      faction: widget.faction,
      cost: stats['cost'],
      lifeline: stats['lifeline'],
      maxTargets: stats['maxTargets'],
      spawnRate: stats['spawnRate'].toDouble(),
      position: const math.Point(0, 0), // Will be set when placed
    );
  }

  Tower _createArcherTower(int tier) {
    final tierKey = 'tier$tier';
    final stats = towerStats!['archer_towers'][tierKey];
    
    return Tower(
      id: 'temp_archer_$tier',
      type: TowerType.archer,
      tier: UnitTier.values[tier - 1],
      faction: widget.faction,
      cost: stats['cost'],
      lifeline: 1, // Archer towers don't use lifeline
      maxTargets: 0, // Archer towers don't target other towers
      spawnRate: 0, // Archer towers don't spawn units
      range: stats['range'].toDouble(),
      damage: stats['damage'],
      accuracy: stats['accuracy'].toDouble(),
      fireRate: stats['fireRate'].toDouble(),
      position: const math.Point(0, 0), // Will be set when placed
    );
  }
}