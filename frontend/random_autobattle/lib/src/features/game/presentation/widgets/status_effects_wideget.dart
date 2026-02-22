import 'dart:async';
import 'package:flutter/material.dart';

class StatusEffectsWidget extends StatefulWidget {
  final String playerName;
  final Stream<Map<String, dynamic>> activationStream;
  final int poisonStacks; // Берем из GameStateModel

  const StatusEffectsWidget({
    super.key,
    required this.playerName,
    required this.activationStream,
    required this.poisonStacks,
  });

  @override
  State<StatusEffectsWidget> createState() => _StatusEffectsWidgetState();
}

class _StatusEffectsWidgetState extends State<StatusEffectsWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.4), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.4, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _sub = widget.activationStream.listen((data) {
      // Слушаем тики яда по этому игроку
      if (data['effect_type'] == 'POISON_TICK' && data['player_name'] == widget.playerName) {
        _pulseController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.poisonStacks <= 0) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.coronavirus, color: Colors.green, size: 16), // Иконка яда
            const SizedBox(width: 4),
            Text(
              '${widget.poisonStacks}',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}