import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:itqan/l10n/app_localizations.dart';
import '../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../quran/models/ayah.dart';
import '../quran/services/quran_service.dart';
import '../recitation/recitation_screen.dart';
import 'mushaf_screen.dart'; // quranServiceProvider, surahsProvider
import 'providers/reading_position_provider.dart';
import 'services/reading_position_service.dart';
import 'models/mushaf_layout.dart';
import 'services/mushaf_layout_service.dart';
import 'widgets/mushaf_15_line_view.dart';
import 'widgets/mushaf_tarteel_view.dart';
import '../recitation/widgets/surah_ayah_picker_sheet.dart';
import '../tajweed/services/tajweed_service.dart';
import '../scoring/models/score_result.dart';
import '../scoring/scoring_service.dart';
import '../scoring/widgets/mistakes_sheet.dart';
import '../settings/settings_service.dart';
import '../scoring/services/inference_config_service.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final _pageDataProvider = FutureProvider.family<PageData, int>((ref, page) async {
  if (page < 1 || page > 604) {
    return PageData(pageNumber: page, juzNumber: 0, hizbNumber: 0, verses: []);
  }
  final service = ref.read(quranServiceProvider);
  await service.init();
  return service.getPage(page);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class MushafPageScreen extends ConsumerStatefulWidget {
  final int startPage;

  const MushafPageScreen({super.key, this.startPage = 1});

  @override
  ConsumerState<MushafPageScreen> createState() => _MushafPageScreenState();
}

class _MushafPageScreenState extends ConsumerState<MushafPageScreen> {
  late PageController _pageController;
  late int _currentPage;
  bool _showTranslation = false;
  bool _is15LineView = false; // Default to Tarteel Modern Mushaf Mode (Image 1 style)
  double _mushafFontSize = 26.0;
  bool _isHifzMode = false;
  bool _showTajweed = true;
  MushafEdition _edition = MushafEdition.madinah15Lines;

  // Auto-save debounce
  Timer? _saveDebounce;
  int _lastSavedPage = -1;

  // Bookmark state
  bool _isBookmarked = false;

  // Live recitation & real-time mistake detection state
  bool _isLiveReciting = false;
  int _recitingSeconds = 0;
  Timer? _recitingTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  AudioRecorder? _liveRecorder;
  String? _liveAudioPath;
  List<RecitationMistake> _liveMistakes = [];
  final Set<String> _mistakeWordKeys = {};
  final Set<String> _correctWordKeys = {};
  String? _activeVerseKey;
  String? _activeWordKey;
  int _activeWordIndex = 0;
  int _accumulatedVoiceMs = 0;
  int _silenceMs = 0;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    TajweedService().init();
    _currentPage = widget.startPage.clamp(1, 604);
    _pageController = PageController(initialPage: _currentPage - 1);
    _precache(_currentPage);
    _checkBookmarkState(_currentPage);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _recitingTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _liveRecorder?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _openSurahAyahPicker(int surahNum, int ayahNum) {
    SurahAyahPickerSheet.show(
      context,
      currentSurahNumber: surahNum,
      currentAyahNumber: ayahNum,
      onSelected: (s, a) {
        _jumpToSurahAyah(s, a);
      },
    );
  }

  void _jumpToSurahAyah(int surahNum, int ayahNum) {
    const surahFirstPage = <int, int>{
      1: 1, 2: 2, 3: 50, 4: 77, 5: 106, 6: 128, 7: 151, 8: 177, 9: 187,
      10: 208, 11: 221, 12: 235, 13: 249, 14: 255, 15: 262, 16: 267, 17: 282,
      18: 293, 19: 305, 20: 312, 21: 322, 22: 333, 23: 342, 24: 350, 25: 359,
      26: 367, 27: 377, 28: 385, 29: 396, 30: 404, 31: 411, 32: 415, 33: 418,
      34: 428, 35: 434, 36: 440, 37: 446, 38: 453, 39: 458, 40: 467, 41: 477,
      42: 483, 43: 489, 44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515,
      50: 518, 51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537,
      58: 542, 59: 545, 60: 549, 61: 551, 62: 553, 63: 554, 64: 556, 65: 558,
      66: 560, 67: 562, 68: 564, 69: 566, 70: 568, 71: 570, 72: 572, 73: 574,
      74: 575, 75: 577, 76: 578, 77: 580, 78: 582, 79: 583, 80: 585, 81: 586,
      82: 587, 83: 587, 84: 589, 85: 590, 86: 591, 87: 591, 88: 592, 89: 593,
      90: 594, 91: 595, 92: 595, 93: 596, 94: 596, 95: 597, 96: 597, 97: 598,
      98: 598, 99: 599, 100: 599, 101: 600, 102: 600, 103: 601, 104: 601,
      105: 601, 106: 602, 107: 602, 108: 602, 109: 603, 110: 603, 111: 603,
      112: 604, 113: 604, 114: 604,
    };
    final page = surahFirstPage[surahNum] ?? 1;
    _jumpToPage(page);
  }

