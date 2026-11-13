import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../quran/models/ayah.dart';
import '../recitation/recitation_screen.dart';
import '../mushaf/mushaf_screen.dart';
import 'models/voice_search_match.dart';
import 'services/voice_search_service.dart';

enum VoiceSearchState { idle, listening, searching, result, error }

class VoiceSearchScreen extends ConsumerStatefulWidget {
  const VoiceSearchScreen({super.key});

  @override
  ConsumerState<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends ConsumerState<VoiceSearchScreen> with SingleTickerProviderStateMixin {
  VoiceSearchState _state = VoiceSearchState.idle;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioPath;
  Timer? _listeningTimer;
  VoiceSearchMatch? _topMatch;
  List<VoiceSearchMatch> _matches = [];
  String? _errorMessage;
  List<VoiceSearchMatch> _recentHistory = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final service = ref.read(voiceSearchServiceProvider);
    await service.init();
    if (mounted) {
      setState(() {
        _recentHistory = service.getHistory();
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    _listeningTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_state == VoiceSearchState.listening) {
      await _stopListeningAndSearch();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      setState(() {
        _state = VoiceSearchState.error;
        _errorMessage = 'Microphone permission required for Voice Search';
      });
      return;
    }

    setState(() {
      _state = VoiceSearchState.listening;
      _errorMessage = null;
      _topMatch = null;
    });
    _pulseController.repeat(reverse: true);

    String? path;
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/voice_search_${DateTime.now().millisecondsSinceEpoch}.wav';
    }
    _audioPath = path;

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
      path: path ?? '',
    );

    // Automatically search after 5 seconds of listening if not stopped manually
    _listeningTimer = Timer(const Duration(seconds: 5), () {
      if (_state == VoiceSearchState.listening) {
        _stopListeningAndSearch();
      }
    });
  }

