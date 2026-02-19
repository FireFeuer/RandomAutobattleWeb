import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class AbilityIcon extends StatefulWidget {
  final Map<String, dynamic> abilityData;
  final bool isLeft;

  const AbilityIcon({
    super.key,
    required this.abilityData,
    required this.isLeft,
  });

  @override
  State<AbilityIcon> createState() => _AbilityIconState();
}

class _AbilityIconState extends State<AbilityIcon> {
  bool _isHovered = false;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;  // ДОБАВЛЯЕМ ЭТУ СТРОКУ

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
    // Берем первую букву, если есть второе слово - берем первую букву второго слова
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

  // Добавляем методы для показа/скрытия тултипа через Overlay
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
              
              // Индикатор стеков, если > 1
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