import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class AbilityIcon extends StatefulWidget {
  final Map<String, dynamic> abilityData;
  final bool isLeft;
  final String playerName;
  final Stream<Map<String, dynamic>> activationStream;

  const AbilityIcon({
    super.key,
    required this.abilityData,
    required this.isLeft,
    required this.playerName,
    required this.activationStream,
  });

  @override
  State<AbilityIcon> createState() => _AbilityIconState();
}

class _AbilityIconState extends State<AbilityIcon> with TickerProviderStateMixin {
  bool _isHovered = false;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  StreamSubscription? _activationSub;

  final List<Widget> _floatingElements = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _activationSub = widget.activationStream.listen((data) {
  print('🎯 ABILITY ICON [${widget.abilityData['name_ru']}]');
  print('   Data received: $data');
  print('   Comparing ability: "${data['ability_name']}" == "${widget.abilityData['id']}"');
  print('   Comparing player: "${data['player_name']}" == "${widget.playerName}"');
  print('   is_heal: ${data['is_heal']}, value: ${data['value']}');
  
  if (data['ability_name'] == widget.abilityData['id'] &&
      data['player_name'] == widget.playerName) {
    
    print('✅ MATCH FOUND! Adding animation for ${widget.abilityData['name_ru']}');
    
    _pulseController.forward(from: 0.0);

    String effectType = data['effect_type']?.toString().toUpperCase() ?? '';
    int value = data['value'] ?? 0;
    bool isHeal = data['is_heal'] ?? false;
    String abilityName = data['ability_name'] ?? '';
    bool isCrit = data['is_crit'] == true;

    // ОБРАБОТКА СТАНА (включая стан от chain_lightning)
    if (effectType == 'STUN') {
      String stunText = value > 0 ? 'ОГЛУШЕНИЕ ${value ~/ 10}с' : 'ОГЛУШЕНИЕ';
      _addFloatingElement(stunText, const Color.fromARGB(255, 26, 26, 122), false, Icons.bolt, offset: Offset.zero);
      return;
    }

    // Для chain_lightning - показываем урон (обычная обработка)
    if (abilityName == 'chain_lightning' && value > 0) {
      Color dmgColor = isCrit ? Colors.orange : Colors.red;
      String text = isCrit ? '-$value! КРИТ' : '-$value';
      _addFloatingElement(text, dmgColor, false, null, offset: Offset.zero);
      return;
    }

    // Специальная обработка для щита
    if (effectType == 'SHIELD' || abilityName == 'divine_shield' || abilityName == 'barrier') {
       _addFloatingElement('БЛОК', Colors.blueAccent, false, Icons.shield, offset: Offset.zero);
       return;
    }

    // Логика двойного текста (урон + хил) для вампиризма
    if (effectType == 'LIFESTEAL' || abilityName == 'vampiric_bite' || abilityName == 'vampiric_bite_heal') {
        if (abilityName == 'vampiric_bite_heal') {
            _addFloatingElement('+$value', Colors.green, true, Icons.favorite, offset: const Offset(8, -5));
        } else {
            String damageText = isCrit ? '-$value! КРИТ' : '-$value';
            _addFloatingElement(damageText, isCrit ? Colors.orange : Colors.red, false, null, offset: const Offset(-8, 0));
        }
        return;
    }

    // Обычный хил или урон
    if (isHeal || effectType == 'HEAL') {
      _addFloatingElement('+$value', Colors.green, true, Icons.favorite, offset: Offset.zero);
    } else if (value > 0) {
      Color dmgColor = isCrit ? Colors.orange : Colors.red;
      String text = isCrit ? '-$value! КРИТ' : '-$value';
      _addFloatingElement(text, dmgColor, false, null, offset: Offset.zero);
    }
  }
});
  }

