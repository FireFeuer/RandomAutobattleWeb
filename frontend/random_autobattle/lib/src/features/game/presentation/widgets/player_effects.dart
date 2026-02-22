import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerEffects extends StatefulWidget {
  final Map<String, dynamic> effects; // poison_stacks, shield, stun и т.д.
  final bool isLeft;

  const PlayerEffects({
    super.key,
    required this.effects,
    required this.isLeft,
  });

  @override
  State<PlayerEffects> createState() => _PlayerEffectsState();
}

class _PlayerEffectsState extends State<PlayerEffects>
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _pulseControllers = {};
  final Map<String, bool> _prevValues = {};

  @override
  void didUpdateWidget(PlayerEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Проверяем изменения в эффектах
    widget.effects.forEach((key, value) {
      final oldValue = oldWidget.effects[key];
      if (oldValue != value && value > 0) {
        // Эффект изменился и активен - запускаем пульсацию
        _startPulse(key);
      }
    });
  }

  void _startPulse(String effectKey) {
    _pulseControllers[effectKey]?.dispose();
    
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _pulseControllers[effectKey] = controller;
    controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    for (var controller in _pulseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildEffectIcon(String type, int value, Color color, IconData icon) {
    final controller = _pulseControllers[type];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller != null)
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                CurvedAnimation(
                  parent: controller,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            )
          else
            Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            value.toString(),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.effects['poison_stacks'] != null && 
            widget.effects['poison_stacks'] > 0)
          _buildEffectIcon(
            'poison',
            widget.effects['poison_stacks'],
            Colors.green,
            Icons.science,
          ),
        if (widget.effects['shield'] != null && 
            widget.effects['shield'] > 0)
          _buildEffectIcon(
            'shield',
            widget.effects['shield'].toInt(),
            Colors.blue,
            Icons.shield,
          ),
        if (widget.effects['stun'] != null && 
            widget.effects['stun'] > 0)
          _buildEffectIcon(
            'stun',
            (widget.effects['stun'] / 1000).round(),
            Colors.amber,
            Icons.timer_off,
          ),
      ],
    );
  }
}