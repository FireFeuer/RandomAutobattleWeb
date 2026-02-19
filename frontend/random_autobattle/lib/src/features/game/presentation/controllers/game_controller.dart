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
        final currentP1Wins = state.p1Wins;
        final currentP2Wins = state.p2Wins;
        
        state = GameStateModel.fromMap(data);
        
        state = state.copyWith(
          p1Wins: currentP1Wins,
          p2Wins: currentP2Wins,
        );
        
        notifyListeners();
      }
    });

    s.on('perk_offer', (data) {
      if (data != null) {
        print('perk_offer received: $data'); // Отладка
        
        if (data['wins'] != null) {
          _updateWinsFromMap(data['wins']);
        }
        
        if (onShowPerks != null) {
          onShowPerks!(data['perks']);
        }
      }
    });

    s.on('round_end', (data) {
      if (data != null) {
        print('round_end received: $data'); // Отладка
        
        // Обновляем победы
        if (data['wins'] != null) {
          _updateWinsFromMap(data['wins']);
        }
        
        bool gameOver = data['game_over'] ?? false;
        if (gameOver) {
          String winner = data['winner_name'] ?? 'Unknown';
          if (onGameOver != null) {
            onGameOver!("Игра окончена! Победитель: $winner");
          }
        } else {
          // ИСПРАВЛЕНИЕ: Явно уведомляем об изменении состояния
          // и НЕ вызываем здесь start_picking_phase - это сделает сервер
          notifyListeners();
        }
      }
    });
    
    s.on('opponent_disconnected', (_) {
      if (onGameOver != null) {
        onGameOver!("Противник отключился");
      }
    });
  }

  void requestWinsSync() {
    _socketService.emit('get_wins', {'match_id': matchId});
  }

  void _updateWinsFromMap(Map<String, dynamic> winsMap) {
    // Теперь winsMap приходит с именами в качестве ключей
    int newP1Wins = winsMap[state.p1Name] ?? state.p1Wins;
    int newP2Wins = winsMap[state.p2Name] ?? state.p2Wins;
    
    // Обновляем состояние только если значения изменились
    if (newP1Wins != state.p1Wins || newP2Wins != state.p2Wins) {
      state = state.copyWith(
        p1Wins: newP1Wins,
        p2Wins: newP2Wins,
      );
      notifyListeners();
    }
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
    _socketService.off('state_update');
    _socketService.off('perk_offer');
    _socketService.off('round_end');
    _socketService.off('opponent_disconnected');
    super.dispose();
  }
}