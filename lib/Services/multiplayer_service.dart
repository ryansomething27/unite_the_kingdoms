import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

enum MultiplayerGameState { waiting, inProgress, finished }
enum PlayerAction { placeTower, placeWall, startCombat, surrender }

class MultiplayerRoom {
  final String id;
  final String hostId;
  final List<String> playerIds;
  final MultiplayerGameState state;
  final String? mapSectionId;
  final Map<String, dynamic> gameData;
  final DateTime createdAt;
  final int maxPlayers;

  MultiplayerRoom({
    required this.id,
    required this.hostId,
    required this.playerIds,
    required this.state,
    this.mapSectionId,
    required this.gameData,
    required this.createdAt,
    this.maxPlayers = 4,
  });

  factory MultiplayerRoom.fromJson(Map<String, dynamic> json) {
    return MultiplayerRoom(
      id: json['id'],
      hostId: json['hostId'],
      playerIds: List<String>.from(json['playerIds']),
      state: MultiplayerGameState.values[json['state']],
      mapSectionId: json['mapSectionId'],
      gameData: json['gameData'] ?? {},
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      maxPlayers: json['maxPlayers'] ?? 4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'playerIds': playerIds,
      'state': state.index,
      'mapSectionId': mapSectionId,
      'gameData': gameData,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'maxPlayers': maxPlayers,
    };
  }
}

class MultiplayerAction {
  final String playerId;
  final PlayerAction action;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  MultiplayerAction({
    required this.playerId,
    required this.action,
    required this.data,
    required this.timestamp,
  });

  factory MultiplayerAction.fromJson(Map<String, dynamic> json) {
    return MultiplayerAction(
      playerId: json['playerId'],
      action: PlayerAction.values[json['action']],
      data: json['data'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'action': action.index,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class MultiplayerService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  MultiplayerRoom? _currentRoom;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  StreamSubscription<QuerySnapshot>? _actionsSubscription;
  List<MultiplayerAction> _recentActions = [];
  
  MultiplayerRoom? get currentRoom => _currentRoom;
  List<MultiplayerAction> get recentActions => _recentActions;
  bool get isInMultiplayer => _currentRoom != null;
  bool get isHost => _currentRoom?.hostId == _auth.currentUser?.uid;

  Future<MultiplayerRoom> createRoom(String mapSectionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final roomId = _firestore.collection('multiplayerRooms').doc().id;
    final room = MultiplayerRoom(
      id: roomId,
      hostId: user.uid,
      playerIds: [user.uid],
      state: MultiplayerGameState.waiting,
      mapSectionId: mapSectionId,
      gameData: {},
      createdAt: DateTime.now(),
    );

    await _firestore.collection('multiplayerRooms').doc(roomId).set(room.toJson());
    await _joinRoom(roomId);
    
    return room;
  }

  Future<List<MultiplayerRoom>> getAvailableRooms() async {
    final snapshot = await _firestore
        .collection('multiplayerRooms')
        .where('state', isEqualTo: MultiplayerGameState.waiting.index)
        .where('playerIds', arrayContains: _auth.currentUser?.uid, isNull: true)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => MultiplayerRoom.fromJson(doc.data()))
        .where((room) => room.playerIds.length < room.maxPlayers)
        .toList();
  }

  Future<void> joinRoom(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final roomDoc = await _firestore.collection('multiplayerRooms').doc(roomId).get();
    if (!roomDoc.exists) throw Exception('Room not found');

    final room = MultiplayerRoom.fromJson(roomDoc.data()!);
    if (room.playerIds.contains(user.uid)) {
      await _joinRoom(roomId);
      return;
    }

    if (room.playerIds.length >= room.maxPlayers) {
      throw Exception('Room is full');
    }

    if (room.state != MultiplayerGameState.waiting) {
      throw Exception('Game already started');
    }

    await _firestore.collection('multiplayerRooms').doc(roomId).update({
      'playerIds': FieldValue.arrayUnion([user.uid]),
    });

    await _joinRoom(roomId);
  }

  Future<void> _joinRoom(String roomId) async {
    await leaveRoom();

    _roomSubscription = _firestore
        .collection('multiplayerRooms')
        .doc(roomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _currentRoom = MultiplayerRoom.fromJson(snapshot.data()!);
        notifyListeners();
      }
    });

    _actionsSubscription = _firestore
        .collection('multiplayerRooms')
        .doc(roomId)
        .collection('actions')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _recentActions = snapshot.docs
          .map((doc) => MultiplayerAction.fromJson(doc.data()))
          .toList();
      notifyListeners();
    });
  }

  Future<void> leaveRoom() async {
    if (_currentRoom == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    _roomSubscription?.cancel();
    _actionsSubscription?.cancel();

    // Remove player from room
    await _firestore.collection('multiplayerRooms').doc(_currentRoom!.id).update({
      'playerIds': FieldValue.arrayRemove([user.uid]),
    });

    // If host left, assign new host or delete room
    if (_currentRoom!.hostId == user.uid) {
      final remainingPlayers = _currentRoom!.playerIds.where((id) => id != user.uid).toList();
      if (remainingPlayers.isNotEmpty) {
        await _firestore.collection('multiplayerRooms').doc(_currentRoom!.id).update({
          'hostId': remainingPlayers.first,
        });
      } else {
        await _firestore.collection('multiplayerRooms').doc(_currentRoom!.id).delete();
      }
    }

    _currentRoom = null;
    _recentActions.clear();
    notifyListeners();
  }

  Future<void> startGame() async {
    if (_currentRoom == null || !isHost) return;

    await _firestore.collection('multiplayerRooms').doc(_currentRoom!.id).update({
      'state': MultiplayerGameState.inProgress.index,
    });
  }

  Future<void> sendAction(PlayerAction action, Map<String, dynamic> data) async {
    if (_currentRoom == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final multiplayerAction = MultiplayerAction(
      playerId: user.uid,
      action: action,
      data: data,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('multiplayerRooms')
        .doc(_currentRoom!.id)
        .collection('actions')
        .add(multiplayerAction.toJson());
  }

  Future<void> updateGameData(Map<String, dynamic> data) async {
    if (_currentRoom == null || !isHost) return;

    await _firestore.collection('multiplayerRooms').doc(_currentRoom!.id).update({
      'gameData': data,
    });
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _actionsSubscription?.cancel();
    super.dispose();
  }
}