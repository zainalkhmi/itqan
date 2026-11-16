import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../features/quran/models/ayah.dart';

enum WordState { idle, active, correct, warning, error }

class WordToken extends StatelessWidget {
  final Word word;
  final WordState state;
  final VoidCallback? onTap;

  const WordToken({super.key, required this.word, this.state = WordState.idle, this.onTap});

  static const Color correctBlue = Color(0xFF3B82F6);
  static const Color errorRed = Color(0xFFEF4444);

  Color get _bgColor {
    return switch (state) {
      WordState.active => ItqanColors.goldGlow,
      WordState.correct => correctBlue.withOpacity(0.18),
      WordState.warning => ItqanColors.warning.withOpacity(0.15),
      WordState.error => errorRed.withOpacity(0.18),
      WordState.idle => Colors.transparent,
    };
  }

  Color get _textColor {
    return switch (state) {
      WordState.active => ItqanColors.goldLight,
      WordState.correct => correctBlue,
      WordState.warning => ItqanColors.warning,
      WordState.error => errorRed,
      WordState.idle => ItqanColors.snow,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(6),
          border: state == WordState.active
              ? Border.all(color: ItqanColors.gold.withOpacity(0.5))
              : (state == WordState.correct
                  ? Border.all(color: correctBlue.withOpacity(0.7), width: 1.2)
                  : (state == WordState.error
                      ? Border.all(color: errorRed.withOpacity(0.7), width: 1.2)
                      : null)),
        ),
        child: Text(
          word.textUthmani,
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 28,
            height: 2.0,
            color: _textColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
