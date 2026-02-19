import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class RoundProgressIndicator extends StatelessWidget {
  final int currentWins;
  final int totalRoundsNeeded;
  final bool isForPlayer;

  const RoundProgressIndicator({
    super.key,
    required this.currentWins,
    this.totalRoundsNeeded = 5,
    this.isForPlayer = true,
  });

  @override
  Widget build(BuildContext context) {
    print('RoundProgressIndicator: isForPlayer=$isForPlayer, currentWins=$currentWins');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: 
            isForPlayer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalRoundsNeeded, (index) {
              final bool isWin = index < currentWins;
              return Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWin ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: AppColors.inputBorder,
                    width: 2,
                  ),
                ),
                child: isWin
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              );
            }),
          ),
        ],
      ),
    );
  }
}
