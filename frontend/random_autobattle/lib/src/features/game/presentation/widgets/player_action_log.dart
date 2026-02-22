import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class PlayerActionLog extends StatefulWidget {
  final List<dynamic> logs;
  final String playerName;
  final bool isLeft;

  const PlayerActionLog({
    super.key,
    required this.logs,
    required this.playerName,
    required this.isLeft,
  });

  @override
  State<PlayerActionLog> createState() => _PlayerActionLogState();
}

class _PlayerActionLogState extends State<PlayerActionLog> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listViewKey = GlobalKey();
  
  bool _showScrollButton = false;
  bool _userInteracted = false;
  bool _isAutoScrolling = false;
  
  double? _savedScrollPosition;
  int _lastLogCount = 0;
  
  // Анимация для новых элементов
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

@override
void didUpdateWidget(PlayerActionLog oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  final playerLogs = _getPlayerLogs();
  final oldPlayerLogs = oldWidget.logs.where((log) {
    final logMap = log as Map<String, dynamic>;
    return logMap['player_name'] == widget.playerName;
  }).toList();
  
  // Если добавились новые логи
  if (playerLogs.length > oldPlayerLogs.length) {
    _fadeController.forward(from: 0.0);
    
    // Сохраняем текущую позицию прокрутки, только если пользователь НЕ внизу
    if (_scrollController.hasClients && 
        !_isNearBottom() && 
        _userInteracted) {
      _savedScrollPosition = _scrollController.position.pixels;
    }
    
    // Плавно обновляем список
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNewLogs();
    });
  }
  
  _lastLogCount = playerLogs.length;
}

bool _isNearBottom() {
  if (!_scrollController.hasClients) return false;
  return _scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent - 100;
}

void _handleNewLogs() {
  if (!_scrollController.hasClients) return;
  
  // Проверяем, находится ли пользователь почти внизу списка (допуск 50 пикселей)
  final isAtBottom = _scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent - 50;
  
  // Если пользователь внизу списка - плавно скроллим к новым логам
  if (isAtBottom) {
    _isAutoScrolling = true;
    // Сбрасываем флаг взаимодействия, чтобы следующие логи снова скроллились
    _userInteracted = false;
    // Прячем кнопку, так как мы и так внизу
    _showScrollButton = false;
    
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    ).then((_) {
      if (mounted) {
        _isAutoScrolling = false;
      }
    });
  } else {
    // Если пользователь НЕ внизу списка - НЕ скроллим!
    // Просто отмечаем, что есть непрочитанные сообщения
    setState(() {
      _showScrollButton = true;
    });
    
    // Сохраняем позицию, если нужно
    if (_savedScrollPosition != null) {
      _scrollController.jumpTo(_savedScrollPosition!);
      _savedScrollPosition = null;
    }
  }
}

  List<dynamic> _getPlayerLogs() {
    return widget.logs.where((log) {
      final logMap = log as Map<String, dynamic>;
      return logMap['player_name'] == widget.playerName;
    }).toList();
  }

void _onScroll() {
  if (!_scrollController.hasClients || _isAutoScrolling) return;

  final position = _scrollController.position;
  
  // Используем maxScrollExtent с проверкой на бесконечность, чтобы избежать ошибок
  final maxScroll = position.maxScrollExtent;
  final currentScroll = position.pixels;
  final isAtBottom = maxScroll == 0.0 || currentScroll >= maxScroll - 100;
  
  // Показываем кнопку, если мы не внизу списка
  final show = !isAtBottom;
  
  if (show != _showScrollButton) {
    setState(() {
      _showScrollButton = show;
    });
  }
  
  // Определение ручного скролла
  final activity = position.activity;
  final isUserDragging = activity is DragScrollActivity;
  
  // Если пользователь активно скроллит
  if (isUserDragging) {
    // Получаем скорость из активности
    final velocity = activity.velocity;
    
    // velocity < 0 означает движение вверх (к началу списка)
    final isScrollingUp = velocity < 0;
    
    // Если пользователь скроллит вверх от низа - значит он хочет почитать старые логи
    if (isScrollingUp && !isAtBottom) {
      _userInteracted = true;
      _savedScrollPosition = currentScroll;
    }
    
    // Если пользователь скроллит вниз
    if (!isScrollingUp) {
      // Проверяем, доскроллил ли он до конца
      if (isAtBottom) {
        // Если он внизу, сбрасываем флаг взаимодействия
        // Теперь новые логи будут снова автоматически прокручиваться
        _userInteracted = false;
        _savedScrollPosition = null;
        _showScrollButton = false;
      }
    }
  }
}

