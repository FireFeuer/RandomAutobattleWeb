import 'package:flutter/material.dart';
import '../services/socket_service.dart';

// Модель состояния игры
class GameState {
  double p1Hp;
  double p2Hp;
  double p1Shield;
  double p2Shield;
  String p1Name;
  String p2Name;
  int round;

  GameState({
    this.p1Hp = 1000,
    this.p2Hp = 1000,
    this.p1Shield = 0,
    this.p2Shield = 0,
    this.p1Name = "",
    this.p2Name = "",
    this.round = 0,
  });

  GameState copyWith({
    double? p1Hp,
    double? p2Hp,
    double? p1Shield,
    double? p2Shield,
    String? p1Name,
    String? p2Name,
    int? round,
  }) {
    return GameState(
      p1Hp: p1Hp ?? this.p1Hp,
      p2Hp: p2Hp ?? this.p2Hp,
      p1Shield: p1Shield ?? this.p1Shield,
      p2Shield: p2Shield ?? this.p2Shield,
      p1Name: p1Name ?? this.p1Name,
      p2Name: p2Name ?? this.p2Name,
      round: round ?? this.round,
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoBattler',
      theme: ThemeData.dark(),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _lobbyCtrl = TextEditingController();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.socket.on('lobby_created', (data) {
      print('MenuScreen: lobby_created: $data');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              socketService: _socketService,
              matchId: data['match_id'],
              myName: _nameCtrl.text,
              isHost: true,
            ),
          ),
        );
      }
    });

    _socketService.socket.on('lobby_joined', (data) {
      print('MenuScreen: lobby_joined: $data');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              socketService: _socketService,
              matchId: data['match_id'],
              myName: _nameCtrl.text,
              isHost: false,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lobbyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Your Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_nameCtrl.text.isNotEmpty) {
                    _socketService.createLobby(_nameCtrl.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text("Create Lobby"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _lobbyCtrl,
                decoration: const InputDecoration(
                  labelText: "Lobby ID",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_lobbyCtrl.text.isNotEmpty && _nameCtrl.text.isNotEmpty) {
                    _socketService.joinLobby(_lobbyCtrl.text, _nameCtrl.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text("Join Lobby"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final SocketService socketService;
  final String matchId;
  final String myName;
  final bool isHost;

  const GameScreen({
    super.key,
    required this.socketService,
    required this.matchId,
    required this.myName,
    required this.isHost,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _state;
  List<dynamic> _offeredPerks = [];
  bool _showPerks = false;
  String _statusText = "Waiting for opponent...";
  Map<String, int> _wins = {};
  bool _listenersSet = false;

  @override
  void initState() {
    super.initState();
    _state = GameState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocketListeners();

      // Говорим серверу: "я в GameScreen и готов получать события"
      widget.socketService.socket.emit('player_ready', {'match_id': widget.matchId});
      print('📤 Sent player_ready for match ${widget.matchId}');
    });
  }

  void _setupSocketListeners() {
    if (_listenersSet) return;
    
    print("Setting up socket listeners for game screen...");
    
    widget.socketService.socket.off('perk_offer');
    widget.socketService.socket.off('state_update');
    widget.socketService.socket.off('round_start');
    widget.socketService.socket.off('round_end');
    widget.socketService.socket.off('match_start');
    widget.socketService.socket.off('opponent_disconnected');

    widget.socketService.socket.on('perk_offer', (data) {
      print("GameScreen: Received perk_offer event: $data");
      if (mounted) {
        setState(() {
          _offeredPerks = List.from(data['perks']);
          _showPerks = true;
          _state = _state.copyWith(round: data['round']);
          _statusText = "Round ${data['round']}: Choose a Perk";
          if (data['wins'] != null) {
            _wins = Map<String, int>.from(data['wins']);
          }
        });
      }
    });

    widget.socketService.socket.on('round_start', (data) {
      print("GameScreen: Received round_start event: $data");
      if (mounted) {
        setState(() {
          _statusText = "Round ${_state.round}: Fight!";
        });
      }
    });

  widget.socketService.socket.on('state_update', (data) {
    print("🎮 GameScreen: Received state_update event");
    print("   Data: $data");
    
    if (mounted) {
      setState(() {
        try {
          _state = GameState(
            p1Hp: (data['p1']['hp'] as num).toDouble(),
            p2Hp: (data['p2']['hp'] as num).toDouble(),
            p1Shield: (data['p1']['shield'] as num).toDouble(),
            p2Shield: (data['p2']['shield'] as num).toDouble(),
            p1Name: data['p1']['name']?.toString() ?? "",
            p2Name: data['p2']['name']?.toString() ?? "",
            round: data['round'],
          );
          _showPerks = false;
          _statusText = "Round ${_state.round}: Fight!";
          print("✅ Updated state: p1Hp=${_state.p1Hp}, p2Hp=${_state.p2Hp}, round=${_state.round}");
        } catch (e) {
          print("❌ Error parsing state_update: $e");
        }
      });
    }
  });

    widget.socketService.socket.on('round_end', (data) {
      print("GameScreen: Received round_end event: $data");
      if (mounted) {
        setState(() {
          if (data['game_over'] == true) {
            _statusText = "GAME OVER. Winner: ${data['winner_name'] ?? 'Unknown'}";
          } else {
            _statusText = "Round Ended. Prepare for next...";
          }
        });
      }
    });

    widget.socketService.socket.on('match_start', (data) {
      print("GameScreen: Received match_start event: $data");
      if (mounted) {
        setState(() {
          _statusText = "Match starting...";
        });
      }
    });

    widget.socketService.socket.on('opponent_disconnected', (data) {
      print("GameScreen: Received opponent_disconnected event");
      if (mounted) {
        setState(() {
          _statusText = "Opponent disconnected. Returning to menu...";
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    });

    _listenersSet = true;
  }

  void _selectPerk(String perk) {
    print("Selecting perk: $perk");
    if (mounted) {
      setState(() {
        _showPerks = false;
        _statusText = "Waiting for opponent to choose...";
      });
    }
    widget.socketService.choosePerk(widget.matchId, perk);
  }

  @override
  void dispose() {
    // Не отключаем сокет полностью, только удаляем обработчики
    if (widget.socketService.socket.connected) {
      widget.socketService.socket.off('perk_offer');
      widget.socketService.socket.off('state_update');
      widget.socketService.socket.off('round_start');
      widget.socketService.socket.off('round_end');
      widget.socketService.socket.off('match_start');
      widget.socketService.socket.off('opponent_disconnected');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Building GameScreen - status: $_statusText, round: ${_state.round}");
    
    // Определяем, кто есть кто для отображения
    bool amIP1 = _state.p1Name == widget.myName;
    if (_state.p1Name.isEmpty) {
      amIP1 = widget.isHost;
    }

    final double myHp = amIP1 ? _state.p1Hp : _state.p2Hp;
    final double oppHp = amIP1 ? _state.p2Hp : _state.p1Hp;
    final double myShield = amIP1 ? _state.p1Shield : _state.p2Shield;
    final double oppShield = amIP1 ? _state.p2Shield : _state.p1Shield;

    return Scaffold(
      appBar: AppBar(
        title: Text("Match: ${widget.matchId} | Round: ${_state.round}"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Противник
              _buildPlayerCard(
                title: "Opponent",
                hp: oppHp,
                shield: oppShield,
                color: Colors.red,
                isPlayer: false,
              ),
              
              // Статус игры
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Я
              _buildPlayerCard(
                title: "You (${widget.myName})",
                hp: myHp,
                shield: myShield,
                color: Colors.green,
                isPlayer: true,
              ),
            ],
          ),
          
          // Оверлей выбора перков
          if (_showPerks)
            Container(
              color: Colors.black.withOpacity(0.9),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "CHOOSE A PERK",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Select one perk for this round:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: _offeredPerks.map((perk) {
                          return ElevatedButton(
                            onPressed: () => _selectPerk(perk.toString()),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              perk.toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Round ${_state.round}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard({
    required String title,
    required double hp,
    required double shield,
    required Color color,
    required bool isPlayer,
  }) {
    final double hpPercentage = (hp / 1000).clamp(0.0, 1.0);
    final double shieldPercentage = shield > 0 ? (shield / 500).clamp(0.0, 1.0) : 0;

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: isPlayer ? Colors.grey[900] : null,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPlayer ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Фон полоски HP
                Container(
                  height: 30,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                
                // Полоска HP
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 30,
                  width: 300 * hpPercentage,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                
                // Полоска щита (поверх HP)
                if (shield > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 10,
                      width: 300 * shieldPercentage,
                      decoration: BoxDecoration(
                        color: Colors.blue[400],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                
                // Текст HP поверх полоски
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "${hp.toInt()} HP${shield > 0 ? ' (+${shield.toInt()} Shield)' : ''}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hpPercentage > 0.3 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "HP: ${hp.toInt()}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (shield > 0)
                  Text(
                    "Shield: +${shield.toInt()}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[400],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}