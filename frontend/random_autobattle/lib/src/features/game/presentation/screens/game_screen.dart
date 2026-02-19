import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/grid_background.dart';
import '../../data/models/game_state_model.dart';
import '../controllers/game_controller.dart';
import '../widgets/health_bar.dart';
import '../widgets/perk_dialog.dart';
import '../widgets/round_progress_indicator.dart';
import '../widgets/ability_icon.dart';

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
  double _copyIconScale = 1.0;
  final int winsToWin = 5;

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      matchId: widget.matchId,
      myName: widget.playerName,
    );

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
      builder: (ctx) => PerkDialog(
        perks: perks,
        onPerkSelected: _controller.selectPerk,
      ),
    );
  }

  void _showGameOver(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.inputBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Игра окончена',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.errorRed,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'В лобби',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: widget.matchId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Код комнаты скопирован!',
          style: GoogleFonts.montserrat(),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Фон с сеткой
          const GridBackground(
            opacity: 0.02,
            mainStep: 60,
          ),
          
          // Основной контент
          ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              final state = _controller.state;

              final bool amIP1 = widget.playerName == state.p1Name;
              final myData = {
                'hp': amIP1 ? state.p1Hp : state.p2Hp,
                'shield': amIP1 ? state.p1Shield : state.p2Shield,
                'max': state.maxHp,
                'name': widget.playerName,
              };
              final oppData = {
                'hp': amIP1 ? state.p2Hp : state.p1Hp,
                'shield': amIP1 ? state.p2Shield : state.p1Shield,
                'max': state.maxHp,
                'name': amIP1 ? state.p2Name : state.p1Name,
              };

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Индикатор для противника (слева) - всегда показывает победы противника
                          RoundProgressIndicator(
                            currentWins: amIP1 ? state.p2Wins : state.p1Wins,  // Если я P1, показываем победы P2, иначе победы P1
                            totalRoundsNeeded: winsToWin,
                            isForPlayer: false,
                          ),
                          
                          // Индикатор для текущего игрока (справа) - всегда показывает мои победы
                          RoundProgressIndicator(
                            currentWins: amIP1 ? state.p1Wins : state.p2Wins,  // Если я P1, показываем победы P1, иначе победы P2
                            totalRoundsNeeded: winsToWin,
                            isForPlayer: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

// Контейнер для способностей и полосок здоровья
Column(
  children: [
    // Способности (на одном уровне для обоих игроков)
    Row(
      children: [
        // Способности левого игрока (противника) - прижаты к левому краю
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: (amIP1 ? state.p2Abilities : state.p1Abilities).map<Widget>((ability) {
                  return AbilityIcon(
                    abilityData: ability,
                    isLeft: true,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        
        // Способности правого игрока (текущего) - прижаты к правому краю
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: (amIP1 ? state.p1Abilities : state.p2Abilities).map<Widget>((ability) {
                  return AbilityIcon(
                    abilityData: ability,
                    isLeft: false,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    ),
    
    const SizedBox(height: 8), // Минимальный отступ до полосок здоровья
    
    // Полоски здоровья
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Левый игрок (противник)
        HealthBar(
          playerName: oppData['name'] as String,
          currentHp: oppData['hp'] as double,
          maxHp: oppData['max'] as double,
          shield: oppData['shield'] as double,
          isLeft: true,
        ),
        
        // Правый игрок (я)
        HealthBar(
          playerName: myData['name'] as String,
          currentHp: myData['hp'] as double,
          maxHp: myData['max'] as double,
          shield: myData['shield'] as double,  // Исправлено: было oppData['shield']
          isLeft: false,
        ),
      ],
    ),
  ],
),

const Spacer(),
                      
                      // Информация в левом нижнем углу
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Раунд ${state.round}',
                              style: GoogleFonts.montserrat(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Комната: ${widget.matchId}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) {
                                    setState(() {
                                      _copyIconScale = 1.2;
                                    });
                                  },
                                  onExit: (_) {
                                    setState(() {
                                      _copyIconScale = 1.0;
                                    });
                                  },
                                  child: GestureDetector(
                                    onTap: _copyRoomCode,
                                    child: AnimatedScale(
                                      duration: const Duration(milliseconds: 200),
                                      scale: _copyIconScale,
                                      child: Icon(
                                        Icons.copy,
                                        color: AppColors.inputBorder,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );         
            },
          ),
        ],
        
      ),
      
    );
  }
}