void _addFloatingElement(String text, Color color, bool isHeal, IconData? icon, {Offset offset = Offset.zero}) {
    final clampedOffset = Offset(
      offset.dx.clamp(-0.0, 10.0),
      offset.dy.clamp(-20.0, 20.0),
    );
    
    final key = UniqueKey(); // Создаем ключ
    
    setState(() {
      _floatingElements.add(
        _FloatingNotification(
          key: key, // Используем ключ
          text: text,
          color: color,
          isHeal: isHeal,
          icon: icon,
          customOffset: clampedOffset,
          onComplete: () {
            if (mounted) {
              setState(() {
                // Удаляем по ключу, а не первый элемент
                _floatingElements.removeWhere((element) => element.key == key);
              });
            }
          },
        ),
      );
    });
  }

  void _triggerFloatingEffect(Map<String, dynamic> data) {
  final value = data['value'];
  final isHeal = data['is_heal'] == true;
  final isCrit = data['is_crit'] == true;
  final effectType = data['effect_type'] as String?;

  Color color = isHeal ? Colors.blue : Colors.redAccent;
  String text = value.toString();
  IconData? icon;

  if (isCrit) {
    color = Colors.orange;
    text = '$text КРИТ!';
  }

  if (effectType == 'REFLECT') {
    color = Colors.purpleAccent;
    icon = Icons.shield;
  } else if (effectType == 'STUN') {
    color = const Color.fromARGB(255, 63, 57, 9);
    icon = Icons.bolt;
    text = 'Оглушение';
  } else if (effectType == 'POISON_APPLY') {
    color = Colors.green;
    icon = Icons.coronavirus;
  }

  final key = UniqueKey();
  setState(() {
    _floatingElements.add(
      _FloatingNotification(
        key: key,
        text: text,
        color: color,
        isHeal: isHeal,
        icon: icon,
        onComplete: () {
          if (mounted) {
            setState(() => _floatingElements.removeWhere((e) => e.key == key));
          }
        },
      ),
    );
  });
}

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'rare':
        return const Color(0xFF72c144);
      case 'epic':
        return const Color(0xFF77136f);
      case 'legendary':
        return const Color(0xFFd2b61e);
      case 'common':
      default:
        return AppColors.gridLine;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.split(' ');
    if (words.length > 1) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.length > 1 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
  }

  String _getRarityName(String rarity) {
    switch (rarity) {
      case 'rare':
        return 'Редкая';
      case 'epic':
        return 'Эпическая';
      case 'legendary':
        return 'Легендарная';
      case 'common':
      default:
        return 'Обычная';
    }
  }

