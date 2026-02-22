import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class ActionLogWidget extends StatefulWidget {
  final List<dynamic> logs;
  final String myName;

  const ActionLogWidget({
    super.key,
    required this.logs,
    required this.myName,
  });

  @override
  State<ActionLogWidget> createState() => _ActionLogWidgetState();
}

class _ActionLogWidgetState extends State<ActionLogWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ActionLogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs.length != oldWidget.logs.length) {
      // Автопрокрутка к новым сообщениям
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getActionText(Map<String, dynamic> log) {
    final actionType = log['action_type'] as String;
    final playerName = log['player_name'] as String;
    final targetName = log['target_name'] as String?;
    final value = log['value'] as int;
    final isCrit = log['is_crit'] as bool? ?? false;

    switch (actionType) {
      case 'attack':
        final critText = isCrit ? ' КРИТ!' : '';
        return '$playerName → $targetName: $value$critText';
      case 'heal':
        return '$playerName лечит себя: +$value';
      case 'crit':
        return '$playerName наносит крит: $value';
      case 'poison':
        return '$playerName отравляет $targetName (${log['stacks']} ст.)';
      case 'poison_damage':
        return 'Яд → $targetName: $value урона';
      case 'shield':
        return '$playerName получает щит: +$value';
      case 'reflect':
        return '$playerName отражает $value → $targetName';
      case 'lifesteal':
        return '$playerName восстанавливает +$value (вампиризм)';
      default:
        return '$playerName: $value';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.inputBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.inputBorder.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.inputBorder.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: AppColors.textDark.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Лог боя',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Список логов
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,  // Новые сообщения сверху
                padding: const EdgeInsets.all(8),
                itemCount: widget.logs.length,
                itemBuilder: (context, index) {
                  final log = widget.logs[widget.logs.length - 1 - index] as Map<String, dynamic>;
                  final playerName = log['player_name'] as String;
                  final isMyAction = playerName == widget.myName || 
                      (playerName == "Яд" && log['target_name'] == widget.myName);
                  final rarityColor = Color(
                    int.parse(
                      (log['rarity_color'] as String).replaceFirst('#', '0xFF'),
                    ),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMyAction 
                            ? rarityColor.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: rarityColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Цветная полоска редкости
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: rarityColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Время
                          Text(
                            log['timestamp'] as String,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: AppColors.textDark.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Текст действия
                          Expanded(
                            child: Text(
                              _getActionText(log),
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: isMyAction 
                                    ? Colors.white
                                    : AppColors.textDark.withOpacity(0.9),
                                fontWeight: isMyAction ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Индикатор стеков
                          if (log['stacks'] != null && log['stacks'] > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: rarityColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'x${log['stacks']}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: rarityColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}