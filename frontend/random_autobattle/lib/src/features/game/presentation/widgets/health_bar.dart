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
    double hpPercentage = (currentHp / maxHp).clamp(0.0, 1.0);
    
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
          Stack(
            children: [
              // Фон (серая полоска)
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.inputBorder, width: 2),
                ),
              ),
              // HP
              FractionallySizedBox(
                widthFactor: hpPercentage,
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.inputBorder, width: 2),
                  ),
                ),
              ),
              // Текст поверх
              Positioned.fill(
                child: Center(
                  child: Text(
                    "${currentHp.toInt()} HP${shield > 0 ? ' (+${shield.toInt()})' : ''}",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}