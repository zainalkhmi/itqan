import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:itqan/l10n/app_localizations.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../quran/models/ayah.dart';
import 'models/score_result.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/gold_button.dart';
import 'widgets/word_detail_sheet.dart';
import 'widgets/mistakes_sheet.dart';
import '../tashih/services/tashih_service.dart';

class ResultsScreen extends StatefulWidget {
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
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingUserAudio = false;
  bool _isAudioDeleted = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((ps) {
      if (mounted) {
        setState(() {
          _isPlayingUserAudio = ps.playing && ps.processingState != ProcessingState.completed;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayUserAudio() async {
    final path = widget.result.audioPath;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File rekaman suara tidak tersedia.')),
      );
      return;
    }

    try {
      if (_isPlayingUserAudio) {
        await _audioPlayer.stop();
        if (mounted) setState(() => _isPlayingUserAudio = false);
      } else {
        if (!kIsWeb) {
          final file = File(path);
          if (await file.exists()) {
            await _audioPlayer.setFilePath(path);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File rekaman tidak ditemukan di perangkat.')),
              );
            }
            return;
          }
        } else {
          await _audioPlayer.setUrl(path);
        }
        await _audioPlayer.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memutar rekaman: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecording() async {
    final path = widget.result.audioPath;
    try {
      await _audioPlayer.stop();
      if (path != null && !kIsWeb) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      if (mounted) {
        setState(() {
          _isAudioDeleted = true;
          _isPlayingUserAudio = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('File rekaman suara berhasil dihapus.'),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus rekaman: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final ayah = widget.ayah;
    final surahName = widget.surahName;
    final onRetry = widget.onRetry;
    final onNext = widget.onNext;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : ItqanColors.lightTextPrimary;
    final mistakes = result.wordScores.where((w) => w.error != null).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(AppLocalizations.of(context)!.resultsTitle, style: ItqanTypography.heading2.copyWith(color: textColor)),
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
                Builder(
                  builder: (context) {
                    final modelStr = result.aiModel!.toLowerCase();
                    final isTajweed = modelStr.contains('tajweedformer');
                    final isWhisper = modelStr.contains('whisper');
                    final isOnDeviceOnnx = modelStr.contains('onnx') || modelStr.contains('mobile c++');

                    final badgeColor = isTajweed
                        ? ItqanColors.correct
                        : (isWhisper ? ItqanColors.gold : (isOnDeviceOnnx ? ItqanColors.info : ItqanColors.mist));

                    final badgeIcon = isTajweed
                        ? Icons.psychology_rounded
                        : (isWhisper ? Icons.auto_awesome : (isOnDeviceOnnx ? Icons.memory_rounded : Icons.graphic_eq));

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(ItqanRadius.full),
                        border: Border.all(
                          color: badgeColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 14, color: badgeColor),
                          const SizedBox(width: 6),
                          Text(
                            result.aiModel!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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

              // ── Player & Manajemen Hasil Rekaman Suara ────────
              if (result.audioPath != null && !_isAudioDeleted) ...[
                const SizedBox(height: ItqanSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Play / Pause Button
                      InkWell(
                        onTap: _togglePlayUserAudio,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isPlayingUserAudio
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF0F766E),
                            boxShadow: [
                              BoxShadow(
                                color: (_isPlayingUserAudio
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF0F766E))
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlayingUserAudio
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isPlayingUserAudio
                                  ? 'Memutar Suara Anda...'
                                  : 'Rekaman Suara Anda',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Dengarkan pelafalan Anda atau hapus rekaman ini',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hapus Rekaman Button
                      IconButton(
                        onPressed: _deleteRecording,
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444), size: 22),
                        tooltip: 'Hapus Rekaman',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFEF4444).withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (result.mistakes.isNotEmpty) ...[
                const SizedBox(height: ItqanSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: ItqanColors.mistakeIncorrect.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ItqanColors.mistakeIncorrect.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: ItqanColors.mistakeIncorrect, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${result.mistakes.length} Mistakes Highlighted',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: ItqanColors.mistakeIncorrect, fontSize: 14),
                            ),
                            Text(
                              'Compare Expected vs Recited with similar verses',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : ItqanColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ItqanColors.mistakeIncorrect,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => MistakesSheet.show(
                          context,
                          mistakes: result.mistakes,
                          onPracticeAyah: onRetry,
                        ),
                        child: const Text('Inspect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
              if (result.tajweedFormerDetails != null) ...[
                const SizedBox(height: ItqanSpacing.md),
                Container(
                  padding: const EdgeInsets.all(ItqanSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? ItqanColors.onyx : ItqanColors.lightCard,
                    borderRadius: BorderRadius.circular(ItqanRadius.md),
                    border: Border.all(color: ItqanColors.correct.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology_rounded, color: ItqanColors.correct, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'TajweedFormer V4 Neural Heads (Quran Lab)',
                            style: TextStyle(
                              color: isDark ? Colors.white : ItqanColors.lightTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _tajweedHeadBadge('Madd', '${result.tajweedFormerDetails!['maddCount']} rules', ItqanColors.tajweedMadd),
                          _tajweedHeadBadge('Ghunnah', '${result.tajweedFormerDetails!['ghunnahCount']} rules', ItqanColors.tajweedGhunnah),
                          _tajweedHeadBadge('Qalqalah', '${result.tajweedFormerDetails!['qalqalahCount']} rules', ItqanColors.tajweedQalqalah),
                          _tajweedHeadBadge('Tempo', '${result.tajweedFormerDetails!['tempo'] ?? "Normal"}', ItqanColors.correct),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
      surahNumber: widget.ayah.surahNumber,
      ayahNumber: widget.ayah.ayahNumber,
      surahName: widget.surahName,
      textUthmani: widget.ayah.textUthmani,
      aiScore: widget.result.overall,
      aiGrade: widget.result.grade,
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

  Widget _tajweedHeadBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ItqanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? ItqanColors.onyx : Colors.white,
        borderRadius: BorderRadius.circular(ItqanRadius.lg),
        border: Border.all(color: isDark ? Colors.transparent : ItqanColors.lightBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Lafal Sesuai (Biru)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Perlu Perbaikan (Merah)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            textDirection: TextDirection.rtl,
            alignment: WrapAlignment.center,
            spacing: ItqanSpacing.sm,
            runSpacing: ItqanSpacing.sm,
            children: wordScores.map((ws) {
          final wordColor = ws.statusColor;
          return Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => showWordDetail(ctx, ws),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: wordColor.withOpacity(ws.isMistake ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(ItqanRadius.sm),
                  border: Border.all(
                    color: ws.isMistake ? wordColor : wordColor.withOpacity(0.4),
                    width: ws.isMistake ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  ws.word,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 22,
                    color: wordColor,
                    fontWeight: ws.isMistake ? FontWeight.bold : FontWeight.normal,
                    height: 1.8,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          );
        }).toList(),
      ),
        ],
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
