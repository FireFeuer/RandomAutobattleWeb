import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class PerkDialog extends StatelessWidget {
  final List<dynamic> perks;
  final Function(String) onPerkSelected;
  final bool amIP1;

  const PerkDialog({
    super.key,
    required this.perks,
    required this.onPerkSelected,
    required this.amIP1,  // Добавить эту строку
  });

  @override
  Widget build(BuildContext context) {
    final double containerHorizontalPadding = 24.0 * 2;
    final double cardWidth = 200.0; // Увеличил ширину для описания
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
            SizedBox(
              height: 350, // Увеличил высоту
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
                        perkData: perks[index],
                        onTap: () {
                          onPerkSelected(perks[index]['id']);
                          Navigator.pop(context);
                        },
                        amIP1: amIP1,  // Добавить эту строку
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
  final dynamic perkData;
  final VoidCallback onTap;
  final bool amIP1;

  const _PerkCard({
    required this.perkData,
    required this.onTap,
    required this.amIP1,  // Добавить эту строку
  });

  @override
  State<_PerkCard> createState() => _PerkCardState();
}

class _PerkCardState extends State<_PerkCard> {
  double _scale = 1.0;

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

  @override
  Widget build(BuildContext context) {
    final perk = widget.perkData;
    final rarity = perk['rarity'] ?? 'common';
    final rarityColor = _getRarityColor(rarity);
    final isStackable = perk['stackable'] ?? true;
    final currentStacks = perk['current_stacks'] ?? {};
    final myStacks = widget.amIP1 
        ? (perk['p1_stacks'] as int? ?? 0)
        : (perk['p2_stacks'] as int? ?? 0);

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
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _scale,
          child: Container(
            width: 200,
            height: 300,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Полоска редкости
                  Container(
                    height: 8,
                    color: rarityColor,
                  ),
                  
                  // Основной контент
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Название и редкость
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Прижимает содержимое к левому краю
                            children: [
                              // 1. Название (теперь занимает всю доступную ширину)
                              Text(
                                perk['name_ru'] ?? 'Неизвестно',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              // 2. Отступ между названием и редкостью
                              const SizedBox(height: 4), 

                              // 3. Блок редкости (теперь снизу)
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
                          
                          // Описание
                          Text(
                            perk['description'] ?? '',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: AppColors.textDark.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Характеристики
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              perk['stats'] ?? '',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: AppColors.textDark,
                                height: 1.4,
                              ),
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Индикатор стеков
                          if (myStacks > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: rarityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: rarityColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Уровень $myStacks',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: rarityColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Индикатор stackable
                          if (!isStackable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Не усиляется при повторном выборе',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: Colors.grey,
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
      ),
    );
  }
}