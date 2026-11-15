import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../features/quran/models/ayah.dart';

enum WordState { idle, active, correct, warning, error }

class WordToken extends StatelessWidget {
  final Word word;
  final WordState state;
  final VoidCallback? onTap;
  final double fontSize;

  const WordToken({
    super.key,
    required this.word,
    this.state = WordState.idle,
    this.onTap,
    this.fontSize = 28,
  });

  Color get _bgColor {
    return switch (state) {
      WordState.active => ItqanColors.goldGlow,
      WordState.correct => ItqanColors.correct.withOpacity(0.28), // Realtime Green
      WordState.warning => ItqanColors.warning.withOpacity(0.20),
      WordState.error => ItqanColors.error.withOpacity(0.32),     // Realtime Red
      WordState.idle => Colors.transparent,
    };
  }

  Color get _textColor {
    return switch (state) {
      WordState.active => ItqanColors.goldLight,
      WordState.correct => ItqanColors.correct,
      WordState.warning => ItqanColors.warning,
      WordState.error => ItqanColors.error,
      WordState.idle => ItqanColors.snow,
    };
  }

  Border? get _border {
    switch (state) {
      case WordState.active:
        return Border.all(color: ItqanColors.gold.withOpacity(0.8), width: 1.5);
      case WordState.correct:
        return Border.all(color: ItqanColors.correct, width: 1.5);
      case WordState.error:
        return Border.all(color: ItqanColors.error, width: 1.5);
      case WordState.warning:
        return Border.all(color: ItqanColors.warning, width: 1.5);
      case WordState.idle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(8),
          border: _border,
          boxShadow: state == WordState.correct || state == WordState.error
              ? [
                  BoxShadow(
                    color: (state == WordState.correct ? ItqanColors.correct : ItqanColors.error).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          word.textUthmani,
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: fontSize,
            height: 2.0,
            color: _textColor,
            fontWeight: state != WordState.idle ? FontWeight.bold : FontWeight.normal,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
