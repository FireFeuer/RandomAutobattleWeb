import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class PerkDialog extends StatelessWidget {
  final List<dynamic> perks;
  final Function(String) onPerkSelected;

  const PerkDialog({
    super.key,
    required this.perks,
    required this.onPerkSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Рассчитываем ширину диалога на основе количества карточек
    // Но не больше максимальной
    final double containerHorizontalPadding = 24.0 * 2; // EdgeInsets.all(24)
    final double cardWidth = 160.0;
    final double cardSpacing = 16.0;

    double dialogWidth = (perks.length * cardWidth) +
                        ((perks.length - 1) * cardSpacing) +
                        containerHorizontalPadding;
    dialogWidth = dialogWidth.clamp(400.0, 1900.0);

    return Dialog(
      backgroundColor: AppColors.inputBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Выберите способность',
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 32),
            // Горизонтальный ряд карточек
            SizedBox(
              height: 260, // Увеличиваем высоту, чтобы карточки при увеличении не обрезались
              child: Center(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: perks.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : 16,
                        right: index == perks.length - 1 ? 0 : 0,
                      ),
                      child: _PerkCard(
                        perkName: perks[index].toString(),
                        onTap: () {
                          onPerkSelected(perks[index].toString());
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerkCard extends StatefulWidget {
  final String perkName;
  final VoidCallback onTap;

  const _PerkCard({
    required this.perkName,
    required this.onTap,
  });

  @override
  State<_PerkCard> createState() => _PerkCardState();
}

class _PerkCardState extends State<_PerkCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _scale = 1.05;
        });
      },
      onExit: (_) {
        setState(() {
          _scale = 1.0;
        });
      },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            clipBehavior: Clip.hardEdge, // ← обрезает overflow при scale
            width: 160,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.inputBorder.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: _scale,
              child: Center(
                child: Text(
                  widget.perkName.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
    );
  }
}