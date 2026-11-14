import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:itqan/l10n/app_localizations.dart';
import '../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../quran/models/ayah.dart';
import '../quran/services/quran_service.dart';
import '../quran/data/quran_catalog.dart';
import '../home/home_screen.dart';
import '../scoring/results_screen.dart';
import '../scoring/widgets/mistakes_sheet.dart';
import '../memorization/services/srs_service.dart';
import 'recitation_controller.dart';
import 'widgets/record_button.dart';
import 'widgets/waveform_visualizer.dart';
import 'widgets/word_token.dart';
import 'widgets/live_tracking_unmasking_card.dart';
import 'widgets/surah_ayah_picker_sheet.dart';

enum HifzMode { off, liveUnmasking, blank, blur, firstLetter }

class RecitationScreen extends ConsumerStatefulWidget {
  final Ayah ayah;
  final String surahName;
  final HifzMode initialHifzMode;

  const RecitationScreen({
    super.key,
    required this.ayah,
    required this.surahName,
    this.initialHifzMode = HifzMode.off,
  });

  @override
  ConsumerState<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends ConsumerState<RecitationScreen> {
  late Ayah _currentAyah;
  List<Ayah> _surahAyahs = [];
  late HifzMode _hifzMode;
  bool _isPeeking = false;
  int _peekCount = 0;
  Timer? _peekTimer;
  final Set<int> _liveUnmaskedIndices = {};
  int _liveActiveWordIndex = 0;
  late int _currentSurahNumber;
  late String _currentSurahName;
  bool _isLoadingSurah = false;

  @override
  void initState() {
    super.initState();
    _currentAyah = widget.ayah;
    _hifzMode = widget.initialHifzMode;
    _currentSurahNumber = widget.ayah.surahNumber > 0 ? widget.ayah.surahNumber : 1;
    final fallbackName = QuranCatalog.getSurah(_currentSurahNumber).nameSimple;
    _currentSurahName = widget.surahName.isNotEmpty ? widget.surahName : fallbackName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recitationProvider.notifier).loadAyah(_currentAyah);
      _loadSurahAyahs();
    });
  }

  @override
  void dispose() {
    _peekTimer?.cancel();
    super.dispose();
  }

  void _triggerPeek() {
    _peekTimer?.cancel();
    setState(() {
      _isPeeking = true;
      _peekCount++;
    });
    _peekTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _isPeeking = false);
      }
    });
  }

  Future<void> _loadSurahAyahs() async {
    try {
      final service = QuranService();
      await service.init();
      final ayahs = await service.getAyahs(_currentSurahNumber);
      if (mounted && ayahs.isNotEmpty) {
        setState(() {
          _surahAyahs = ayahs;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSurah(int surahNum, {int targetAyahNumber = 1}) async {
    final surahObj = QuranCatalog.getSurah(surahNum);
    setState(() {
      _currentSurahNumber = surahNum;
      _currentSurahName = surahObj.nameSimple;
      _isLoadingSurah = true;
      _liveUnmaskedIndices.clear();
      _peekCount = 0;
    });

    try {
      final service = QuranService();
      await service.init();
      final ayahs = await service.getAyahs(surahNum);
      if (mounted && ayahs.isNotEmpty) {
        setState(() {
          _surahAyahs = ayahs;
          _isLoadingSurah = false;
        });
        final target = ayahs.firstWhere(
          (a) => a.ayahNumber == targetAyahNumber,
          orElse: () => ayahs.first,
        );
        _goToAyah(target);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSurah = false);
    }
  }

  void _goToAyah(Ayah newAyah) {
    setState(() {
      _currentAyah = newAyah;
      _liveUnmaskedIndices.clear();
      _peekCount = 0;
    });
    ref.read(recitationProvider.notifier).loadAyah(newAyah);
  }

  void _nextAyah() async {
    if (_surahAyahs.isEmpty) return;
    final currentIndex = _surahAyahs.indexWhere((a) => a.ayahNumber == _currentAyah.ayahNumber);
    if (currentIndex != -1 && currentIndex + 1 < _surahAyahs.length) {
      _goToAyah(_surahAyahs[currentIndex + 1]);
    } else if (_currentSurahNumber < 114) {
      // Seamlessly advance to next Surah!
      await _loadSurah(_currentSurahNumber + 1, targetAyahNumber: 1);
    }
  }

  void _prevAyah() async {
    if (_surahAyahs.isEmpty) return;
    final currentIndex = _surahAyahs.indexWhere((a) => a.ayahNumber == _currentAyah.ayahNumber);
    if (currentIndex > 0) {
      _goToAyah(_surahAyahs[currentIndex - 1]);
    } else if (_currentSurahNumber > 1) {
      // Seamlessly transition to previous Surah (last Ayah)!
      final prevCount = QuranCatalog.getAyahCount(_currentSurahNumber - 1);
      await _loadSurah(_currentSurahNumber - 1, targetAyahNumber: prevCount);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(recitationProvider);
    final notifier = ref.read(recitationProvider.notifier);
    final isRecording = data.state == RecitationState.recording;
    final isPlaying = data.state == RecitationState.playing;
    final isProcessing = data.state == RecitationState.processing;

    // Navigate to results when scored
    ref.listen(recitationProvider, (prev, next) {
      if (next.state == RecitationState.scored && next.result != null) {
        final double finalOverall = _hifzMode != HifzMode.off && _peekCount > 0
            ? (next.result!.overall - (_peekCount * 5)).clamp(0.0, 100.0)
            : next.result!.overall;

        final adjustedResult = next.result!.copyWith(
          overall: finalOverall,
          hifzMode: _hifzMode != HifzMode.off ? _hifzMode.name : null,
          peeksUsed: _peekCount,
        );

        // Record into Spaced Repetition System
        try {
          SrsService().recordReview(
            _currentAyah.surahNumber,
            _currentAyah.ayahNumber,
            finalOverall,
            peeks: _peekCount,
          );
        } catch (_) {}

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              result: adjustedResult,
              ayah: _currentAyah,
              surahName: _currentSurahName,
              onRetry: () {
                notifier.retry();
                Navigator.pop(context);
              },
              onNext: () {
                Navigator.pop(context);
                _nextAyah();
              },
            ),
          ),
        );
      }
    });

    RecordButtonState btnState = RecordButtonState.idle;
    if (isRecording) btnState = RecordButtonState.recording;
    if (isProcessing) btnState = RecordButtonState.processing;

    // In liveUnmasking mode, unmask words progressively during recording
    if (isRecording && _hifzMode == HifzMode.liveUnmasking) {
      final elapsedSec = data.recordingDuration.inSeconds;
      final totalWords = _currentAyah.words.length;
      if (totalWords > 0) {
        final expectedWordIndex = (elapsedSec * 0.8).floor().clamp(0, totalWords - 1);
        _liveUnmaskedIndices.add(expectedWordIndex);
        _liveActiveWordIndex = (expectedWordIndex + 1).clamp(0, totalWords - 1);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : ItqanColors.lightTextPrimary;
    final secondaryTextColor = isDark ? ItqanColors.mist : ItqanColors.lightTextSecondary;
    final cardBg = isDark ? ItqanColors.onyx : Colors.white;
    final cardBorder = isDark
        ? (_isPeeking ? ItqanColors.gold : ItqanColors.goldGlow)
        : (_isPeeking ? ItqanColors.gold : ItqanColors.lightBorder);

    final currentAyahIdx = _surahAyahs.indexWhere((a) => a.ayahNumber == _currentAyah.ayahNumber);
    final hasPrev = (_surahAyahs.isNotEmpty && currentAyahIdx > 0) || _currentSurahNumber > 1;
    final hasNext = (_surahAyahs.isNotEmpty && currentAyahIdx != -1 && currentAyahIdx + 1 < _surahAyahs.length) || _currentSurahNumber < 114;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
        ),
        centerTitle: true,
        title: InkWell(
          onTap: () {
            SurahAyahPickerSheet.show(
              context,
              currentSurahNumber: _currentSurahNumber,
              currentAyahNumber: _currentAyah.ayahNumber,
              onSelected: (sNum, aNum) {
                _loadSurah(sNum, targetAyahNumber: aNum);
              },
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '$_currentSurahName • Ayah ${_currentAyah.ayahNumber}',
                    style: ItqanTypography.label.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? ItqanColors.gold : ItqanColors.goldDeep,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: hasPrev ? (isDark ? ItqanColors.gold : ItqanColors.goldDeep) : secondaryTextColor),
            tooltip: 'Previous Ayah',
            onPressed: hasPrev ? _prevAyah : null,
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: hasNext ? (isDark ? ItqanColors.gold : ItqanColors.goldDeep) : secondaryTextColor),
            tooltip: 'Next Ayah',
            onPressed: hasNext ? _nextAyah : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ItqanSpacing.lg),
          child: Column(
            children: [
              // Quran text card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(ItqanSpacing.lg),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(ItqanRadius.xl),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                    border: Border.all(
                      color: cardBorder,
                      width: _isPeeking ? 2.0 : 1.5,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Hifz mode toggle pills
                        _buildHifzModeSelector(),
                        const SizedBox(height: ItqanSpacing.md),

                        if (_hifzMode == HifzMode.liveUnmasking) ...[
                          LiveTrackingUnmaskingCard(
                            ayah: _currentAyah,
                            isTracking: isRecording,
                            unmaskedIndices: _liveUnmaskedIndices,
                            currentActiveWordIndex: _liveActiveWordIndex,
                            onWordTap: (idx) {
                              setState(() {
                                _liveUnmaskedIndices.add(idx);
                              });
                            },
                          ),
                        ] else ...[
                          if (_isPeeking) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              margin: const EdgeInsets.only(bottom: ItqanSpacing.sm),
                              decoration: BoxDecoration(
                                color: ItqanColors.gold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(ItqanRadius.full),
                                border: Border.all(color: ItqanColors.gold),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.visibility_rounded, size: 14, color: ItqanColors.gold),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Peeking... (-5 pts penalty) • ${_peekCount}x peeked',
                                    style: const TextStyle(color: ItqanColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Full text or masked text
                          _buildAyahTextDisplay(),
                          const SizedBox(height: ItqanSpacing.lg),

                          // Word tokens or masked tokens
                          _buildWordTokensDisplay(),
                          const SizedBox(height: ItqanSpacing.lg),

                          // Translation
                          if (_currentAyah.translation.isNotEmpty && (_hifzMode == HifzMode.off || _isPeeking))
                            Text(
                              '"${_currentAyah.translation}"',
                              style: ItqanTypography.caption.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),

                          // Peek Button (only when in Hifz mode)
                          if (_hifzMode != HifzMode.off) ...[
                            const SizedBox(height: ItqanSpacing.md),
                            OutlinedButton.icon(
                              onPressed: _triggerPeek,
                              icon: Icon(
                                _isPeeking ? Icons.visibility_rounded : Icons.visibility_outlined,
                                color: _isPeeking ? ItqanColors.gold : ItqanColors.mist,
                                size: 18,
                              ),
                              label: Text(
                                _isPeeking
                                    ? 'Peeking active (2.5s)'
                                    : 'Peek Ayah (-5 pts)${_peekCount > 0 ? " • ${_peekCount}x" : ""}',
                                style: TextStyle(
                                  color: _isPeeking ? ItqanColors.gold : ItqanColors.mist,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _isPeeking ? ItqanColors.gold : ItqanColors.charcoal,
                                ),
                                backgroundColor: _isPeeking ? ItqanColors.gold.withOpacity(0.15) : Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ItqanRadius.full)),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: ItqanSpacing.lg),

              // Waveform (visible when recording)
              AnimatedOpacity(
                opacity: isRecording ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: WaveformVisualizer(isActive: isRecording),
              ),

              // Recording timer
              AnimatedOpacity(
                opacity: isRecording ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.only(top: ItqanSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.circle, color: ItqanColors.error, size: 10),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(data.recordingDuration),
                        style: const TextStyle(
                          color: ItqanColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (data.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: ItqanSpacing.sm),
                  child: Text(data.error!, style: const TextStyle(color: ItqanColors.error)),
                ),

              const SizedBox(height: ItqanSpacing.lg),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Listen button
                  _ControlButton(
                    icon: isPlaying ? Icons.stop_rounded : Icons.headphones_rounded,
                    label: isPlaying ? AppLocalizations.of(context)!.recitationStop : AppLocalizations.of(context)!.recitationListenFirst,
                    color: isPlaying ? ItqanColors.error : ItqanColors.info,
                    onTap: notifier.listen,
                  ),

                  // Record button
                  RecordButton(
                    state: btnState,
                    onTap: () {
                      if (isRecording) {
                        notifier.stopRecording();
                      } else if (!isProcessing) {
                        notifier.startRecording();
                      }
                    },
                  ),

                  // Retry / skip
                  _ControlButton(
                    icon: Icons.refresh_rounded,
                    label: AppLocalizations.of(context)!.recitationRetry,
                    color: ItqanColors.mist,
                    onTap: notifier.retry,
                  ),
                ],
              ),

              const SizedBox(height: ItqanSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHifzModeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? ItqanColors.charcoal : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(ItqanRadius.full),
        border: Border.all(color: isDark ? Colors.transparent : ItqanColors.lightBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _hifzChip('Read', HifzMode.off, Icons.menu_book_rounded),
            _hifzChip('Live Unmask', HifzMode.liveUnmasking, Icons.mic_external_on_rounded),
            _hifzChip('Blur', HifzMode.blur, Icons.blur_on_rounded),
            _hifzChip('Blank', HifzMode.blank, Icons.visibility_off_rounded),
            _hifzChip('Initials', HifzMode.firstLetter, Icons.title_rounded),
          ],
        ),
      ),
    );
  }

  Widget _hifzChip(String label, HifzMode mode, IconData icon) {
    final isSelected = _hifzMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _hifzMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? ItqanColors.gold : ItqanColors.goldDeep)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ItqanRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : (isDark ? ItqanColors.mist : ItqanColors.lightTextSecondary),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? ItqanColors.mist : ItqanColors.lightTextSecondary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahTextDisplay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final arabicTextColor = isDark ? ItqanColors.snow : ItqanColors.lightTextPrimary;

    if (_isPeeking || _hifzMode == HifzMode.off) {
      return Text(
        _currentAyah.textUthmani,
        style: ItqanTypography.arabicLarge.copyWith(color: arabicTextColor),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      );
    }

    if (_hifzMode == HifzMode.blank) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              '• • • • • • • • • • • • • • • •\n• • • • • • • • • • • •',
              style: ItqanTypography.arabicLarge.copyWith(color: ItqanColors.mist.withOpacity(0.4), letterSpacing: 4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hifz Mode Active (Ayah Hidden)',
              style: ItqanTypography.caption.copyWith(color: ItqanColors.gold.withOpacity(0.8), fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_hifzMode == HifzMode.blur) {
      return ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Text(
          _currentAyah.textUthmani,
          style: ItqanTypography.arabicLarge,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      );
    }

    // First letter mode
    final words = _currentAyah.textUthmani.split(' ');
    final masked = words.map((w) {
      if (w.length <= 2) return '$wـ...';
      return '${w.substring(0, 2)}ـ...';
    }).join(' ');

    return Text(
      masked,
      style: ItqanTypography.arabicLarge.copyWith(color: ItqanColors.gold),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }

  Widget _buildWordTokensDisplay() {
    if (_currentAyah.words.isEmpty) return const SizedBox.shrink();

    if (_hifzMode == HifzMode.blank && !_isPeeking) {
      return Wrap(
        alignment: WrapAlignment.center,
        textDirection: TextDirection.rtl,
        spacing: ItqanSpacing.xs,
        runSpacing: ItqanSpacing.xs,
        children: _currentAyah.words.map((w) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ItqanColors.charcoal.withOpacity(0.5),
              borderRadius: BorderRadius.circular(ItqanRadius.sm),
              border: Border.all(color: ItqanColors.charcoal),
            ),
            child: const Text('•••', style: TextStyle(color: ItqanColors.mist)),
          );
        }).toList(),
      );
    }

    final tokensWidget = Wrap(
      alignment: WrapAlignment.center,
      textDirection: TextDirection.rtl,
      spacing: ItqanSpacing.xs,
      runSpacing: ItqanSpacing.xs,
      children: _currentAyah.words.map((w) {
        return WordToken(word: w, state: WordState.idle);
      }).toList(),
    );

    if (_hifzMode == HifzMode.blur && !_isPeeking) {
      return ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: tokensWidget,
      );
    }

    return tokensWidget;
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDark ? color.withOpacity(0.12) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? color.withOpacity(0.4) : ItqanColors.lightBorder;
    final captionColor = isDark ? ItqanColors.mist : ItqanColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: btnBg,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 84),
            child: Text(
              label,
              style: ItqanTypography.caption.copyWith(color: captionColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