  Future<void> _stopListeningAndSearch([String? simulatedQuery]) async {
    _listeningTimer?.cancel();
    _pulseController.stop();

    setState(() => _state = VoiceSearchState.searching);

    String? recordedPath;
    try {
      recordedPath = await _recorder.stop();
    } catch (_) {}

    final service = ref.read(voiceSearchServiceProvider);
    try {
      final results = await service.identifyRecitation(
        audioPath: recordedPath ?? _audioPath,
        textQuery: simulatedQuery,
      );

      if (mounted) {
        setState(() {
          if (results.isNotEmpty) {
            _matches = results;
            _topMatch = results.first;
            _state = VoiceSearchState.result;
            _recentHistory = service.getHistory();
          } else {
            _state = VoiceSearchState.error;
            _errorMessage = 'No matching Ayah found. Please recite clearly.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = VoiceSearchState.error;
          _errorMessage = 'Search error: $e';
        });
      }
    }
  }

  void _navigateToRecitation(VoiceSearchMatch match) {
    final tokens = match.textUthmani.split(' ');
    final words = <Word>[];
    for (int i = 0; i < tokens.length; i++) {
      words.add(Word(
        position: i + 1,
        textUthmani: tokens[i],
        transliteration: '',
      ));
    }

    final ayah = Ayah(
      surahNumber: match.surah,
      ayahNumber: match.ayah,
      textUthmani: match.textUthmani,
      words: words,
      translation: match.translation,
    );

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => RecitationScreen(ayah: ayah, surahName: match.surahName),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        backgroundColor: ItqanColors.void_,
        title: const Text('Quran Voice Search', style: ItqanTypography.heading2),
        actions: [
          IconButton(
            tooltip: 'How Voice Search Works',
            icon: const Icon(Icons.info_outline_rounded, color: ItqanColors.gold),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ItqanSpacing.lg, vertical: ItqanSpacing.md),
        child: Column(
          children: [
            const SizedBox(height: ItqanSpacing.sm),
            const Text(
              'Shazam for the Holy Quran',
              style: TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Recite any verse or play audio — AI will find the Surah & Ayah instantly',
              style: ItqanTypography.caption.copyWith(color: ItqanColors.mist),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ItqanSpacing.xl),

            // Pulsing Radar Mic Area
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final scale = (_state == VoiceSearchState.listening) ? _pulseAnimation.value : 1.0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_state == VoiceSearchState.listening) ...[
                        Container(
                          width: 170 * scale,
                          height: 170 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ItqanColors.gold.withValues(alpha: 0.12),
                          ),
                        ),
                        Container(
                          width: 140 * scale,
                          height: 140 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ItqanColors.gold.withValues(alpha: 0.25),
                          ),
                        ),
                      ],
                      GestureDetector(
                        onTap: _toggleListening,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [ItqanColors.gold, Color(0xFFB8860B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ItqanColors.gold.withValues(alpha: 0.4),
                                blurRadius: 18,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            _state == VoiceSearchState.listening
                                ? Icons.stop_rounded
                                : (_state == VoiceSearchState.searching
                                    ? Icons.hourglass_top_rounded
                                    : Icons.mic_rounded),
                            size: 46,
                            color: ItqanColors.void_,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: ItqanSpacing.lg),

            // Status label
            Text(
              _statusLabel(),
              style: TextStyle(
                color: _state == VoiceSearchState.listening ? ItqanColors.gold : Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ItqanSpacing.md),

            // Quick Samples Chips
            if (_state == VoiceSearchState.idle || _state == VoiceSearchState.error) ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _sampleChip('Surah Al-Fatihah', 'الحمد لله رب العالمين'),
                  _sampleChip('Ayat Kursi', 'الله لا اله الا هو الحي القيوم'),
                  _sampleChip('Al-Ikhlas', 'قل هو الله احد'),
                  _sampleChip('An-Nas', 'قل اعوذ برب الناس'),
                ],
              ),
              const SizedBox(height: ItqanSpacing.lg),
            ],

            // Result Card
            if (_topMatch != null) ...[
              _buildResultCard(_topMatch!),
              const SizedBox(height: ItqanSpacing.lg),
            ],

            // Error display
            if (_errorMessage != null && _state == VoiceSearchState.error) ...[
              Container(
                padding: const EdgeInsets.all(ItqanSpacing.md),
                decoration: BoxDecoration(
                  color: ItqanColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(ItqanRadius.md),
                  border: Border.all(color: ItqanColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: ItqanColors.error),
                    const SizedBox(width: ItqanSpacing.sm),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white))),
                  ],
                ),
              ),
              const SizedBox(height: ItqanSpacing.lg),
            ],

            // Recent Searches Section
            if (_recentHistory.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 18, color: ItqanColors.gold),
                    const SizedBox(width: 8),
                    const Text('Recent Voice Identifications', style: ItqanTypography.label),
                  ],
                ),
              ),
              const SizedBox(height: ItqanSpacing.sm),
              ..._recentHistory.take(4).map((h) => _buildHistoryTile(h)),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel() {
    switch (_state) {
      case VoiceSearchState.listening:
        return 'Listening... Recite an Ayah';
      case VoiceSearchState.searching:
        return 'Analyzing speech & scanning Quran...';
      case VoiceSearchState.result:
        return 'Ayah Identified!';
      case VoiceSearchState.error:
        return 'Tap microphone to try again';
      case VoiceSearchState.idle:
        return 'Tap microphone and start reciting';
    }
  }

  Widget _sampleChip(String label, String arabicQuery) {
    return ActionChip(
      backgroundColor: ItqanColors.onyx,
      side: const BorderSide(color: ItqanColors.charcoal),
      label: Text(label, style: const TextStyle(color: ItqanColors.snow, fontSize: 12)),
      avatar: const Icon(Icons.search_rounded, size: 14, color: ItqanColors.gold),
      onPressed: () => _stopListeningAndSearch(arabicQuery),
    );
  }

  Widget _buildResultCard(VoiceSearchMatch match) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      decoration: BoxDecoration(
        color: ItqanColors.onyx,
        borderRadius: BorderRadius.circular(ItqanRadius.lg),
        border: Border.all(color: ItqanColors.gold.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ItqanColors.gold.withValues(alpha: 0.15),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${match.surahName} (${match.surahArabic})',
                    style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('Surah ${match.surah} • Ayah ${match.ayah}', style: ItqanTypography.caption),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ItqanColors.correct.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ItqanColors.correct),
                ),
                child: Text(
                  '${match.confidence.toStringAsFixed(1)}% Match',
                  style: const TextStyle(color: ItqanColors.correct, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: ItqanSpacing.md),

          // Arabic Uthmani text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ItqanSpacing.md),
            decoration: BoxDecoration(
              color: ItqanColors.void_,
              borderRadius: BorderRadius.circular(ItqanRadius.md),
            ),
            child: Text(
              match.textUthmani,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 22,
                color: ItqanColors.snow,
                height: 1.9,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: ItqanSpacing.sm),

          // Translation
          Text(
            match.translation,
            style: const TextStyle(color: ItqanColors.mist, fontStyle: FontStyle.italic, fontSize: 13),
          ),
          const SizedBox(height: ItqanSpacing.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ItqanColors.gold,
                    foregroundColor: ItqanColors.void_,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  label: const Text('Practice & Hifz', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _navigateToRecitation(match),
                ),
              ),
              const SizedBox(width: ItqanSpacing.sm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ItqanColors.gold),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                icon: const Icon(Icons.menu_book_rounded, color: ItqanColors.gold, size: 18),
                label: const Text('Mushaf', style: TextStyle(color: ItqanColors.gold)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const MushafScreen(),
                  ));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(VoiceSearchMatch item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ItqanColors.onyx,
        borderRadius: BorderRadius.circular(ItqanRadius.md),
        border: Border.all(color: ItqanColors.charcoal),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ItqanColors.gold.withValues(alpha: 0.15),
          child: Text('${item.surah}', style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold)),
        ),
        title: Text('${item.surahName} (${item.surah}:${item.ayah})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(item.textUthmani, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'NotoNaskhArabic', color: ItqanColors.mist)),
        trailing: const Icon(Icons.chevron_right_rounded, color: ItqanColors.mist),
        onTap: () => setState(() {
          _topMatch = item;
          _state = VoiceSearchState.result;
        }),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ItqanColors.onyx,
        title: const Text('About Voice Search', style: TextStyle(color: ItqanColors.gold)),
        content: const Text(
          'Quran Voice Search uses Whisper speech recognition and Arabic phonetic alignment to identify any Ayah from your voice or live audio playback in seconds — matching Tarteel\'s famous "Shazam for Quran" capability.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: ItqanColors.gold)),
          ),
        ],
      ),
    );
  }
}
