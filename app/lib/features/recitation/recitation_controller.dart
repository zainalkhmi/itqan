import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../quran/models/ayah.dart';
import '../quran/data/quran_catalog.dart';
import '../scoring/scoring_service.dart';
import '../scoring/models/score_result.dart';
import '../offline/services/audio_download_service.dart';
import '../settings/settings_service.dart';
import '../scoring/services/inference_config_service.dart';
import 'widgets/word_token.dart';

enum RecitationState { idle, playing, recording, processing, scored }

class RecitationData {
  final RecitationState state;
  final Ayah? ayah;
  final ScoreResult? result;
  final Duration recordingDuration;
  final String? error;
  final Map<int, WordState> liveWordStates;
  final int activeWordIndex;
  final String? detectedSurahName;

  const RecitationData({
    this.state = RecitationState.idle,
    this.ayah,
    this.result,
    this.recordingDuration = Duration.zero,
    this.error,
    this.liveWordStates = const {},
    this.activeWordIndex = 0,
    this.detectedSurahName,
  });

  RecitationData copyWith({
    RecitationState? state,
    Ayah? ayah,
    ScoreResult? result,
    Duration? recordingDuration,
    String? error,
    Map<int, WordState>? liveWordStates,
    int? activeWordIndex,
    String? detectedSurahName,
  }) {
    return RecitationData(
      state: state ?? this.state,
      ayah: ayah ?? this.ayah,
      result: result ?? this.result,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      error: error,
      liveWordStates: liveWordStates ?? this.liveWordStates,
      activeWordIndex: activeWordIndex ?? this.activeWordIndex,
      detectedSurahName: detectedSurahName ?? this.detectedSurahName,
    );
  }
}

class RecitationController extends StateNotifier<RecitationData> {
  final Ref? _ref;
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  final ScoringService _scorer = ScoringService();
  Timer? _recordingTimer;
  String? _currentRecordingPath;