void _scrollToBottom() {
  if (!_scrollController.hasClients) return;
  
  _isAutoScrolling = true;
  _userInteracted = false;
  _savedScrollPosition = null;
  _showScrollButton = false;
  
  _scrollController.animateTo(
    _scrollController.position.maxScrollExtent,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutCubic,
  ).then((_) {
    if (mounted) {
      _isAutoScrolling = false;
    }
  });
}

  String _getActionText(Map<String, dynamic> log) {
    final actionType = log['action_type'] as String;
    final abilityName = log['ability_name'] as String;
    final targetName = log['target_name'] as String?;
    final value = log['value'] as int;
    final isCrit = log['is_crit'] as bool? ?? false;
    final stacks = log['stacks'] as int? ?? 1;

    switch (actionType) {
      case 'attack':
        final critText = isCrit ? ' КРИТИЧЕСКИЙ УДАР!' : '';
        return '$abilityName наносит $value ед. урона$critText по $targetName';
      
      case 'heal':
        return '$abilityName восстанавливает $value ед. здоровья';
      
      case 'crit':
        return '$abilityName наносит критический урон: $value ед.';
      
      case 'poison_apply':
        return '$abilityName отравляет $targetName на $stacks ст. (${value} урона/тик)';
      
      case 'poison_damage':
        return '$targetName получает $value ед. урона от яда';
      
      case 'shield_gain':
        return '$abilityName даёт +$value ед. щита';
      
      case 'reflect':
        return '$abilityName отражает $value ед. урона в $targetName';
      
      case 'lifesteal':
        return '$abilityName восстанавливает $value ед. здоровья (вампиризм)';
      
      case 'stun':
        return '$abilityName оглушает $targetName на ${(value / 1000).toStringAsFixed(1)} сек.';
      
      default:
        return '$abilityName: $value ед.';
    }
  }

  String _getSpeedText(Map<String, dynamic> log) {
    final minDelay = log['min_delay'];
    final maxDelay = log['max_delay'];
    final actualDelay = log['actual_delay'];
    
    if (minDelay != null && maxDelay != null && actualDelay != null) {
      final avgDelay = (minDelay + maxDelay) / 2;
      final speedDiff = actualDelay - avgDelay;
      
      String speedComment = '';
      // Цвета лучше брать из темы или AppColors, но оставим как было для примера
      Color speedColor = Colors.grey;
      
      if (speedDiff < -0.3) {
        speedComment = '⚡ очень быстро';
        speedColor = Colors.green;
      } else if (speedDiff < -0.1) {
        speedComment = '⚡ быстро';
        speedColor = Colors.lightGreen;
      } else if (speedDiff > 0.3) {
        speedComment = '🐢 медленно';
        speedColor = Colors.orange;
      } else if (speedDiff > 0.1) {
        speedComment = '🐢 чуть медленнее';
        speedColor = Colors.amber;
      } else {
        speedComment = '✓ нормально';
        speedColor = Colors.blue;
      }
      
      return '$speedComment • ${actualDelay.toStringAsFixed(2)}с (норма: ${avgDelay.toStringAsFixed(1)}с)';
    }
    return '';
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerLogs = _getPlayerLogs();
    // Флаг isNewLog нужен, чтобы понять, появился ли элемент только что в этом кадре
    final isNewLog = playerLogs.length > _lastLogCount;

    return Container(
      width: 500,
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.05),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Список логов
            ListView.builder(
              key: _listViewKey,
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: playerLogs.length,
              itemBuilder: (context, index) {
                final log = playerLogs[index] as Map<String, dynamic>;
                final isLatest = index == playerLogs.length - 1;
                // Анимация появления только для последнего элемента, если список вырос
                final shouldAnimate = isLatest && isNewLog;
                
                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: shouldAnimate ? 300 : 0),
                  child: _buildLogCard(log, shouldAnimate),
                );
              },
            ),
            
            // Кнопка прокрутки вниз
            if (_showScrollButton)
              Positioned(
                bottom: 24,
                right: 24,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  elevation: 8,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                  child: InkWell(
                    onTap: _scrollToBottom,
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              
            // Индикатор новых сообщений
            if (_showScrollButton && _userInteracted)
              Positioned(
                bottom: 80,
                right: 24,
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  child: InkWell(
                    onTap: _scrollToBottom,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Новые действия',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, bool isNew) {
    // Безопасное получение цвета
    Color rarityColor = Colors.grey;
    try {
      final colorString = (log['rarity_color'] as String).replaceFirst('#', '0xFF');
      rarityColor = Color(int.parse(colorString));
    } catch (e) {
      // Fallback цвет если парсинг не удался
      rarityColor = Colors.grey; 
    }

    final speedText = _getSpeedText(log);
    final actionText = _getActionText(log);

    return AnimatedContainer(
      duration: Duration(milliseconds: isNew ? 400 : 0),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: isNew ? 0.8 : 1.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: rarityColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Верхняя строка: время и уровень
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        log['timestamp'] as String? ?? '',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: rarityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (log['stacks'] != null && (log['stacks'] as int) > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: rarityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Уровень ${log['stacks']}',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: rarityColor,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 14),
                
                // Название способности
                Text(
                  log['ability_name'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Действие
                Text(
                  actionText,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                
                // Информация о скорости
                if (speedText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: rarityColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.speed,
                            size: 16,
                            color: rarityColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              speedText,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: rarityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}