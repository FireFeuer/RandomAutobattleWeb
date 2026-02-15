import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/socket_service.dart';
import '../../../game/presentation/screens/game_screen.dart';

import '../widgets/animated_title.dart';
import '../widgets/create_game_button.dart';
import '../widgets/how_to_play_button.dart';
import '../widgets/join_game_button.dart';
import '../widgets/lobby_background.dart';
import '../widgets/music_toggle_button.dart';
import '../widgets/nickname_input.dart';
import '../widgets/colorful_match_id_input.dart';
import '../../../../core/constants/app_colors.dart';
import 'dart:async';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final SocketService _socket = SocketService();
  bool _hasTriedToSubmit = false;
  Function(dynamic)? _lobbyJoinedHandler;


  
  String? _nicknameError;           // ← новое поле для ошибки

  @override
  void initState() {
    super.initState();
      _lobbyJoinedHandler = (data) => _goToGame(data['match_id'] ?? data);
    _setupListeners();
    
  }

  @override
  void dispose() {
    _socket.socket.off('lobby_created');
    _socket.socket.off('lobby_joined');
    _nameController.dispose();
    super.dispose();
  }

  void _validateNickname() {
    setState(() {
      _nicknameError = _computeNicknameError(_nameController.text);
    });
  }

  bool get _isFormValidNow => _nicknameError == null;

  void _setupListeners() {
    _socket.socket.on('lobby_created', (data) => _goToGame(data['match_id']));
    _socket.socket.on('lobby_joined', (data) => _goToGame(data['match_id']));
    _socket.socket.on('lobby_joined', _lobbyJoinedHandler!);
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

  String? _computeNicknameError(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Никнейм не может быть пустым';
    } else if (trimmed.length == 1) {
      return 'Никнейм должен содержать минимум 2 символа';
    } else if (trimmed.length > 32) {
      return 'Никнейм не может быть длиннее 32 символов';
    }
    return null;
  }



void _showJoinDialog() {
  print('Диалог открыт');
  final joinController = TextEditingController();
  
  // Выносим переменные состояния ЗА пределы builder
  String? idError;
  bool hasTriedSubmit = false;
  bool isSubmitting = false;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return Center(
          child: Material(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(30),
            elevation: 40,
            shadowColor: Colors.black.withOpacity(0.18),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Присоединиться к игре',
                    style: GoogleFonts.montserrat(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),

                  ColorfulMatchIdInput(
                    controller: joinController,
                    errorText: hasTriedSubmit ? idError : null,
                  ),
                  const SizedBox(height: 60),

                  if (isSubmitting)
                    const CircularProgressIndicator(color: AppColors.primary),

                  if (isSubmitting) const SizedBox(height: 20),

                  JoinGameButton(
                    onPressed: () {
                      if (isSubmitting) return;

                      final id = joinController.text;
                      final name = _nameController.text.trim();

                      // Валидация ID (клиентская)
                      String? newIdError;
                      if (id.isEmpty) {
                        newIdError = 'Введите ID матча';
                      } else if (id.length != 6) {
                        newIdError = 'ID матча должен содержать ровно 6 символов';
                      }

                      // Если ID невалиден → показываем ошибку, остаёмся в диалоге
                      if (newIdError != null) {
                        setDialogState(() {
                          hasTriedSubmit = true;
                          idError = newIdError;
                        });
                        return;
                      }

                      // Проверяем никнейм
                      final nickError = _computeNicknameError(name);
                      if (nickError != null) {
                        setState(() {
                          _hasTriedToSubmit = true;
                          _nicknameError = nickError;
                        });
                        Navigator.pop(dialogContext);
                        return;
                      }

                      // Всё ок → запускаем отправку
                      setDialogState(() {
                        hasTriedSubmit = true;
                        idError = null;
                        isSubmitting = true;
                      });

                      // Отправка
                      print('Отправляем join_lobby → id: "$id", name: "$name"');

                      _socket.socket.off('lobby_joined');

                      final joinedHandler = (data) {
                        print('Получен lobby_joined: $data');
                        final matchId = (data is Map && data['match_id'] != null)
                            ? data['match_id'] as String
                            : id;

                        Navigator.pop(dialogContext);
                        _goToGame(matchId);

                        _socket.socket.on('lobby_joined', _lobbyJoinedHandler!);
                      };

                      final errorHandler = (errData) {
                        print('Получен join_error: $errData');
                        String message = 'Не удалось присоединиться. Неверный ID или игра уже началась.';
                        if (errData is Map && errData['message'] != null) {
                          message = errData['message'] as String;
                        } else if (errData is String) {
                          message = errData;
                        }

                        setDialogState(() {
                          isSubmitting = false;
                          idError = message;
                        });

                        _socket.socket.on('lobby_joined', _lobbyJoinedHandler!);
                      };

                      _socket.socket.once('lobby_joined', joinedHandler);
                      _socket.socket.once('join_error', errorHandler);

                      _socket.emit('join_lobby', {'match_id': id, 'name': name});
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const LobbyBackground(),
          const Positioned(top: 40, left: 40, child: MusicToggleButton()),
          Positioned(
            bottom: 40,
            right: 40,
            child: HowToPlayButton(onPressed: () {}),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnimatedTitle(),
                const SizedBox(height: 90),
                
                // ← обновлённый вызов
                NicknameInput(
                  controller: _nameController,
                  errorText: _hasTriedToSubmit ? _nicknameError : null,   // ← теперь только после попытки
                ),
                
                const SizedBox(height: 70),
                CreateGameButton(
                  onPressed: () {
                    setState(() => _hasTriedToSubmit = true);

                    final name = _nameController.text.trim();
                    _nicknameError = _computeNicknameError(name);   // напрямую

                    if (_nicknameError == null) {
                      _socket.emit('create_lobby', {'name': name});
                    }
                  },
                ),
                const SizedBox(height: 24),
                JoinGameButton(onPressed: _showJoinDialog),
              ],
            ),
          ),
        ],
      ),
    );
  }


}