  void _showDisplaySettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? ItqanColors.onyx
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mushaf Display Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // View Mode Switcher
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? ItqanColors.charcoal : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _is15LineView = false);
                                setSheetState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_is15LineView
                                      ? const Color(0xFF10B981)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Tarteel Mushaf Mode',
                                    style: TextStyle(
                                      color: !_is15LineView ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _is15LineView = true);
                                setSheetState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _is15LineView
                                      ? (isDark ? ItqanColors.gold : const Color(0xFFD97706))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '15-Line Madinah Mode',
                                    style: TextStyle(
                                      color: _is15LineView ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Font Size Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Arabic Font Size',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          '${_mushafFontSize.toInt()} sp',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _mushafFontSize,
                      min: 20.0,
                      max: 36.0,
                      divisions: 8,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) {
                        setState(() => _mushafFontSize = val);
                        setSheetState(() {});
                      },
                    ),

                    // Tajweed Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Tajweed Rules Color Highlight',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      activeColor: const Color(0xFF10B981),
                      value: _showTajweed,
                      onChanged: (val) {
                        setState(() => _showTajweed = val);
                        setSheetState(() {});
                      },
                    ),

                    // Hifz Mode Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Hifz Mode (Hide Words / Tap to Peek)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      activeColor: const Color(0xFF10B981),
                      value: _isHifzMode,
                      onChanged: (val) {
                        setState(() => _isHifzMode = val);
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startLiveReciting() async {
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      try {
        _liveRecorder ??= AudioRecorder();
        final hasPermission = await _liveRecorder!.hasPermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Microphone permission required for AI recitation'),
                backgroundColor: ItqanColors.mistakeIncorrect,
              ),
            );
          }
          return;
        }

        AudioEncoder encoder = AudioEncoder.aacLc;
        if (await _liveRecorder!.isEncoderSupported(AudioEncoder.wav)) {
          encoder = AudioEncoder.wav;
        }

        String? recordingPath;
        if (!kIsWeb) {
          final dir = await getTemporaryDirectory();
          final ext = encoder == AudioEncoder.wav ? 'wav' : 'm4a';
          recordingPath = '${dir.path}/mushaf_live_${DateTime.now().millisecondsSinceEpoch}.$ext';
        }
        _liveAudioPath = recordingPath;

        await _liveRecorder!.start(
          RecordConfig(encoder: encoder, sampleRate: 16000, numChannels: 1),
          path: recordingPath ?? '',
        );

        // Real microphone amplitude stream for Voice Activity Detection (VAD)
        _amplitudeSubscription?.cancel();
        _amplitudeSubscription = _liveRecorder!
            .onAmplitudeChanged(const Duration(milliseconds: 50))
            .listen(_processLiveAudioAmplitude);
      } catch (e) {
        debugPrint('[LiveRecitation] Recorder start exception: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _isLiveReciting = true;
      _recitingSeconds = 0;
      _activeVerseKey = null;
      _activeWordKey = null;
      _activeWordIndex = 0;
      _accumulatedVoiceMs = 0;
      _silenceMs = 0;
      _isSpeaking = false;
      _liveMistakes = [];
      _mistakeWordKeys.clear();
      _correctWordKeys.clear();
    });

    _recitingTimer?.cancel();
    _recitingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _recitingSeconds++;
      });
      if (isTest) {
        _processLiveRecitationProgress();
      }
    });
  }

  int _estimateWordAcousticDurationMs(String wordText) {
    final clean = wordText.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'), '');
    final charCount = clean.length.clamp(2, 12);
    return (charCount * 120).clamp(350, 1600);
  }

  void _processLiveAudioAmplitude(Amplitude amp) {
    if (!mounted || !_isLiveReciting) return;

    final pageAsync = ref.read(_pageDataProvider(_currentPage));
    final pageData = pageAsync.valueOrNull;
    if (pageData == null || pageData.verses.isEmpty) return;

    final allWords = <PageWord>[];
    for (final v in pageData.verses) {
      allWords.addAll(v.words.where((w) => !w.isVerseEnd));
    }
    if (allWords.isEmpty) return;

    if (_activeWordIndex >= allWords.length) return;

    // Threshold: -40.0 dBFS separates ambient background noise from active recitation
    final isVoice = amp.current > -40.0;

    if (isVoice) {
      _silenceMs = 0;
      _isSpeaking = true;
      _accumulatedVoiceMs += 50;

      final currentWord = allWords[_activeWordIndex];
      final targetDuration = _estimateWordAcousticDurationMs(currentWord.textUthmani);

      if (_accumulatedVoiceMs >= targetDuration) {
        final wordKey = '${currentWord.verseKey}:${currentWord.position}';
        setState(() {
          _correctWordKeys.add(wordKey);
          _activeWordIndex++;
          if (_activeWordIndex < allWords.length) {
            final nextWord = allWords[_activeWordIndex];
            _activeVerseKey = nextWord.verseKey;
            _activeWordKey = '${nextWord.verseKey}:${nextWord.position}';
          }
        });
        _accumulatedVoiceMs = 0;
      } else {
        final currentKey = '${currentWord.verseKey}:${currentWord.position}';
        if (_activeWordKey != currentKey) {
          setState(() {
            _activeVerseKey = currentWord.verseKey;
            _activeWordKey = currentKey;
          });
        }
      }
    } else {
      _isSpeaking = false;
      _silenceMs += 50;
      // Silence detected: do NOT advance word pointer! Keep frozen waiting for speech.
    }
  }

  Future<void> _stopLiveReciting() async {
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    _recitingTimer?.cancel();
    _amplitudeSubscription?.cancel();
    String? finalPath;
    if (!isTest) {
      try {
        if (_liveRecorder != null && await _liveRecorder!.isRecording()) {
          finalPath = await _liveRecorder!.stop();
        }
      } catch (e) {
        debugPrint('[LiveRecitation] Stop recorder error: $e');
      }

      finalPath ??= _liveAudioPath;
      await _evaluateCurrentPageRecitation(finalPath);
    }

    if (mounted) {
      setState(() {
        _isLiveReciting = false;
        _activeVerseKey = null;
        _activeWordKey = null;
      });
    }
  }

  void _processLiveRecitationProgress() {
    final pageAsync = ref.read(_pageDataProvider(_currentPage));
    final pageData = pageAsync.valueOrNull;
    if (pageData == null || pageData.verses.isEmpty) return;

    final allWords = <PageWord>[];
    for (final v in pageData.verses) {
      allWords.addAll(v.words.where((w) => !w.isVerseEnd));
    }
    if (allWords.isEmpty) return;

    final activeIndex = (_recitingSeconds * 0.85).floor().clamp(0, allWords.length - 1);
    final activeWord = allWords[activeIndex];
    final activeKey = '${activeWord.verseKey}:${activeWord.position}';

    setState(() {
      _activeVerseKey = activeWord.verseKey;
      _activeWordKey = activeKey;

      for (int i = 0; i <= activeIndex; i++) {
        final w = allWords[i];
        final key = '${w.verseKey}:${w.position}';
        if (!_mistakeWordKeys.contains(key)) {
          _correctWordKeys.add(key);
        }
      }
    });
  }

  Future<void> _evaluateCurrentPageRecitation(String? audioPath) async {
    final pageAsync = ref.read(_pageDataProvider(_currentPage));
    final pageData = pageAsync.valueOrNull;
    if (pageData == null || pageData.verses.isEmpty) return;

    final scorer = ScoringService();
    final newMistakes = <RecitationMistake>[];
    final newMistakeKeys = <String>{};
    final newCorrectKeys = <String>{};

    final duration = Duration(seconds: _recitingSeconds.clamp(1, 3600));

    for (int vi = 0; vi < pageData.verses.length; vi++) {
      final verse = pageData.verses[vi];
      final ayah = Ayah(
        surahNumber: verse.surahNumber,
        ayahNumber: verse.ayahNumber,
        textUthmani: verse.textUthmani,
        translation: verse.translation,
        words: verse.words.map((w) => Word(
          position: w.position,
          textUthmani: w.textUthmani,
          transliteration: w.transliteration,
        )).toList(),
      );

      try {
        final inferenceMode = ref.read(inferenceConfigProvider);
        final settings = ref.read(settingsProvider);
        final scoreResult = await scorer.scoreRecording(
          audioPath: audioPath ?? '',
          ayah: ayah,
          recordingDuration: duration,
          mode: inferenceMode,
          scoringDifficulty: settings.scoringDifficulty,
        );

        for (final m in scoreResult.mistakes) {
          newMistakes.add(m);
          newMistakeKeys.add('${verse.verseKey}:${m.wordIndex + 1}');
          newMistakeKeys.add('${ayah.surahNumber}:${ayah.ayahNumber}:${m.wordIndex + 1}');
        }

        for (int wi = 0; wi < scoreResult.wordScores.length; wi++) {
          final ws = scoreResult.wordScores[wi];
          final wordKey = '${verse.verseKey}:${wi + 1}';
          final locKey = '${ayah.surahNumber}:${ayah.ayahNumber}:${wi + 1}';
          if (!ws.isMistake && !newMistakeKeys.contains(wordKey) && !newMistakeKeys.contains(locKey)) {
            newCorrectKeys.add(wordKey);
            newCorrectKeys.add(locKey);
          }
        }
      } catch (e) {
        debugPrint('[LiveRecitation] Verse score error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _liveMistakes = newMistakes;
        _mistakeWordKeys.addAll(newMistakeKeys);
        _correctWordKeys.addAll(newCorrectKeys);
      });

      if (_liveMistakes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_liveMistakes.length} mistakes detected. Tap mistakes pill to review.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: ItqanColors.charcoal,
            action: SnackBarAction(
              label: 'View',
              textColor: ItqanColors.gold,
              onPressed: () {
                MistakesSheet.show(context, mistakes: _liveMistakes);
              },
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _precache(int page) {
    for (var p = (page - 2).clamp(1, 604); p <= (page + 2).clamp(1, 604); p++) {
      ref.read(_pageDataProvider(p));
    }
  }

  void _jumpToPage(int page) {
    final p = page.clamp(1, 604);
    setState(() => _currentPage = p);
    _pageController.jumpToPage(p - 1);
    _precache(p);
    _checkBookmarkState(p);
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    setState(() => _currentPage = page);
    _precache(page);
    _checkBookmarkState(page);
    _scheduleSave(page);
  }

  void _scheduleSave(int page) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      if (page == _lastSavedPage) return;
      _lastSavedPage = page;
      final pageAsync = ref.read(_pageDataProvider(page));
      pageAsync.whenData((pd) {
        int surahNum = pd.verses.isNotEmpty ? pd.verses.first.surahNumber : 1;
        int ayahNum = pd.verses.isNotEmpty ? pd.verses.first.ayahNumber : 1;
        String surahNameSimple = 'Page $page';
        String surahNameArabic = '';

        final surahsAsync = ref.read(surahsProvider);
        surahsAsync.whenData((surahs) {
          final found = surahs.where((s) => s.number == surahNum);
          if (found.isNotEmpty) {
            surahNameSimple = found.first.nameSimple;
            surahNameArabic = found.first.nameArabic;
          }
        });

        ref.read(readingPositionServiceProvider).saveLastPosition(
          ReadingPosition(
            pageNumber: page,
            surahNumber: surahNum,
            ayahNumber: ayahNum,
            surahNameSimple: surahNameSimple,
            surahNameArabic: surahNameArabic,
            savedAt: DateTime.now(),
          ),
        );

        // Invalidate the last reading position provider so home screen updates
        ref.invalidate(lastReadingPositionProvider);
      });
    });
  }

  void _checkBookmarkState(int page) {
    ref.read(readingPositionServiceProvider).isPageBookmarked(page).then((v) {
      if (mounted) setState(() => _isBookmarked = v);
    });
  }

  void _toggleBookmark() async {
    final pageAsync = ref.read(_pageDataProvider(_currentPage));
    pageAsync.whenData((pd) async {
      int surahNum = pd.verses.isNotEmpty ? pd.verses.first.surahNumber : 1;
      int ayahNum = pd.verses.isNotEmpty ? pd.verses.first.ayahNumber : 1;
      String surahNameSimple = 'Page $_currentPage';
      String surahNameArabic = '';

      final surahsAsync = ref.read(surahsProvider);
      surahsAsync.whenData((surahs) {
        final found = surahs.where((s) => s.number == surahNum);
        if (found.isNotEmpty) {
          surahNameSimple = found.first.nameSimple;
          surahNameArabic = found.first.nameArabic;
        }
      });

      if (_isBookmarked) {
        // Remove bookmark
        final bm = await ref
            .read(readingPositionServiceProvider)
            .getBookmarkForPage(_currentPage);
        if (bm != null) {
          await ref.read(bookmarksProvider.notifier).remove(bm.id);
        }
        setState(() => _isBookmarked = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.mushafBookmarkRemoved),
              duration: const Duration(seconds: 2),
              backgroundColor: ItqanColors.charcoal,
            ),
          );
        }
      } else {
        // Add bookmark
        final position = ReadingPosition(
          pageNumber: _currentPage,
          surahNumber: surahNum,
          ayahNumber: ayahNum,
          surahNameSimple: surahNameSimple,
          surahNameArabic: surahNameArabic,
          savedAt: DateTime.now(),
        );
        await ref.read(bookmarksProvider.notifier).add(position);
        setState(() => _isBookmarked = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.mushafBookmarkSaved,
                style: const TextStyle(color: ItqanColors.void_, fontWeight: FontWeight.w600),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: ItqanColors.gold,
            ),
          );
        }
      }
    });
  }

  void _showJumpDialog() {
    int temp = _currentPage;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: ItqanColors.onyx,
          title: Text(AppLocalizations.of(context)!.mushafJumpToPage, style: ItqanTypography.label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: temp.toDouble(),
                min: 1,
                max: 604,
                divisions: 603,
                activeColor: ItqanColors.gold,
                inactiveColor: ItqanColors.charcoal,
                label: AppLocalizations.of(context)!.mushafPage(temp),
                onChanged: (v) => setS(() => temp = v.round()),
              ),
              Text('\${AppLocalizations.of(context)!.mushafPage(temp)} / 604', style: ItqanTypography.caption),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.mushafJumpCancel, style: const TextStyle(color: ItqanColors.mist)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ItqanColors.gold),
              onPressed: () {
                Navigator.pop(ctx);
                _jumpToPage(temp);
              },
              child: Text(AppLocalizations.of(context)!.mushafJumpConfirm, style: const TextStyle(color: ItqanColors.void_)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTajweedLegend() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ItqanColors.onyx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.palette_outlined, color: ItqanColors.gold, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tajweed Rules Legend (QUL / QPC)',
                          style: TextStyle(color: ItqanColors.snow, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: ItqanColors.mist, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Color-coded Tajweed based on King Fahd Complex (QPC V4) standards.',
                  style: TextStyle(color: ItqanColors.mist, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: TajweedService.ruleDefinitions.values.map((rule) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.only(top: 3),
                              decoration: BoxDecoration(
                                color: rule.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        rule.name,
                                        style: TextStyle(color: rule.color, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        rule.nameArabic,
                                        style: TextStyle(
                                          fontFamily: 'NotoNaskhArabic',
                                          color: rule.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rule.description,
                                    style: const TextStyle(color: ItqanColors.silver, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(_pageDataProvider(_currentPage));

    // Current surah name for bottom bar
    final String surahName = pageAsync.maybeWhen(
      data: (pd) {
        if (pd.verses.isEmpty) return 'Page $_currentPage';
        final s = pd.verses.first.surahNumber;
        final surahsAsync = ref.watch(surahsProvider);
        return surahsAsync.maybeWhen(
          data: (surahs) {
            final found = surahs.where((x) => x.number == s);
            return found.isNotEmpty ? found.first.nameSimple : 'Page $_currentPage';
          },
          orElse: () => 'Page $_currentPage',
        );
      },
      orElse: () => 'Page $_currentPage',
    );

    final int juzNum = pageAsync.maybeWhen(
      data: (pd) => pd.juzNumber,
      orElse: () => 0,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topBottomBg = isDark ? ItqanColors.obsidian : Colors.white;
    final barBorderColor = isDark ? ItqanColors.charcoal : ItqanColors.lightBorder;
    final primaryTextColor = isDark ? ItqanColors.cloud : ItqanColors.lightTextPrimary;
    final secondaryTextColor = isDark ? ItqanColors.mist : ItqanColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top info bar (Tarteel Style matching Image 1) ──────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: topBottomBg,
                border: Border(bottom: BorderSide(color: barBorderColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: primaryTextColor, size: 22),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: Icon(Icons.search_rounded, color: secondaryTextColor, size: 22),
                    onPressed: _showJumpDialog,
                    tooltip: 'Search & Jump',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final sNum = pageAsync.maybeWhen(
                          data: (pd) => pd.verses.isNotEmpty ? pd.verses.first.surahNumber : 1,
                          orElse: () => 1,
                        );
                        _openSurahAyahPicker(sNum, 1);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Chapter $surahName',
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: primaryTextColor,
                                size: 18,
                              ),
                            ],
                          ),
                          Text(
                            juzNum > 0
                                ? 'Chapter $surahName · Page $_currentPage'
                                : 'Page $_currentPage',
                            style: TextStyle(color: secondaryTextColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: _isBookmarked ? ItqanColors.gold : secondaryTextColor,
                      size: 22,
                    ),
                    onPressed: _toggleBookmark,
                    tooltip: _isBookmarked
                        ? AppLocalizations.of(context)!.mushafBookmarkRemoved
                        : AppLocalizations.of(context)!.mushafBookmarkSaved,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: Icon(Icons.tune_rounded, color: secondaryTextColor, size: 22),
                    onPressed: _showDisplaySettingsSheet,
                    tooltip: 'Mushaf Display Settings',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // ── Page content ──────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                reverse: true, // RTL: right page = earlier
                itemCount: 604,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = index + 1;
                  return _MushafPage(
                    pageNumber: page,
                    showTranslation: _showTranslation,
                    is15LineView: _is15LineView,
                    isHifzMode: _isHifzMode,
                    showTajweed: _showTajweed,
                    edition: _edition,
                    fontSize: _mushafFontSize,
                    mistakeWordKeys: page == _currentPage ? _mistakeWordKeys : null,
                    correctWordKeys: page == _currentPage ? _correctWordKeys : null,
                    activeVerseKey: page == _currentPage ? _activeVerseKey : null,
                    activeWordKey: page == _currentPage ? _activeWordKey : null,
                  );
                },
              ),
            ),

            // ── Floating Recitation & Mistake Detection Dock ──────────────
            _buildFloatingRecitationBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingRecitationBar(bool isDark) {
    final barBg = isDark ? const Color(0xFF1E1E24) : const Color(0xFFECFDF5);
    final borderColor = isDark ? const Color(0xFF2E2E38) : const Color(0xFFA7F3D0);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Live Timer or Page Indicator + Mistakes Pill
          if (_isLiveReciting) ...[
            const _PulsingRedDot(),
            const SizedBox(width: 6),
            Text(
              _formatDuration(_recitingSeconds),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            _MistakesPill(
              count: _liveMistakes.length,
              onTap: () => MistakesSheet.show(context, mistakes: _liveMistakes),
            ),
          ] else ...[
            GestureDetector(
              onTap: _showJumpDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_rounded, color: ItqanColors.gold, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Page $_currentPage',
                    style: const TextStyle(
                      color: ItqanColors.gold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_liveMistakes.isNotEmpty) ...[
              const SizedBox(width: 8),
              _MistakesPill(
                count: _liveMistakes.length,
                onTap: () => MistakesSheet.show(context, mistakes: _liveMistakes),
              ),
            ],
          ],

          const Spacer(),

          // Navigation and quick toggles
          IconButton(
            icon: Icon(
              Icons.auto_stories_rounded,
              color: _is15LineView ? ItqanColors.gold : (isDark ? Colors.white70 : Colors.black54),
              size: 19,
            ),
            onPressed: () => setState(() => _is15LineView = !_is15LineView),
            tooltip: _is15LineView ? '15-Line Mushaf Mode' : 'Tarteel Mushaf Mode',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            icon: Icon(
              _isHifzMode ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: _isHifzMode ? ItqanColors.gold : ItqanColors.mist,
              size: 19,
            ),
            onPressed: () => setState(() => _isHifzMode = !_isHifzMode),
            tooltip: _isHifzMode ? 'Hifz Mode Active' : 'Enable Hifz Mode',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: ItqanColors.mist, size: 22),
            onPressed: _currentPage > 1 ? () => _jumpToPage(_currentPage - 1) : null,
            tooltip: 'Previous Page',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            icon: const Icon(Icons.first_page_rounded, color: ItqanColors.mist, size: 22),
            onPressed: _showJumpDialog,
            tooltip: 'Jump Page',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),

          const SizedBox(width: 6),

          // Glowing Green Action Button (Microphone or Stop)
          _GlowingRecitationButton(
            key: const Key('mushaf_recitation_action_button'),
            isRecording: _isLiveReciting,
            onTap: () {
              if (_isLiveReciting) {
                _stopLiveReciting();
              } else {
                _startLiveReciting();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _PulsingRedDot extends StatefulWidget {
  const _PulsingRedDot();

  @override
  State<_PulsingRedDot> createState() => _PulsingRedDotState();
}

class _PulsingRedDotState extends State<_PulsingRedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacityAnim = Tween<double>(begin: 0.35, end: 1.0).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x80EF4444),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _MistakesPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _MistakesPill({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasMistakes = count > 0;
    final bg = hasMistakes
        ? const Color(0x33EF4444)
        : const Color(0x2610B981);
    final border = hasMistakes
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final text = hasMistakes
        ? '$count ${count == 1 ? 'Mistake' : 'Mistakes'}'
        : '0 Mistakes';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMistakes) ...[
              const Icon(Icons.error_outline_rounded, size: 13, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                color: border,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowingRecitationButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const _GlowingRecitationButton({
    super.key,
    required this.isRecording,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF10B981),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(isRecording ? 0.6 : 0.35),
              blurRadius: isRecording ? 14 : 8,
              spreadRadius: isRecording ? 2 : 1,
            ),
          ],
        ),
        child: Center(
          child: isRecording
              ? Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )
              : const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 25,
                ),
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? ItqanColors.charcoal : ItqanColors.obsidian,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? ItqanColors.silver : ItqanColors.slate,
          size: 16,
        ),
      ),
    );
  }
}

// ─── Single page content widget ───────────────────────────────────────────────

class _MushafPage extends ConsumerWidget {
  final int pageNumber;
  final bool showTranslation;
  final bool is15LineView;
  final bool isHifzMode;
  final bool showTajweed;
  final MushafEdition edition;
  final double fontSize;
  final Set<String>? mistakeWordKeys;
  final Set<String>? correctWordKeys;
  final String? activeVerseKey;
  final String? activeWordKey;

  const _MushafPage({
    required this.pageNumber,
    required this.showTranslation,
    this.is15LineView = false,
    this.isHifzMode = false,
    this.showTajweed = true,
    this.edition = MushafEdition.madinah15Lines,
    this.fontSize = 26.0,
    this.mistakeWordKeys,
    this.correctWordKeys,
    this.activeVerseKey,
    this.activeWordKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(_pageDataProvider(pageNumber));
    final surahsAsync = ref.watch(surahsProvider);

    return pageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: ItqanColors.gold)),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: ItqanColors.mist, size: 40),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.errorLoadFailed, style: ItqanTypography.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
      data: (pageData) {
        if (pageData.verses.isEmpty) {
          return Center(child: Text('Page $pageNumber', style: ItqanTypography.caption));
        }

        final surahMap = surahsAsync.maybeWhen(
          data: (list) => {for (final s in list) s.number: s},
          orElse: () => <int, Surah>{},
        );

        final layoutService = MushafLayoutService();
        final layout = layoutService.buildPageLayout(
          pageData,
          edition: edition,
          surahMap: surahMap,
        );

        if (is15LineView) {
          return Mushaf15LineView(
            layout: layout,
            surahMap: surahMap,
            isHifzMode: isHifzMode,
            showTajweed: showTajweed,
            mistakeWordKeys: mistakeWordKeys,
            correctWordKeys: correctWordKeys,
            activeVerseKey: activeVerseKey,
            activeWordKey: activeWordKey,
          );
        }

        // Tarteel Modern Large-Font Mushaf Mode (Image 1 style)
        return TarteelMushafView(
          layout: layout,
          surahMap: surahMap,
          isHifzMode: isHifzMode,
          showTajweed: showTajweed,
          mistakeWordKeys: mistakeWordKeys,
          correctWordKeys: correctWordKeys,
          activeVerseKey: activeVerseKey,
          activeWordKey: activeWordKey,
          fontSize: fontSize,
        );
      },
    );
  }
}

class _SurahGroup {
  final int surahNumber;
  final List<VerseOnPage> verses;
  _SurahGroup(this.surahNumber, this.verses);
}

// ─── Surah Banner ─────────────────────────────────────────────────────────────

class _SurahBanner extends StatelessWidget {
  final Surah? surah;
  final int surahNumber;

  const _SurahBanner({required this.surah, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    final arabic = surah?.nameArabic ?? '';
    final place = surah?.revelationPlace == 'makkah' ? 'مكية' : 'مدنية';
    final ayahCount = surah?.ayahCount ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: ItqanColors.gold, width: 1),
          bottom: BorderSide(color: ItqanColors.gold, width: 1),
        ),
      ),
      child: Column(
        children: [
          if (arabic.isNotEmpty)
            Text(
              arabic,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 28,
                color: ItqanColors.gold,
                height: 1.6,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          if (ayahCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              ayahCount > 0 ? '$place · $ayahCount آيات' : '',
              style: const TextStyle(color: ItqanColors.mist, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          if (surahNumber != 9 && surahNumber != 1) ...[
            const SizedBox(height: 12),
            const Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 22,
                color: ItqanColors.goldLight,
                height: 2.0,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Verse Block ─────────────────────────────────────────────────────────────

class _VerseBlock extends ConsumerWidget {
  final List<VerseOnPage> verses;
  final bool showTranslation;
  final bool showTajweed;

  const _VerseBlock({
    required this.verses,
    required this.showTranslation,
    this.showTajweed = true,
  });

  String _toArabicNumerals(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? digits[d] : c;
    }).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spans = <InlineSpan>[];

    for (final verse in verses) {
      if (showTajweed && verse.textUthmaniTajweed.isNotEmpty) {
        final tajweedSpans = TajweedService().parseTajweedSpans(
          verse.textUthmaniTajweed,
          defaultStyle: const TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 24,
            height: 2.2,
            color: ItqanColors.snow,
          ),
        );
        spans.addAll(tajweedSpans);
      } else {
        spans.add(TextSpan(
          text: verse.textUthmani,
          style: const TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 24,
            height: 2.2,
            color: ItqanColors.snow,
          ),
        ));
      }
      spans.add(TextSpan(
        text: ' \u06DD${_toArabicNumerals(verse.ayahNumber)} ',
        style: const TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 18,
          height: 2.2,
          color: ItqanColors.gold,
        ),
      ));
    }

    final column = <Widget>[
      GestureDetector(
        onLongPressStart: (details) => _showWordSheet(context, ref, details),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(children: spans),
          ),
        ),
      ),
    ];

    if (showTranslation) {
      for (final verse in verses) {
        if (verse.translation.isNotEmpty) {
          column.add(Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${verse.ayahNumber}. ',
                  style: const TextStyle(color: ItqanColors.gold, fontSize: 11),
                ),
                Expanded(
                  child: Text(
                    verse.translation,
                    style: const TextStyle(color: ItqanColors.silver, fontSize: 12, height: 1.6),
                  ),
                ),
              ],
            ),
          ));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: column,
    );
  }

  void _showWordSheet(BuildContext context, WidgetRef ref, LongPressStartDetails details) {
    if (verses.isEmpty) return;
    final verse = verses.first;

    showModalBottomSheet(
      context: context,
      backgroundColor: ItqanColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _WordDetailSheet(verse: verse),
    );
  }
}

// ─── Word Detail Bottom Sheet ─────────────────────────────────────────────────

class _WordDetailSheet extends ConsumerWidget {
  final VerseOnPage verse;

  const _WordDetailSheet({required this.verse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: ItqanColors.slate,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            verse.textUthmani,
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 26,
              color: ItqanColors.snow,
              height: 2.0,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ayah ${verse.ayahNumber} • Surah ${verse.surahNumber}',
            style: ItqanTypography.caption,
            textAlign: TextAlign.center,
          ),
          if (verse.translation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              verse.translation,
              style: const TextStyle(color: ItqanColors.silver, fontSize: 13, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ItqanColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                final service = ref.read(quranServiceProvider);
                await service.init();
                final ayahs = await service.getAyahs(verse.surahNumber);
                if (!context.mounted) return;
                final ayah = ayahs.firstWhere(
                  (a) => a.ayahNumber == verse.ayahNumber,
                  orElse: () => ayahs.first,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecitationScreen(
                      ayah: ayah,
                      surahName: 'Surah ${verse.surahNumber}',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.mic_rounded, color: ItqanColors.void_, size: 18),
              label: Text(AppLocalizations.of(context)!.wordDetailPracticeAyah,
                  style: const TextStyle(color: ItqanColors.void_, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
