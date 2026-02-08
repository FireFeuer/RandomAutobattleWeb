import 'package:flutter/material.dart';
import '../../../../core/services/socket_service.dart';
import '../../data/models/game_state_model.dart';

class GameController extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  final String matchId;
  final String myName;

  GameStateModel state = GameStateModel();
  
  // События для UI (показать диалог, показать экран победы)
  Function(List<dynamic> perks)? onShowPerks;
  Function(String resultText)? onGameOver;

  GameController({required this.matchId, required this.myName}) {
    _initListeners();
    _notifyReady();
  }

  void _initListeners() {
    final s = _socketService.socket;

    s.on('state_update', (data) {
      if (data != null) {
        state = GameStateModel.fromMap(data);
        notifyListeners(); // Обновляем UI
      }
    });

    s.on('perk_offer', (data) {
      if (onShowPerks != null) {
        onShowPerks!(data['perks']);
      }
    });

    s.on('round_end', (data) {
      bool gameOver = data['game_over'];
      if (gameOver) {
        String winner = data['winner_name'];
        if (onGameOver != null) {
          onGameOver!("Game Over! Winner: $winner");
        }
      }
    });
    
    // Очистка при отключении оппонента
    s.on('opponent_disconnected', (_) {
       if (onGameOver != null) onGameOver!("Opponent Disconnected");
    });
  }

  void _notifyReady() {
    _socketService.emit('player_ready', {'match_id': matchId});
  }

  void selectPerk(String perkId) {
    _socketService.emit('choose_perk', {
      'match_id': matchId,
      'perk_id': perkId
    });
  }

  @override
  void dispose() {
    // Отписываемся от событий, чтобы не было утечек памяти
    _socketService.off('state_update');
    _socketService.off('perk_offer');
    _socketService.off('round_end');
    _socketService.off('opponent_disconnected');
    super.dispose();
  }
}