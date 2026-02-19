import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class HealthBar extends StatelessWidget {
  final String playerName;
  final double currentHp;
  final double maxHp;
  final double shield;
  final bool isLeft;

  const HealthBar({
    super.key,
    required this.playerName,
    required this.currentHp,
    required this.maxHp,
    required this.shield,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final safeHp = currentHp < 0 ? 0 : currentHp;
    final hpPercentage = maxHp > 0 ? (safeHp / maxHp).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.inputBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            playerName,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          // Внешний контейнер с границей
          Container(
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.inputBorder, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                children: [
                  // Фон (серая полоска)
                  Container(
                    color: Colors.grey[300],
                  ),
                  // HP (Цветная полоска)
                  Positioned.fill(
                    child: Align(
                      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: hpPercentage,
                        heightFactor: 1.0,
                        child: Container(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  // Текст поверх
                  Center(
                    child: Text(
                      "${safeHp.toInt()} HP${shield > 0 ? ' (+${shield.toInt()})' : ''}",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}