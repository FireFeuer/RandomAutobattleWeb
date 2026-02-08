import 'package:flutter/material.dart';
import '../../../../core/services/socket_service.dart';
import '../../../game/presentation/screens/game_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _joinIdController = TextEditingController();
  final SocketService _socket = SocketService();

  @override
  void initState() {
    super.initState();
    _setupLobbyListeners();
  }

  void _setupLobbyListeners() {
    _socket.socket.on('lobby_created', (data) {
      _goToGame(data['match_id']);
    });

    _socket.socket.on('lobby_joined', (data) {
      _goToGame(data['match_id']);
    });
  }

  void _goToGame(String matchId) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          matchId: matchId,
          playerName: _nameController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Battle Game Lobby")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Your Nickname"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  _socket.emit('create_lobby', {'name': _nameController.text});
                }
              },
              child: const Text("Create Match"),
            ),
            const Divider(height: 40),
            TextField(
              controller: _joinIdController,
              decoration: const InputDecoration(labelText: "Match ID"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _joinIdController.text.isNotEmpty) {
                  _socket.emit('join_lobby', {
                    'match_id': _joinIdController.text,
                    'name': _nameController.text
                  });
                }
              },
              child: const Text("Join Match"),
            ),
          ],
        ),
      ),
    );
  }
}