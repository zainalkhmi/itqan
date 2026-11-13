import 'package:flutter/material.dart';
import 'package:itqan/l10n/app_localizations.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../quran/models/ayah.dart';
import 'models/score_result.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/gold_button.dart';
import 'widgets/word_detail_sheet.dart';
import '../tashih/services/tashih_service.dart';

class ResultsScreen extends StatelessWidget {
  final ScoreResult result;
  final Ayah ayah;
  final String surahName;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  const ResultsScreen({
    super.key,
    required this.result,
    required this.ayah,
    required this.surahName,
    required this.onRetry,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final mistakes = result.wordScores.where((w) => w.error != null).toList();

    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        backgroundColor: ItqanColors.void_,
        title: Text(AppLocalizations.of(context)!.resultsTitle, style: ItqanTypography.heading2),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ItqanSpacing.lg),
          child: Column(
            children: [
              Text(
                '$surahName • Ayah ${ayah.ayahNumber}',
                style: ItqanTypography.body.copyWith(color: ItqanColors.mist),
                textAlign: TextAlign.center,
              ),
              if (result.aiModel != null) ...[
                const SizedBox(height: ItqanSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: result.aiModel!.contains('whisper') ? ItqanColors.gold.withOpacity(0.15) : ItqanColors.charcoal,
                    borderRadius: BorderRadius.circular(ItqanRadius.full),
                    border: Border.all(
                      color: result.aiModel!.contains('whisper') ? ItqanColors.gold : ItqanColors.mist.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        result.aiModel!.contains('whisper') ? Icons.auto_awesome : Icons.graphic_eq,
                        size: 14,
                        color: result.aiModel!.contains('whisper') ? ItqanColors.gold : ItqanColors.mist,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        result.aiModel!.contains('whisper') ? 'Whisper AI Quran Engine (Phase 2)' : 'On-Device Acoustic Engine',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: result.aiModel!.contains('whisper') ? ItqanColors.gold : ItqanColors.mist,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (result.hifzMode != null) ...[
                const SizedBox(height: ItqanSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: result.peeksUsed == 0
                        ? ItqanColors.correct.withOpacity(0.15)
                        : ItqanColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(ItqanRadius.full),
                    border: Border.all(
                      color: result.peeksUsed == 0 ? ItqanColors.correct : ItqanColors.warning,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        result.peeksUsed == 0 ? Icons.verified_rounded : Icons.visibility_rounded,
                        size: 15,
                        color: result.peeksUsed == 0 ? ItqanColors.correct : ItqanColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        result.peeksUsed == 0
                            ? 'Hifz (${result.hifzMode}) • Perfect Recall! (+5 bonus)'
                            : 'Hifz (${result.hifzMode}) • ${result.peeksUsed} Peek(s) (-${result.peeksUsed * 5} pts)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: result.peeksUsed == 0 ? ItqanColors.correct : ItqanColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: ItqanSpacing.lg),
              Text(result.grade, style: ItqanTypography.heading1.copyWith(color: result.color)),
              const SizedBox(height: ItqanSpacing.md),
              ScoreRing(score: result.overall, size: 180),
              if (result.transcription != null && result.transcription!.isNotEmpty) ...[
                const SizedBox(height: ItqanSpacing.lg),
                const _SectionHeader(title: 'AI Speech Recognition'),
                const SizedBox(height: ItqanSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(ItqanSpacing.md),
                  decoration: BoxDecoration(
                    color: ItqanColors.onyx,
                    borderRadius: BorderRadius.circular(ItqanRadius.md),
                    border: Border.all(color: ItqanColors.gold.withOpacity(0.3)),
                  ),
                  child: Text(
                    result.transcription!,
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 18,
                      color: ItqanColors.white,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
              const SizedBox(height: ItqanSpacing.xl),
              _SectionHeader(title: AppLocalizations.of(context)!.resultsOverallScore),
              const SizedBox(height: ItqanSpacing.md),
              _BreakdownBar(label: AppLocalizations.of(context)!.resultsWordAccuracy, score: result.wordAccuracy),
              _BreakdownBar(label: AppLocalizations.of(context)!.resultsLetterAccuracy, score: result.letterAccuracy),
              _BreakdownBar(label: AppLocalizations.of(context)!.resultsTajweed, score: result.tajweed),
              _BreakdownBar(label: AppLocalizations.of(context)!.resultsFluency, score: result.fluency),
              const SizedBox(height: ItqanSpacing.xl),
              if (result.wordScores.isNotEmpty) ...[
                _SectionHeader(title: AppLocalizations.of(context)!.resultsWordAccuracy),
                const SizedBox(height: ItqanSpacing.md),
                _WordAnalysis(wordScores: result.wordScores),
                const SizedBox(height: ItqanSpacing.xl),
              ],
              if (mistakes.isNotEmpty) ...[
                _SectionHeader(title: AppLocalizations.of(context)!.resultsMistakeCards),
                const SizedBox(height: ItqanSpacing.md),
                ...mistakes.map((w) => _MistakeCard(wordScore: w)),
                const SizedBox(height: ItqanSpacing.xl),
              ],
              Row(
                children: [
                  Expanded(
                    child: GoldButton(label: AppLocalizations.of(context)!.recitationRetry, icon: Icons.refresh_rounded, onPressed: onRetry),
                  ),
                  const SizedBox(width: ItqanSpacing.md),
                  Expanded(
                    child: GoldButton(
                      label: AppLocalizations.of(context)!.recitationNextAyah,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: onNext,
                      secondary: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ItqanSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _submitToTeacher(context),
                  icon: const Icon(Icons.school_rounded, color: ItqanColors.gold, size: 18),
                  label: const Text(
                    'Submit Recitation to Teacher (Tashih)',
                    style: TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ItqanColors.goldGlow),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ItqanRadius.full)),
                  ),
                ),
              ),
              const SizedBox(height: ItqanSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _submitToTeacher(BuildContext context) async {
    final service = TashihService();
    await service.init();
    await service.submitRecitation(
      studentName: 'Ahmad Santri',
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.ayahNumber,
      surahName: surahName,
      textUthmani: ayah.textUthmani,
      aiScore: result.overall,
      aiGrade: result.grade,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recitation submitted to Teacher Tashih queue!'),
          backgroundColor: ItqanColors.correct,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: ItqanTypography.label),
        const SizedBox(width: ItqanSpacing.sm),
        Expanded(child: Container(height: 1, color: ItqanColors.charcoal)),
      ],
    );
  }
}

class _BreakdownBar extends StatefulWidget {
  final String label;
  final double score;
  const _BreakdownBar({required this.label, required this.score});

  @override
  State<_BreakdownBar> createState() => _BreakdownBarState();
}

class _BreakdownBarState extends State<_BreakdownBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = Tween<double>(begin: 0, end: widget.score / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _barColor(double score) {
    if (score >= 85) return ItqanColors.correct;
    if (score >= 65) return ItqanColors.warning;
    return ItqanColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ItqanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label, style: ItqanTypography.caption),
              Text(
                '${widget.score.round()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _barColor(widget.score),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(ItqanRadius.full),
              child: LinearProgressIndicator(
                value: _anim.value,
                minHeight: 8,
                backgroundColor: ItqanColors.charcoal,
                valueColor: AlwaysStoppedAnimation(_barColor(widget.score)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordAnalysis extends StatelessWidget {
  final List<WordScore> wordScores;
  const _WordAnalysis({required this.wordScores});

  Color _color(double score) {
    if (score >= 0.85) return ItqanColors.correct;
    if (score >= 0.65) return ItqanColors.warning;
    return ItqanColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ItqanSpacing.md),
      decoration: BoxDecoration(
        color: ItqanColors.onyx,
        borderRadius: BorderRadius.circular(ItqanRadius.lg),
      ),
      child: Wrap(
        textDirection: TextDirection.rtl,
        alignment: WrapAlignment.center,
        spacing: ItqanSpacing.sm,
        runSpacing: ItqanSpacing.sm,
        children: wordScores.map((ws) {
          return Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => showWordDetail(ctx, ws),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _color(ws.score).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(ItqanRadius.sm),
                  border: Border.all(color: _color(ws.score).withOpacity(0.4)),
                ),
                child: Text(
                  ws.word,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 22,
                    color: _color(ws.score),
                    height: 1.8,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final WordScore wordScore;
  const _MistakeCard({required this.wordScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ItqanSpacing.sm),
      padding: const EdgeInsets.all(ItqanSpacing.md),
      decoration: BoxDecoration(
        color: ItqanColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(ItqanRadius.lg),
        border: Border.all(color: ItqanColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(
            wordScore.word,
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 28,
              color: ItqanColors.error,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: ItqanSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.resultsNeedsWork,
                  style: const TextStyle(color: ItqanColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(wordScore.error ?? '', style: ItqanTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
