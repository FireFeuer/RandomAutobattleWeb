import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusEffectsWidget extends StatefulWidget {
  final String playerName;
  final Stream<Map<String, dynamic>> activationStream;
  final int poisonStacks;

  const StatusEffectsWidget({
    super.key,
    required this.playerName,
    required this.activationStream,
    required this.poisonStacks,
  });

  @override
  State<StatusEffectsWidget> createState() => _StatusEffectsWidgetState();
}

class _StatusEffectsWidgetState extends State<StatusEffectsWidget> with TickerProviderStateMixin {
  final List<Widget> _floatingEffects = [];
  late AnimationController _stunPulseController;
  bool _isStunned = false;

  @override
  void initState() {
    super.initState();
    
    _stunPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    widget.activationStream.listen((data) {
      String effectType = data['effect_type']?.toString().toUpperCase() ?? '';
      String targetName = data['player_name'] ?? '';
      
      if (targetName == widget.playerName) {
        if (effectType == 'STUN') {
          // Показываем эффект стана
          _showStunEffect();
        } else if (effectType == 'POISON_APPLY') {
          // Показываем эффект яда
          _showPoisonEffect(data['value'] ?? 0);
        } else if (effectType == 'POISON_TICK') {
          // Показываем тик яда
          _showPoisonTickEffect(data['value'] ?? 0);
        }
      }
    });
  }

  void _showStunEffect() {
    setState(() {
      _isStunned = true;
    });
    _stunPulseController.forward(from: 0.0);
    
    // Добавляем вылетающий текст
    _addFloatingElement('ОГЛУШЕНИЕ', Colors.yellow, Icons.bolt);
    
    // Через 1 секунду убираем состояние стана
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isStunned = false;
        });
      }
    });
  }

  void _showPoisonEffect(int stacks) {
    _addFloatingElement('ЯД +$stacks', Colors.green, Icons.coronavirus);
  }

  void _showPoisonTickEffect(int damage) {
    _addFloatingElement('-$damage', const Color.fromARGB(255, 33, 175, 38), Icons.water_drop);
  }

  void _addFloatingElement(String text, Color color, IconData? icon) {
    final key = UniqueKey();
    setState(() {
      _floatingEffects.add(
        _FloatingEffect(
          key: key,
          text: text,
          color: color,
          icon: icon,
          onComplete: () {
            if (mounted) {
              setState(() {
                _floatingEffects.removeWhere((e) => e.key == key);
              });
            }
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _stunPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Индикатор стана
          if (_isStunned)
            Positioned(
              top: 0,
              child: ScaleTransition(
                scale: TweenSequence([
                  TweenSequenceItem(
                    tween: Tween<double>(begin: 1.0, end: 1.3),
                    weight: 1,
                  ),
                  TweenSequenceItem(
                    tween: Tween<double>(begin: 1.3, end: 1.0),
                    weight: 1,
                  ),
                ]).animate(CurvedAnimation(
                  parent: _stunPulseController,
                  curve: Curves.easeInOut,
                )),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.yellow,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.yellow,
                    size: 20,
                  ),
                ),
              ),
            ),
          
          // Индикатор яда
          if (widget.poisonStacks > 0)
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.coronavirus,
                      color: Colors.green,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${widget.poisonStacks}',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Вылетающие эффекты
          ..._floatingEffects,
        ],
      ),
    );
  }
}

class _FloatingEffect extends StatefulWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final VoidCallback onComplete;

  const _FloatingEffect({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    required this.onComplete,
  });

  @override
  State<_FloatingEffect> createState() => _FloatingEffectState();
}

class _FloatingEffectState extends State<_FloatingEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -40),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon!,
                      color: widget.color,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    widget.text,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                      shadows: const [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
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