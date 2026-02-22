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
      if (!mounted) return;

      final abilityName = data['ability_name'] as String?;
      final eventPlayerName = data['player_name'] as String?;
      final effectType = data['effect_type'] as String?;

      // Тики яда обрабатываются виджетом статусов возле здоровья, а не здесь
      if (effectType == 'POISON_TICK') return;

      // Если активировалась именно эта способность у этого игрока
      if (abilityName == widget.abilityData['name_ru'] && eventPlayerName == widget.playerName) {
        _pulseController.forward(from: 0.0);
        _triggerFloatingEffect(data);
      }
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
      text = '$text!';
    }

    if (effectType == 'REFLECT') {
      color = Colors.purpleAccent;
      icon = Icons.shield;
    } else if (effectType == 'STUN') {
      color = Colors.yellow;
      icon = Icons.bolt;
      text = 'Оглушение';
    } else if (effectType == 'POISON_APPLY') {
      color = Colors.green;
      icon = Icons.coronavirus;
    }

    final key = UniqueKey();
    setState(() {
      _floatingElements.add(
        _FloatingAnimation(
          key: key,
          text: text,
          color: color,
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

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: widget.isLeft ? position.dx : null,
        right: widget.isLeft ? null : MediaQuery.of(context).size.width - position.dx - 48,
        top: position.dy + 56,
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

  @override
  Widget build(BuildContext context) {
    final name = widget.abilityData['name_ru'] as String;
    final rarity = widget.abilityData['rarity'] as String;
    final stacks = widget.abilityData['stacks'] as int? ?? 1;

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
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 4),
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
                child: Stack(
                  children: [
                    Center(
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
                    if (stacks > 1)
                      Positioned(
                        top: -4,
                        right: -4,
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
                  ],
                ),
              ),
            ),
            // Вылетающие эффекты
            ..._floatingElements,
          ],
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
            child: Text(
              stats,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: AppColors.textDark,
                height: 1.4,
              ),
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
class _FloatingAnimation extends StatefulWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final VoidCallback onComplete;

  const _FloatingAnimation({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    required this.onComplete,
  });

  @override
  State<_FloatingAnimation> createState() => _FloatingAnimationState();
}

class _FloatingAnimationState extends State<_FloatingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 40),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)));

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
        return Positioned(
          top: _positionAnimation.value.dy,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: widget.color, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(
                  widget.text,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 3,
                        offset: const Offset(1, 1),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}