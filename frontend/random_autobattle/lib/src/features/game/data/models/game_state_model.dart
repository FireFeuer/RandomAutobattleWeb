// Добавляем новые поля в класс GameStateModel

class GameStateModel {
  final double p1Hp;
  final double p2Hp;
  final double p1Shield;
  final double p2Shield;
  final String p1Name;
  final String p2Name;
  final int round;
  final double maxHp;
  final int p1Wins;
  final int p2Wins;
  final int winsToWin;
  final List<dynamic> p1Abilities;  // Добавляем
  final List<dynamic> p2Abilities;  // Добавляем
  final List<dynamic> logs;
    final int p1Poison;
  final int p2Poison;
  final int p1Stun;
  final int p2Stun;

  GameStateModel({
    this.p1Hp = 1000,
    this.p2Hp = 1000,
    this.p1Shield = 0,
    this.p2Shield = 0,
    this.p1Name = "",
    this.p2Name = "",
    this.round = 0,
    this.maxHp = 1000,
    this.p1Wins = 0,
    this.p2Wins = 0,
    this.winsToWin = 5,
    this.p1Abilities = const [],  // Добавляем
    this.p2Abilities = const [],  // Добавляем
    this.logs = const [],
       this.p1Poison = 0,
    this.p2Poison = 0,
    this.p1Stun = 0,
    this.p2Stun = 0,
  });

  factory GameStateModel.fromMap(Map<String, dynamic> map) {
    final p1 = map['p1'] ?? {};
    final p2 = map['p2'] ?? {};
    
    return GameStateModel(
      p1Hp: (p1['hp'] ?? 1000).toDouble(),
      p1Shield: (p1['shield'] ?? 0).toDouble(),
      p1Name: p1['name'] ?? "Player 1",
      p1Abilities: p1['abilities'] ?? [],  // Добавляем
      
      p2Hp: (p2['hp'] ?? 1000).toDouble(),
      p2Shield: (p2['shield'] ?? 0).toDouble(),
      p2Name: p2['name'] ?? "Player 2",
      p2Abilities: p2['abilities'] ?? [],  // Добавляем
      
      round: map['round'] ?? 0,
      maxHp: (p1['max_hp'] ?? 1000).toDouble(),
      logs: map['logs'] ?? [],
            p1Poison: p1['poison_stacks'] ?? 0,
      p2Poison: p2['poison_stacks'] ?? 0,
      p1Stun: p1['stun'] ?? 0,
      p2Stun: p2['stun'] ?? 0,
      
      p1Wins: 0,
      p2Wins: 0,
    );
  }

  GameStateModel copyWith({
    double? p1Hp,
    double? p2Hp,
    double? p1Shield,
    double? p2Shield,
    String? p1Name,
    String? p2Name,
    int? round,
    int? p1Wins,
    int? p2Wins,
    List<dynamic>? p1Abilities,  // Добавляем
    List<dynamic>? p2Abilities,  // Добавляем
    List<dynamic>? logs,
  }) {
    return GameStateModel(
      p1Hp: p1Hp ?? this.p1Hp,
      p2Hp: p2Hp ?? this.p2Hp,
      p1Shield: p1Shield ?? this.p1Shield,
      p2Shield: p2Shield ?? this.p2Shield,
      p1Name: p1Name ?? this.p1Name,
      p2Name: p2Name ?? this.p2Name,
      round: round ?? this.round,
      maxHp: this.maxHp,
      p1Wins: p1Wins ?? this.p1Wins,
      p2Wins: p2Wins ?? this.p2Wins,
      winsToWin: this.winsToWin,
      p1Abilities: p1Abilities ?? this.p1Abilities,  // Добавляем
      p2Abilities: p2Abilities ?? this.p2Abilities,  // Добавляем
      logs: logs ?? this.logs, 
    );
  }
}