void _showTooltip() {
  if (_isHovered) return;
  _isHovered = true;

  final overlay = Overlay.of(context);
  final renderBox = context.findRenderObject() as RenderBox;
  final position = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;

  _overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      left: widget.isLeft ? position.dx : null,
      right: widget.isLeft ? null : MediaQuery.of(context).size.width - position.dx - size.width,
      top: position.dy + size.height + 2, // Уменьшил отступ
      child: Material(
        color: Colors.transparent,
        child: _buildTooltipContent(),
      ),
    ),
  );

  overlay.insert(_overlayEntry!);
}

  void _hideTooltip() {
    _isHovered = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _activationSub?.cancel();
    _pulseController.dispose();
    _focusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

    String _getDelayRange(Map<String, dynamic> abilityData) {
    if (abilityData['id'] == 'magic_arrow') return 'Скорость: 1.2-2.0 сек';
    if (abilityData['id'] == 'fireball') return 'Скорость: 2.0-4.0 сек';
    if (abilityData['id'] == 'heavy_strike') return 'Скорость: 4.5-6.5 сек';
    if (abilityData['id'] == 'holy_light') return 'Скорость: 3.5-5.0 сек';
    if (abilityData['id'] == 'chain_lightning') return 'Скорость: 2.0-4.4 сек';
    if (abilityData['id'] == 'ice_touch') return 'Скорость: 4.0-6.0 сек';
    if (abilityData['id'] == 'berserker_strike') return 'Скорость: 3.5-5.0 сек';
    if (abilityData['id'] == 'vampiric_bite') return 'Скорость: 3.0-4.5 сек';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.abilityData['name_ru'] as String;
    final rarity = widget.abilityData['rarity'] as String;
    int stacks = 1;

  if (widget.abilityData.containsKey('stacks')) {
    stacks = widget.abilityData['stacks'] as int? ?? 1;
  } else if (widget.abilityData.containsKey('p1_stacks') && widget.isLeft) {
    // Если это левый игрок и есть p1_stacks
    stacks = widget.abilityData['p1_stacks'] as int? ?? 1;
  } else if (widget.abilityData.containsKey('p2_stacks') && !widget.isLeft) {
    // Если это правый игрок и есть p2_stacks
    stacks = widget.abilityData['p2_stacks'] as int? ?? 1;
  }


    final rarityColor = _getRarityColor(rarity);
    final initials = _getInitials(name);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _showTooltip(),
      onExit: (_) => _hideTooltip(),
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            _showTooltip();
          } else {
            _hideTooltip();
          }
        },
        child: SizedBox(
          width: 80, // Фиксированный размер контейнера
          height: 80, // предотвращает "дерганье" соседних элементов при scale
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        rarityColor.withOpacity(0.3),
                        rarityColor.withOpacity(0.6),
                      ],
                    ),
                    border: Border.all(
                      color: rarityColor.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: rarityColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Кружок уровня прокачки (stacks)
              if (stacks > 1)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: rarityColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '$stacks',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              // Вылетающие эффекты
              ..._floatingElements,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTooltipContent() {
    final name = widget.abilityData['name_ru'] as String;
    final rarity = widget.abilityData['rarity'] as String;
    final description = widget.abilityData['description'] as String;
    final stats = widget.abilityData['stats'] as String;
    final stacks = widget.abilityData['stacks'] as int? ?? 1;
    final stackable = widget.abilityData['stackable'] as bool? ?? true;
      double baseDuration = 1.0;
  double totalDuration = baseDuration + (stacks - 1) * 0.5;

    final rarityColor = _getRarityColor(rarity);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rarityColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getRarityName(rarity),
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: rarityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textDark.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
                    Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDelayRange(widget.abilityData),
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: AppColors.textDark.withOpacity(0.8),
                  ),
                ),
                // Если это способность с станом, показываем дополнительную информацию
                if (widget.abilityData['type'] == 'stun' || widget.abilityData['id'] == 'ice_touch') 
                  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      'Длительность: ${totalDuration.toStringAsFixed(1)} сек (уровень $stacks)',
      style: GoogleFonts.montserrat(
        fontSize: 11,
        color: const Color.fromARGB(255, 87, 82, 35),
      ),
    ),
  ),
              ],
            ),
          ),
          if (stacks > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: rarityColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stackable
                        ? 'Уровень $stacks'
                        : 'Не усиливается при повторе',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: stackable ? rarityColor : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Виджет для анимации вылетающего текста ВНИЗ
class _FloatingNotification extends StatefulWidget {
  final String text;
  final Color color;
  final bool isHeal;
  final IconData? icon;
  final Offset customOffset;
  final VoidCallback onComplete;

  const _FloatingNotification({
    super.key,
    required this.text,
    required this.color,
    required this.isHeal,
    this.icon,
    this.customOffset = Offset.zero,
    required this.onComplete,
  });

  @override
  State<_FloatingNotification> createState() => _FloatingNotificationState();
}

class _FloatingNotificationState extends State<_FloatingNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800)); // Уменьшил длительность

    // Уменьшил дистанцию полета
    final double endY = (widget.isHeal ? -40.0 : 40.0) + widget.customOffset.dy;
    final double endX = widget.customOffset.dx;

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(endX, endY),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacityAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _positionAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(maxWidth: 110), // Ограничиваем ширину
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon, 
                      color: widget.color, 
                      size: 14, // Ещё уменьшил иконку
                    ),
                    const SizedBox(width: 2),
                  ],
                  Flexible( // Добавляем Flexible для переноса текста
                    child: Text(
                      widget.text,
                      style: GoogleFonts.montserrat(
                        fontSize: 16, // Уменьшил размер шрифта
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                        shadows: [
                          const Shadow(
                            blurRadius: 2, 
                            color: Colors.black, 
                            offset: Offset(1, 1)
                          ),
                        ],
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}