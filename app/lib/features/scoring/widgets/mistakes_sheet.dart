import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/score_result.dart';

/// Tarteel-style Mistake Detection Sheet (Inspection, Comparisons & Similar Verses)
class MistakesSheet extends StatelessWidget {
  final List<RecitationMistake> mistakes;
  final VoidCallback? onPracticeAyah;

  const MistakesSheet({
    super.key,
    required this.mistakes,
    this.onPracticeAyah,
  });

  static Future<void> show(
    BuildContext context, {
    required List<RecitationMistake> mistakes,
    VoidCallback? onPracticeAyah,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? ItqanColors.onyx
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MistakesSheet(
        mistakes: mistakes,
        onPracticeAyah: onPracticeAyah,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : ItqanColors.lightTextPrimary;
    final secondaryTextColor = isDark ? ItqanColors.mist : ItqanColors.lightTextSecondary;
    final cardBg = isDark ? ItqanColors.charcoal : ItqanColors.lightBackground;
    final borderColor = isDark ? Colors.white12 : ItqanColors.lightBorder;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.symmetric(horizontal: ItqanSpacing.lg, vertical: ItqanSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? ItqanColors.slate : ItqanColors.lightDivider,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Mistakes',
                      style: ItqanTypography.heading2.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ItqanColors.mistakeIncorrect.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(ItqanRadius.full),
                        border: Border.all(color: ItqanColors.mistakeIncorrect.withOpacity(0.4)),
                      ),
                      child: Text(
                        '${mistakes.length} detected',
                        style: const TextStyle(
                          color: ItqanColors.mistakeIncorrect,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: secondaryTextColor, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: ItqanSpacing.sm),

            if (mistakes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: ItqanColors.correct, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No recitation mistakes detected!',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alhamdulillah, your recitation was clear and accurate.',
                        style: TextStyle(color: secondaryTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: mistakes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: ItqanSpacing.md),
                  itemBuilder: (ctx, idx) {
                    final m = mistakes[idx];
                    return _MistakeItemCard(
                      mistake: m,
                      isDark: isDark,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    );
                  },
                ),
              ),

            const SizedBox(height: ItqanSpacing.md),
            if (onPracticeAyah != null && mistakes.isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? ItqanColors.gold : ItqanColors.goldDeep,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Fix & Practice Again',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onPracticeAyah!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MistakeItemCard extends StatelessWidget {
  final RecitationMistake mistake;
  final bool isDark;
  final Color textColor;
  final Color secondaryTextColor;
  final Color cardBg;
  final Color borderColor;

  const _MistakeItemCard({
    required this.mistake,
    required this.isDark,
    required this.textColor,
    required this.secondaryTextColor,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ItqanSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: e.g. [2:7] Incorrect words
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: secondaryTextColor.withOpacity(0.5)),
                ),
                child: Text(
                  mistake.verseKey,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                mistake.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: mistake.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Comparison Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? ItqanColors.onyx : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                // Expected Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 65,
                      child: Text(
                        'Expected',
                        style: TextStyle(fontSize: 12, color: secondaryTextColor),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        mistake.expectedText,
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 18,
                          color: textColor,
                          height: 1.6,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Recited Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 65,
                      child: Text(
                        'Recited',
                        style: TextStyle(fontSize: 12, color: secondaryTextColor),
                      ),
                    ),
                    Expanded(
                      child: RichText(
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 18,
                            color: textColor,
                            height: 1.6,
                          ),
                          children: [
                            if (mistake.type == MistakeType.missed) ...[
                              TextSpan(
                                text: mistake.highlightedWord,
                                style: const TextStyle(
                                  color: ItqanColors.mistakeMissed,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const TextSpan(text: ' (terlewat)'),
                            ] else if (mistake.type == MistakeType.incorrect) ...[
                              TextSpan(
                                text: mistake.recitedText.isNotEmpty ? mistake.recitedText : mistake.highlightedWord,
                                style: const TextStyle(
                                  color: ItqanColors.mistakeIncorrect,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else ...[
                              TextSpan(
                                text: mistake.recitedText.isNotEmpty ? mistake.recitedText : mistake.highlightedWord,
                                style: TextStyle(
                                  color: mistake.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (mistake.detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              mistake.detail,
              style: TextStyle(color: secondaryTextColor, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),

          // Tarteel-style "See similar verses" Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? ItqanColors.charcoal : const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: () {
              _showSimilarVersesDialog(context, mistake);
            },
            child: const Text(
              'See similar verses',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showSimilarVersesDialog(BuildContext context, RecitationMistake mistake) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? ItqanColors.onyx : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.compare_arrows_rounded, color: ItqanColors.gold),
              const SizedBox(width: 8),
              Text(
                'Similar Verses (Mutashabihat)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : ItqanColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Careful! In the Quran, verses with similar phrasing often differ in key endings:',
                style: TextStyle(fontSize: 13, color: isDark ? ItqanColors.mist : ItqanColors.lightTextSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? ItqanColors.charcoal : ItqanColors.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '• Ayah ${mistake.verseKey}:',
                      style: TextStyle(color: secondaryTextColor, fontSize: 11),
                    ),
                    Text(
                      mistake.expectedText,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 15,
                        color: isDark ? Colors.white : ItqanColors.lightTextPrimary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood', style: TextStyle(color: ItqanColors.gold)),
            ),
          ],
        );
      },
    );
  }
}

