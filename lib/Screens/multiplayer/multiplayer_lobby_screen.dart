// lib/screens/multiplayer/multiplayer_lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../services/multiplayer_service.dart';
import '../../services/config_service.dart';
import 'multiplayer_room_screen.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  List<MultiplayerRoom> _availableRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await context.read<MultiplayerService>().getAvailableRooms();
      setState(() {
        _availableRooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rooms: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Create Room Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateRoomDialog(),
              icon: const Icon(Icons.add),
              label: const Text('CREATE ROOM'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          // Available Rooms
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _availableRooms.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No active rooms',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create a room to start playing!',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _availableRooms.length,
                        itemBuilder: (context, index) {
                          final room = _availableRooms[index];
                          return _RoomCard(
                            room: room,
                            onJoin: () => _joinRoom(room.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateRoomDialog() async {
    final mapSections = await ConfigService.loadMapSections();
    if (!mounted) return;
    final selectedMapId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a map for multiplayer battle:'),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: math.min(mapSections.length, 10),
                itemBuilder: (context, index) {
                  final section = mapSections[index];
                  return ListTile(
                    title: Text(section.name),
                    subtitle: Text(section.kingdom.toUpperCase()),
                    trailing: section.isCastle 
                        ? const Icon(Icons.castle, color: Colors.red)
                        : null,
                    onTap: () => Navigator.of(context).pop(section.id),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedMapId != null) {
      await _createRoom(selectedMapId);
    }
  }

  Future<void> _createRoom(String mapSectionId) async {
    try {
      final multiplayerService = context.read<MultiplayerService>();
      await multiplayerService.createRoom(mapSectionId);
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MultiplayerRoomScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create room: $e')),
        );
      }
    }
  }

  Future<void> _joinRoom(String roomId) async {
    try {
      final multiplayerService = context.read<MultiplayerService>();
      await multiplayerService.joinRoom(roomId);
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MultiplayerRoomScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join room: $e')),
        );
      }
    }
  }
}

class _RoomCard extends StatelessWidget {
  final MultiplayerRoom room;
  final VoidCallback onJoin;

  const _RoomCard({
    required this.room,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFD4AF37),
          child: Text(
            '${room.playerIds.length}/${room.maxPlayers}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text('Room ${room.id.substring(0, 8)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Map: ${room.mapSectionId ?? 'Unknown'}'),
            Text('Created: ${_formatTime(room.createdAt)}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onJoin,
          child: const Text('JOIN'),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}