  RecitationController([this._ref]) : super(const RecitationData()) {
    _player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        if (mounted && state.state == RecitationState.playing) {
          state = state.copyWith(state: RecitationState.idle);
        }
      }
    });
  }

  void loadAyah(Ayah ayah) {
    String? surahName;
    try {
      final s = QuranCatalog.getSurah(ayah.surahNumber);
      surahName = s.nameSimple;
    } catch (_) {
      surahName = 'Surah ${ayah.surahNumber}';
    }
    state = RecitationData(
      ayah: ayah,
      detectedSurahName: surahName,
      liveWordStates: const {},
      activeWordIndex: 0,
    );
  }

  Future<void> listen() async {
    if (state.ayah == null) return;
    if (state.state == RecitationState.playing) {
      await _player.stop();
      state = state.copyWith(state: RecitationState.idle);
      return;
    }
    try {
      state = state.copyWith(state: RecitationState.playing, error: null);
      final settings = _ref?.read(settingsProvider) ?? const AppSettings();
      final audioService = AudioDownloadService();
      await audioService.init();

      final surah = state.ayah!.surahNumber;
      final ayah = state.ayah!.ayahNumber;
      final isDownloaded = audioService.isAyahAudioDownloaded(surah, ayah);

      if (isDownloaded && settings.defaultQari.toLowerCase() == 'alafasy') {
        final localPath = audioService.getLocalAudioPath(surah, ayah);
        if (localPath != null) {
          await _player.setFilePath(localPath);
        } else {
          await _player.setUrl(state.ayah!.getAudioUrlForQari(settings.defaultQari));
        }
      } else {
        await _player.setUrl(state.ayah!.getAudioUrlForQari(settings.defaultQari));
      }
      await _player.setSpeed(settings.playbackSpeed);
      await _player.play();
    } catch (e) {
      state = state.copyWith(state: RecitationState.idle, error: 'Audio error: $e');
    }
  }

  Future<void> startRecording() async {
    if (state.state != RecitationState.idle) return;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(error: 'Microphone permission denied');
      return;
    }

    AudioEncoder encoder = AudioEncoder.aacLc;
    if (await _recorder.isEncoderSupported(AudioEncoder.wav)) {
      encoder = AudioEncoder.wav;
    }

    String? recordingPath;
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      final ext = encoder == AudioEncoder.wav ? 'wav' : 'm4a';
      recordingPath = '${dir.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.$ext';
    }
    _currentRecordingPath = recordingPath;

    await _recorder.start(
      RecordConfig(encoder: encoder, sampleRate: 16000, numChannels: 1),
      path: recordingPath ?? '',
    );

    String? surahName;
    if (state.ayah != null) {
      try {
        final s = QuranCatalog.getSurah(state.ayah!.surahNumber);
        surahName = s.nameSimple;
      } catch (_) {
        surahName = 'Surah ${state.ayah!.surahNumber}';
      }
    }

    state = state.copyWith(
      state: RecitationState.recording,
      recordingDuration: Duration.zero,
      liveWordStates: const {},
      activeWordIndex: 0,
      detectedSurahName: surahName,
    );

    _recordingTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (mounted) {
        final newDuration = state.recordingDuration + const Duration(milliseconds: 700);
        final wordsCount = state.ayah?.words.isNotEmpty == true
            ? state.ayah!.words.length
            : (state.ayah?.textUthmani.trim().split(RegExp(r'\s+')).length ?? 0);

        final updatedStates = Map<int, WordState>.from(state.liveWordStates);
        int nextActiveIndex = state.activeWordIndex;

        if (wordsCount > 0) {
          final elapsedSec = newDuration.inMilliseconds / 1000.0;
          final targetIndex = (elapsedSec / 0.9).floor().clamp(0, wordsCount - 1);

          for (int i = 0; i < targetIndex; i++) {
            if (!updatedStates.containsKey(i)) {
              updatedStates[i] = WordState.correct;
            }
          }
          nextActiveIndex = targetIndex;
        }

        state = state.copyWith(
          recordingDuration: newDuration,
          liveWordStates: updatedStates,
          activeWordIndex: nextActiveIndex,
        );
      }
    });
  }

  Future<void> stopRecording() async {
    if (state.state != RecitationState.recording) return;
    _recordingTimer?.cancel();

    final path = await _recorder.stop();
    if (path != null && path.isNotEmpty) {
      _currentRecordingPath = path;
    } else {
      _currentRecordingPath ??= 'recording_${DateTime.now().millisecondsSinceEpoch}';
    }
    state = state.copyWith(state: RecitationState.processing);

    if (state.ayah != null && _currentRecordingPath != null) {
      try {
        final inferenceMode = _ref?.read(inferenceConfigProvider) ?? InferenceMode.auto;
        final settings = _ref?.read(settingsProvider) ?? const AppSettings();
        final result = await _scorer.scoreRecording(
          audioPath: _currentRecordingPath!,
          ayah: state.ayah!,
          recordingDuration: state.recordingDuration,
          mode: inferenceMode,
          scoringDifficulty: settings.scoringDifficulty,
        );

        final finalWordStates = <int, WordState>{};
        for (int i = 0; i < result.wordScores.length; i++) {
          final ws = result.wordScores[i];
          finalWordStates[i] = ws.isMistake ? WordState.error : WordState.correct;
        }

        state = state.copyWith(
          state: RecitationState.scored,
          result: result,
          liveWordStates: finalWordStates,
          activeWordIndex: result.wordScores.length,
        );
        await _saveSession(result);
      } catch (e) {
        state = state.copyWith(state: RecitationState.idle, error: 'Scoring failed: $e');
      }
    }
  }

  Future<void> _saveSession(ScoreResult result) async {
    try {
      if (!Hive.isBoxOpen('sessions')) {
        await Hive.openBox('sessions');
      }
      final box = Hive.box('sessions');
      await box.add({
        'surah': result.surahNumber,
        'ayah': result.ayahNumber,
        'overall': result.overall,
        'wordAccuracy': result.wordAccuracy,
        'letterAccuracy': result.letterAccuracy,
        'tajweed': result.tajweed,
        'fluency': result.fluency,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Non-fatal: ignore Hive errors
    }
  }

  void retry() {
    state = RecitationData(
      ayah: state.ayah,
      detectedSurahName: state.detectedSurahName,
      liveWordStates: const {},
      activeWordIndex: 0,
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }
}

final recitationProvider = StateNotifierProvider.autoDispose<RecitationController, RecitationData>(
  (ref) => RecitationController(ref),
);
