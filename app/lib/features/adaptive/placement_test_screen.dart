import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/gold_button.dart';
import '../../shared/widgets/score_ring.dart';
import '../quran/models/ayah.dart';
import '../scoring/scoring_service.dart';
import '../scoring/models/score_result.dart';
import 'adaptive_service.dart';

class PlacementTestScreen extends ConsumerStatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  ConsumerState<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends ConsumerState<PlacementTestScreen> {
  final ScoringService _scorer = ScoringService();
  int _currentIndex = 0;
  bool _isRecording = false;
  bool _isEvaluating = false;
  final List<double> _scores = [];
  ScoreResult? _currentResult;

  final ayahs = AdaptiveService.diagnosticAyahs;

  void _recordAndScore() async {
    setState(() {
      _isRecording = true;
      _currentResult = null;
    });

    // Simulate standard recitation duration for diagnostic test
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isEvaluating = true;
    });

    final currentDiag = ayahs[_currentIndex];
    final words = currentDiag.textUthmani.split(' ').map((w) => Word(
      position: 1,
      textUthmani: w,
      transliteration: '',
    )).toList();

    final testAyah = Ayah(
      surahNumber: currentDiag.surahNumber,
      ayahNumber: currentDiag.ayahNumber,
      textUthmani: currentDiag.textUthmani,
      words: words,
      translation: '',
    );

    try {
      final res = await _scorer.scoreRecording(
        audioPath: 'placement_test_audio.wav',
        ayah: testAyah,
        recordingDuration: const Duration(milliseconds: 3200),
      );
      if (mounted) {
        setState(() {
          _currentResult = res;
          _isEvaluating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isEvaluating = false);
      }
    }
  }

  void _nextStep() {
    if (_currentResult != null) {
      _scores.add(_currentResult!.overall);
    } else {
      _scores.add(80.0);
    }

    if (_currentIndex < ayahs.length - 1) {
      setState(() {
        _currentIndex++;
        _currentResult = null;
      });
    } else {
      // Completed all 3 ayahs
      setState(() {
        _currentIndex = ayahs.length; // Show final results
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = _currentIndex >= ayahs.length;

    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        backgroundColor: ItqanColors.void_,
        title: const Text('Diagnostic Placement Test', style: ItqanTypography.heading2),
      ),
      body: SafeArea(
        child: isFinished ? _buildFinalSummary() : _buildAyahStep(),
      ),
    );
  }

  Widget _buildAyahStep() {
    final item = ayahs[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verse ${_currentIndex + 1} of ${ayahs.length}',
                style: ItqanTypography.caption.copyWith(color: ItqanColors.gold),
              ),
              Text(
                '${item.surahName} : ${item.ayahNumber}',
                style: ItqanTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / ayahs.length,
              backgroundColor: ItqanColors.charcoal,
              valueColor: const AlwaysStoppedAnimation(ItqanColors.gold),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: ItqanSpacing.xl),

          // Diagnostic focus badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ItqanColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(ItqanRadius.full),
              border: Border.all(color: ItqanColors.gold.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.psychology_rounded, size: 16, color: ItqanColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.focusArea,
                    style: const TextStyle(fontSize: 12, color: ItqanColors.goldLight, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ItqanSpacing.xl),

          // Quran Verse Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(ItqanSpacing.lg),
              decoration: BoxDecoration(
                color: ItqanColors.onyx,
                borderRadius: BorderRadius.circular(ItqanRadius.lg),
                border: Border.all(color: ItqanColors.charcoal),
              ),
              child: Center(
                child: Text(
                  item.textUthmani,
                  style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 26,
                    color: ItqanColors.white,
                    height: 2.0,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
          const SizedBox(height: ItqanSpacing.lg),

          // Feedback area if evaluated
          if (_currentResult != null) ...[
            Container(
              padding: const EdgeInsets.all(ItqanSpacing.md),
              decoration: BoxDecoration(
                color: ItqanColors.obsidian,
                borderRadius: BorderRadius.circular(ItqanRadius.md),
                border: Border.all(color: _currentResult!.color.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: _currentResult!.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Score: ${_currentResult!.overall.round()} • ${_currentResult!.grade}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: _currentResult!.color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ItqanSpacing.md),
          ],

          // Action buttons
          if (_currentResult == null)
            GoldButton(
              label: _isRecording ? 'Listening to Recitation...' : (_isEvaluating ? 'Evaluating...' : 'Recite This Verse'),
              icon: _isRecording ? Icons.mic : Icons.mic_none_rounded,
              onPressed: (_isRecording || _isEvaluating) ? null : _recordAndScore,
            )
          else
            GoldButton(
              label: _currentIndex < ayahs.length - 1 ? 'Next Verse' : 'Complete Assessment',
              icon: Icons.arrow_forward_rounded,
              onPressed: _nextStep,
            ),
        ],
      ),
    );
  }

  Widget _buildFinalSummary() {
    final avgScore = _scores.isNotEmpty
        ? _scores.reduce((a, b) => a + b) / _scores.length
        : 80.0;
    final recommendedLevel = AdaptiveService.determineLevel(avgScore);
    final capitalized = recommendedLevel[0].toUpperCase() + recommendedLevel.substring(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: ItqanSpacing.md),
          const Icon(Icons.stars_rounded, size: 64, color: ItqanColors.gold),
          const SizedBox(height: ItqanSpacing.md),
          const Text('Diagnostic Completed!', style: ItqanTypography.heading1),
          const SizedBox(height: ItqanSpacing.xs),
          Text(
            'Your recitation capability has been calibrated.',
            style: ItqanTypography.body.copyWith(color: ItqanColors.mist),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ItqanSpacing.xl),
          ScoreRing(score: avgScore, size: 160),
          const SizedBox(height: ItqanSpacing.xl),

          // Recommended Level Card
          Container(
            padding: const EdgeInsets.all(ItqanSpacing.lg),
            decoration: BoxDecoration(
              color: ItqanColors.onyx,
              borderRadius: BorderRadius.circular(ItqanRadius.lg),
              border: Border.all(color: ItqanColors.gold),
            ),
            child: Column(
              children: [
                const Text('Recommended Level', style: ItqanTypography.caption),
                const SizedBox(height: 6),
                Text(
                  capitalized,
                  style: ItqanTypography.heading1.copyWith(color: ItqanColors.gold),
                ),
                const SizedBox(height: ItqanSpacing.sm),
                Text(
                  recommendedLevel == 'advanced'
                      ? 'Strict Tajweed verification & precision makhraj grading.'
                      : (recommendedLevel == 'intermediate'
                          ? 'Standard Tajweed rule evaluation with balanced elongation metrics.'
                          : 'Focus on clear pronunciation, foundational fluency, and basic makhraj.'),
                  style: ItqanTypography.body.copyWith(color: ItqanColors.cloud, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: ItqanSpacing.xl),

          GoldButton(
            label: 'Apply & Save Level ($capitalized)',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () async {
              await AdaptiveService.applyPlacementLevel(
                ref: ref,
                newLevel: recommendedLevel,
                placementScore: avgScore,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: ItqanColors.onyx,
                  content: Text('Level calibrated to $capitalized! Dynamic difficulty active.'),
                ),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

