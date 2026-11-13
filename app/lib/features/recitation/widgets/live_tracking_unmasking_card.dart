import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../quran/models/ayah.dart';

class LiveTrackingUnmaskingCard extends StatefulWidget {
  final Ayah ayah;
  final bool isTracking;
  final Set<int> unmaskedIndices;
  final int currentActiveWordIndex;
  final ValueChanged<int>? onWordTap;
  final VoidCallback? onComplete;

  const LiveTrackingUnmaskingCard({
    super.key,
    required this.ayah,
    required this.isTracking,
    required this.unmaskedIndices,
    this.currentActiveWordIndex = 0,
    this.onWordTap,
    this.onComplete,
  });

  @override
  State<LiveTrackingUnmaskingCard> createState() => _LiveTrackingUnmaskingCardState();
}

class _LiveTrackingUnmaskingCardState extends State<LiveTrackingUnmaskingCard> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.ayah.words;
    final totalWords = words.length;
    final unmaskedCount = widget.unmaskedIndices.length;
    final progress = totalWords > 0 ? (unmaskedCount / totalWords).clamp(0.0, 1.0) : 0.0;
    final isDone = totalWords > 0 && unmaskedCount >= totalWords;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      decoration: BoxDecoration(
        color: ItqanColors.onyx,
        borderRadius: BorderRadius.circular(ItqanRadius.lg),
        border: Border.all(
          color: isDone ? ItqanColors.correct : (widget.isTracking ? ItqanColors.gold : ItqanColors.charcoal),
          width: 1.5,
        ),
        boxShadow: widget.isTracking
            ? [
                BoxShadow(
                  color: ItqanColors.gold.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Header tracking status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isTracking ? ItqanColors.gold : ItqanColors.mist,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isTracking ? 'Live Speech Tracking' : 'Dynamic Unmasking (Hifz)',
                    style: TextStyle(
                      color: widget.isTracking ? ItqanColors.gold : ItqanColors.mist,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '$unmaskedCount / $totalWords words',
                style: const TextStyle(color: ItqanColors.mist, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: ItqanColors.charcoal,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? ItqanColors.correct : ItqanColors.gold,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: ItqanSpacing.lg),

          // Words cloud in RTL
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 10,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: List.generate(words.length, (index) {
                final word = words[index];
                final isUnmasked = widget.unmaskedIndices.contains(index);
                final isCurrent = widget.isTracking && index == widget.currentActiveWordIndex && !isUnmasked;

                return GestureDetector(
                  onTap: () => widget.onWordTap?.call(index),
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isUnmasked
                              ? ItqanColors.correct.withValues(alpha: 0.15)
                              : (isCurrent
                                  ? ItqanColors.gold.withValues(alpha: 0.15 * _glowAnimation.value)
                                  : ItqanColors.charcoal.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(ItqanRadius.md),
                          border: Border.all(
                            color: isUnmasked
                                ? ItqanColors.correct
                                : (isCurrent
                                    ? ItqanColors.gold.withValues(alpha: _glowAnimation.value)
                                    : Colors.transparent),
                            width: isCurrent ? 2.0 : 1.0,
                          ),
                        ),
                        child: Text(
                          isUnmasked ? word.textUthmani : '••••••',
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 22,
                            fontWeight: isUnmasked ? FontWeight.w600 : FontWeight.normal,
                            color: isUnmasked
                                ? ItqanColors.correct
                                : (isCurrent ? ItqanColors.gold : ItqanColors.mist.withValues(alpha: 0.5)),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: ItqanSpacing.md),

          // Instruction / prompt message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ItqanColors.void_,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isDone
                  ? '🎉 Ayah Completed! All words successfully recited.'
                  : (widget.isTracking
                      ? 'Speak word by word from memory — each word unmasks upon speech'
                      : 'Tap record to begin dynamic unmasking session'),
              style: TextStyle(
                color: isDone ? ItqanColors.correct : ItqanColors.mist,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

