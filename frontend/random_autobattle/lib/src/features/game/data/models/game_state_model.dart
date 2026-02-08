class GameStateModel {
  final double p1Hp;
  final double p2Hp;
  final double p1Shield;
  final double p2Shield;
  final String p1Name;
  final String p2Name;
  final int round;
  final double maxHp;

  GameStateModel({
    this.p1Hp = 1000,
    this.p2Hp = 1000,
    this.p1Shield = 0,
    this.p2Shield = 0,
    this.p1Name = "",
    this.p2Name = "",
    this.round = 0,
    this.maxHp = 1000,
  });

  // Создание из JSON (от Python сервера)
  factory GameStateModel.fromMap(Map<String, dynamic> map) {
    final p1 = map['p1'] ?? {};
    final p2 = map['p2'] ?? {};
    
    return GameStateModel(
      p1Hp: (p1['hp'] ?? 1000).toDouble(),
      p1Shield: (p1['shield'] ?? 0).toDouble(),
      p1Name: p1['name'] ?? "Player 1",
      
      p2Hp: (p2['hp'] ?? 1000).toDouble(),
      p2Shield: (p2['shield'] ?? 0).toDouble(),
      p2Name: p2['name'] ?? "Player 2",
      
      round: map['round'] ?? 0,
      maxHp: (p1['max_hp'] ?? 1000).toDouble(),
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
    );
  }
}