import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class NicknameInput extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const NicknameInput({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  @override
  State<NicknameInput> createState() => _NicknameInputState();
}

class _NicknameInputState extends State<NicknameInput> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 480,
          child: TextField(
            controller: widget.controller,
            onChanged: widget.onChanged,
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: AppColors.inputBorder, width: 5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: widget.errorText != null ? AppColors.errorRed : AppColors.inputBorder,
                  width: 5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: widget.errorText != null ? AppColors.errorRed : AppColors.primary,
                  width: 5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.errorRed, width: 5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.errorRed, width: 5),
              ),
              hintText: 'Ваш никнейм',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark.withOpacity(0.4),
              ),

              // ── Настройки текста ошибки ───────────────────────────────
              errorText: widget.errorText,
              errorStyle: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.errorRed,
                height: 1.3,                    // ← комфортный межстрочный интервал
              ),
              errorMaxLines: 3,              // ← главное исправление: ∞ строк
              // или можно указать конкретное число, например: errorMaxLines: 3,
            ),
          ),
        ),
      ],
    );
  }
}