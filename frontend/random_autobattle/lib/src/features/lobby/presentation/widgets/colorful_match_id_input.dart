import 'dart:math' as math;
import 'package:flutter/services.dart'; 

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class ColorfulMatchIdInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? errorText;          // ← новый параметр

  const ColorfulMatchIdInput({
    super.key,
    required this.controller,
    this.hintText = 'ID матча',
    this.errorText,
  });

  @override
  State<ColorfulMatchIdInput> createState() => _ColorfulMatchIdInputState();
}

class _ColorfulMatchIdInputState extends State<ColorfulMatchIdInput> {
  static const double goldenAngle = 137.50776;

  final FocusNode _focusNode = FocusNode();

  Color _getColor(int index) {
    final hue = (index * goldenAngle) % 360;
    return HSVColor.fromAHSV(0.9, hue, 0.8, 0.8).toColor();
  }

  Color _getBorderColor() {
    if (widget.errorText != null) {
      return AppColors.errorRed;
    }
    return _focusNode.hasFocus ? AppColors.primary : AppColors.inputBorder;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.controller.removeListener(() => setState(() {}));
    _focusNode.removeListener(() => setState(() {}));
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 480,
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getBorderColor(),
                width: 5,
              ),
            ),
            child: Stack(
              children: [
                // Цветной текст (нижний слой)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: GoogleFonts.montserrat(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                        children: widget.controller.text.split('').asMap().entries.map((entry) {
                          final char = entry.value == ' ' ? '\u{00A0}' : entry.value;
                          return TextSpan(
                            text: char,
                            style: TextStyle(color: _getColor(entry.key)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  maxLines: 1,
                  showCursor: false,
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    // Только буквы и цифры
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    // Максимум 6 символов
                    LengthLimitingTextInputFormatter(6),
                    // Приводим к верхнему регистру (length не меняется → selection без корректировки)
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return TextEditingValue(
                        text: newValue.text.toUpperCase(),
                        selection: newValue.selection,
                        composing: TextRange.empty,
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark.withOpacity(0.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
        ),

        // Текст ошибки (показывается только если есть)
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),  // ← убран left: 32, теперь выровнено по левому краю поля
            child: Text(
              widget.errorText!,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.errorRed,
                height: 1.3,
              ),
              maxLines: null,                 // ← перенос на следующую строку без троеточия
            ),
          ),
      ],
    );
  }
}