import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class LobbyBackground extends StatelessWidget {
  const LobbyBackground({super.key});

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
            painter: _GridPainter(),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Основные линии сетки (более тонкие и прозрачные)
    final gridPaint = Paint()
      ..color = AppColors.gridLine.withOpacity(0.06) // Уменьшил прозрачность
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round; // Скругленные концы линий
    
    // Второстепенные линии (еще более прозрачные и тонкие)
    final subGridPaint = Paint()
      ..color = AppColors.gridLine.withOpacity(0.02)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    // Основной шаг сетки (увеличил до 80 пикселей)
    const mainStep = 90.0;
    
    // Второстепенный шаг (между основными линиями)
    const subStep = mainStep / 4; // 20 пикселей

    // Рисуем второстепенные линии (более светлые)
    for (double x = 0; x <= size.width; x += subStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), subGridPaint);
    }
    for (double y = 0; y <= size.height; y += subStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), subGridPaint);
    }

    // Рисуем основные линии (немного темнее)
    for (double x = 0; x <= size.width; x += mainStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += mainStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Добавляем точку в центре каждого большого квадрата для мягкости
    final dotPaint = Paint()
      ..color = AppColors.gridLine.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    
    const dotRadius = 1.5;
    
    for (double x = mainStep; x < size.width; x += mainStep) {
      for (double y = mainStep; y < size.height; y += mainStep) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}