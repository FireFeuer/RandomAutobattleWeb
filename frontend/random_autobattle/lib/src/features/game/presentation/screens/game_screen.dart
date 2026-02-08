import 'package:flutter/material.dart';
import '../../data/models/game_state_model.dart';
import '../controllers/game_controller.dart';
import '../widgets/health_bar.dart';

class GameScreen extends StatefulWidget {
  final String matchId;
  final String playerName;

  const GameScreen({
    super.key,
    required this.matchId,
    required this.playerName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      matchId: widget.matchId,
      myName: widget.playerName,
    );

    // Подписываемся на события контроллера (показ диалогов)
    _controller.onShowPerks = _showPerkSelection;
    _controller.onGameOver = _showGameOver;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showPerkSelection(List<dynamic> perks) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Choose a Perk"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: perks.map((p) => ElevatedButton(
            onPressed: () {
              _controller.selectPerk(p.toString());
              Navigator.pop(ctx);
            },
            child: Text(p.toString().toUpperCase()),
          )).toList(),
        ),
      ),
    );
  }

  void _showGameOver(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Game Over"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Закрыть диалог
              Navigator.pop(context); // Вернуться в лобби
            },
            child: const Text("Back to Lobby"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder перестраивает UI, когда контроллер делает notifyListeners()
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final state = _controller.state;
        
        // Определяем, кто есть кто для отрисовки
        final bool amIP1 = widget.playerName == state.p1Name;
        final myData = amIP1 ? {'hp': state.p1Hp, 'shield': state.p1Shield, 'max': state.maxHp} : {'hp': state.p2Hp, 'shield': state.p2Shield, 'max': state.maxHp};
        final oppData = amIP1 ? {'hp': state.p2Hp, 'shield': state.p2Shield, 'max': state.maxHp, 'name': state.p2Name} : {'hp': state.p1Hp, 'shield': state.p1Shield, 'max': state.maxHp, 'name': state.p1Name};

        return Scaffold(
          appBar: AppBar(title: Text("Round ${state.round}")),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Enemy
                HealthBar(
                  label: "Enemy: ${oppData['name']}",
                  currentHp: oppData['hp'] as double,
                  maxHp: oppData['max'] as double,
                  shield: oppData['shield'] as double,
                  color: Colors.red,
                ),
                
                const Spacer(),
                const Text("VS", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                const Spacer(),
                
                // Me
                HealthBar(
                  label: "You: ${widget.playerName}",
                  currentHp: myData['hp'] as double,
                  maxHp: myData['max'] as double,
                  shield: myData['shield'] as double,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}