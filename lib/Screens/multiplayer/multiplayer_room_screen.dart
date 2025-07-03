// lib/screens/multiplayer/multiplayer_room_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/multiplayer_service.dart';
import '../../services/auth_service.dart';

class MultiplayerRoomScreen extends StatelessWidget {
  const MultiplayerRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MultiplayerService, AuthService>(
      builder: (context, multiplayerService, authService, child) {
        final room = multiplayerService.currentRoom;
        
        if (room == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Room ${room.id.substring(0, 8)}'),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () async {
                  await multiplayerService.leaveRoom();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.exit_to_app),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room Information',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Map: ${room.mapSectionId ?? 'Not selected'}'),
                        Text('Host: ${room.hostId == authService.currentUser?.uid ? 'You' : room.hostId.substring(0, 8)}'),
                        Text('Players: ${room.playerIds.length}/${room.maxPlayers}'),
                        Text('Status: ${room.state.name}'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Players List
                Text(
                  'Players',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: room.maxPlayers,
                    itemBuilder: (context, index) {
                      if (index < room.playerIds.length) {
                        final playerId = room.playerIds[index];
                        final isHost = playerId == room.hostId;
                        final isCurrentUser = playerId == authService.currentUser?.uid;
                        
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isHost 
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFF2196F3),
                              child: Icon(
                                isHost ? Icons.star : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              isCurrentUser 
                                  ? 'You' 
                                  : 'Player ${playerId.substring(0, 8)}',
                            ),
                            subtitle: Text(
                              isHost ? 'Host' : 'Player',
                            ),
                            trailing: isCurrentUser && !isHost
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : isHost
                                    ? const Icon(Icons.star, color: Color(0xFFD4AF37))
                                    : null,
                          ),
                        );
                      } else {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: Icon(
                                Icons.person_outline,
                                color: Colors.grey[600],
                              ),
                            ),
                            title: Text(
                              'Waiting for player...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                
                // Action Buttons
                if (multiplayerService.isHost && room.state == MultiplayerGameState.waiting)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: room.playerIds.length >= 2
                          ? () => _startGame(context, multiplayerService)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'START GAME',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                
                if (room.state == MultiplayerGameState.inProgress)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _enterBattle(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'ENTER BATTLE',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Future<void> _startGame(BuildContext context, MultiplayerService multiplayerService) async {
    try {
      await multiplayerService.startGame();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game started!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start game: $e')),
        );
      }
    }
  }

  void _enterBattle(BuildContext context) {
    // Navigate to multiplayer battle screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Multiplayer battle coming soon!')),
    );
  }
}