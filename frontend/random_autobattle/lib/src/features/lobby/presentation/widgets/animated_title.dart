import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class AnimatedTitle extends StatefulWidget {
  const AnimatedTitle({super.key});

  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<Offset>> _offsetAnimations;
  late final List<Animation<double>> _scaleAnimations;
  late final List<Animation<Color?>> _colorAnimations;

  final String _text = "RANDOM AUTOBATTLE";
  late final List<String> _letters;

  @override
  void initState() {
    super.initState();
    _letters = _text.split('');

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600), // Быстрее!
      vsync: this,
    )..repeat(reverse: true);

    _offsetAnimations = List.generate(_letters.length, (i) {
      final delay = i * 0.015; // Меньше задержка
      final double safeEnd = (delay + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: Offset.zero,
        end: Offset(0, -18 + (i % 3 - 1) * 9), // Больше амплитуда
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(delay.clamp(0.0, 1.0), safeEnd, curve: Curves.easeOutBack),
        ),
      );
    });

    // Scale-анимация для "пружинистости"
    _scaleAnimations = List.generate(_letters.length, (i) {
      final delay = i * 0.015;
      return Tween<double>(begin: 1.0, end: 1.15)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.elasticOut),
      ));
    });

    _colorAnimations = List.generate(_letters.length, (i) {
      return TweenSequence<Color?>(
        [
          TweenSequenceItem(
            tween: ColorTween(begin: AppColors.primary, end: const Color.fromARGB(200, 20, 90, 180)),
            weight: 35,
          ),
          TweenSequenceItem(
            tween: ColorTween(begin: const Color.fromARGB(200, 30, 60, 160), end: const Color.fromARGB(180, 13, 189, 54)),
            weight: 55,
          ),
          TweenSequenceItem(
            tween: ColorTween(begin: const Color.fromARGB(190, 20, 85, 200), end: AppColors.primary),
            weight: 35,
          ),
        ],
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.05 + i * 0.012, (0.05 + i * 0.012 + 0.75).clamp(0.0, 1.0), curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_letters.length, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Transform.scale(
              scale: _scaleAnimations[i].value,
              child: Transform.translate(
                offset: _offsetAnimations[i].value,
                child: Text(
                  _letters[i],
                  style: GoogleFonts.mandali(
                    fontSize: 69,
                    fontWeight: FontWeight.w900,
                    color: _colorAnimations[i].value,
                    letterSpacing: 16,
                    shadows: [
                      Shadow(
                        blurRadius: 90,
                        color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.45),
                        offset: const Offset(3, 5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}