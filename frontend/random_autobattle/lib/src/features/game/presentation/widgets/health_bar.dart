import 'package:flutter/material.dart';

class HealthBar extends StatelessWidget {
  final String label;
  final double currentHp;
  final double maxHp;
  final double shield;
  final Color color;

  const HealthBar({
    super.key,
    required this.label,
    required this.currentHp,
    required this.maxHp,
    required this.shield,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    double hpPercentage = (currentHp / maxHp).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Stack(
          children: [
            // Фон (серая полоска)
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // HP
            FractionallySizedBox(
              widthFactor: hpPercentage,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            // Текст поверх
            Positioned.fill(
              child: Center(
                child: Text(
                  "${currentHp.toInt()} HP${shield > 0 ? ' (+${shield.toInt()})' : ''}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hpPercentage > 0.3 ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}