import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GridBackground extends StatelessWidget {
  final double opacity;
  final double mainStep;
  final Color gridColor;
  final bool showDots;

  const GridBackground({
    super.key,
    this.opacity = 0.06,
    this.mainStep = 90.0,
    this.gridColor = AppColors.gridLine,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Фон
        Positioned.fill(
          child: Container(color: AppColors.background),
        ),
        
        // Сетка
        Positioned.fill(
          child: CustomPaint(
            painter: _GridPainter(
              opacity: opacity,
              mainStep: mainStep,
              gridColor: gridColor,
              showDots: showDots,
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final double opacity;
  final double mainStep;
  final Color gridColor;
  final bool showDots;

  _GridPainter({
    required this.opacity,
    required this.mainStep,
    required this.gridColor,
    required this.showDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final subStep = mainStep / 4;

    // Основные линии сетки
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(opacity)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    
    // Второстепенные линии
    final subGridPaint = Paint()
      ..color = gridColor.withOpacity(opacity * 0.3)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    // Рисуем второстепенные линии
    for (double x = 0; x <= size.width; x += subStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), subGridPaint);
    }
    for (double y = 0; y <= size.height; y += subStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), subGridPaint);
    }

    // Рисуем основные линии
    for (double x = 0; x <= size.width; x += mainStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += mainStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Добавляем точки в центре каждого большого квадрата
    if (showDots) {
      final dotPaint = Paint()
        ..color = gridColor.withOpacity(opacity * 0.7)
        ..style = PaintingStyle.fill;
      
      const dotRadius = 1.5;
      
      for (double x = mainStep; x < size.width; x += mainStep) {
        for (double y = mainStep; y < size.height; y += mainStep) {
          canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
           oldDelegate.mainStep != mainStep ||
           oldDelegate.gridColor != gridColor ||
           oldDelegate.showDots != showDots;
  }
}