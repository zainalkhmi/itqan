import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../quran/models/ayah.dart';
import '../scoring/scoring_service.dart';
import '../scoring/models/score_result.dart';
import '../offline/services/audio_download_service.dart';
import '../settings/settings_service.dart';
import '../scoring/services/inference_config_service.dart';

enum RecitationState { idle, playing, recording, processing, scored }

class RecitationData {
  final RecitationState state;
  final Ayah? ayah;
  final ScoreResult? result;
  final Duration recordingDuration;
  final String? error;
  final bool isSpeaking;
  final List<double>? recentWaveform;
  final String? currentRecordingPath;

  const RecitationData({
    this.state = RecitationState.idle,
    this.ayah,
    this.result,
    this.recordingDuration = Duration.zero,
    this.error,
    this.isSpeaking = false,
    this.recentWaveform,
    this.currentRecordingPath,
  });

  RecitationData copyWith({
    RecitationState? state,
    Ayah? ayah,
    ScoreResult? result,
    Duration? recordingDuration,
    String? error,
    bool? isSpeaking,
    List<double>? recentWaveform,
    String? currentRecordingPath,
  }) {
    return RecitationData(
      state: state ?? this.state,
      ayah: ayah ?? this.ayah,
      result: result ?? this.result,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      error: error,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      recentWaveform: recentWaveform ?? this.recentWaveform,
      currentRecordingPath: currentRecordingPath ?? this.currentRecordingPath,
    );
  }
}

class RecitationController extends StateNotifier<RecitationData> {
  final Ref? _ref;
  final AudioPlayer _player = AudioPlayer();
  AudioRecorder _recorder = AudioRecorder();
  final ScoringService _scorer = ScoringService();
  Timer? _recordingTimer;
  StreamSubscription<Amplitude>? _ampSub;
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
    state = RecitationData(ayah: ayah);
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
    // Allow starting when idle or scored (re-recording after previous evaluation)
    if (state.state == RecitationState.recording || state.state == RecitationState.processing) {
      return;
    }
    if (state.state == RecitationState.playing) {
      try {
        await _player.stop();
      } catch (_) {}
    }

    _recordingTimer?.cancel();
    _ampSub?.cancel();
    _ampSub = null;

    // Safely stop and dispose previous recorder instance to prevent stale native AudioRecord state on Android
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      await _recorder.dispose();
    } catch (_) {}
    _recorder = AudioRecorder();

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(error: 'Microphone permission denied', state: RecitationState.idle);
      return;
    }

    // Always prefer aacLc (.m4a) for rock-solid cross-platform and Android stability
    AudioEncoder encoder = AudioEncoder.aacLc;
    String ext = 'm4a';
    if (!kIsWeb && await _recorder.isEncoderSupported(AudioEncoder.wav)) {
      encoder = AudioEncoder.wav;
      ext = 'wav';
    }

    String? recordingPath;
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      recordingPath = '${dir.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.$ext';
    }
    _currentRecordingPath = recordingPath;

    try {
      await _recorder.start(
        RecordConfig(encoder: encoder, sampleRate: 16000, numChannels: 1),
        path: recordingPath ?? '',
      );
    } catch (e) {
      debugPrint('[RecitationController] Error starting recorder: $e');
      state = state.copyWith(error: 'Gagal memulai perekam audio: $e', state: RecitationState.idle);
      return;
    }

    state = state.copyWith(
      state: RecitationState.recording,
      recordingDuration: Duration.zero,
      recentWaveform: List.filled(40, 0.08),
      isSpeaking: false,
      currentRecordingPath: recordingPath,
      error: null,
    );

    // Real-time microphone amplitude streaming for voice recognition & waveform
    _ampSub?.cancel();
    _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
      if (!mounted || state.state != RecitationState.recording) return;
      final db = amp.current;
      final isSpeaking = db > -34.0;
      final norm = ((db + 45.0) / 45.0).clamp(0.08, 1.0);

      final currentBars = List<double>.from(state.recentWaveform ?? List.filled(40, 0.08));
      if (currentBars.length >= 40) {
        currentBars.removeAt(0);
      }
      currentBars.add(norm);

      state = state.copyWith(
        isSpeaking: isSpeaking,
        recentWaveform: currentBars,
      );
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        state = state.copyWith(
          recordingDuration: state.recordingDuration + const Duration(seconds: 1),
        );
      }
    });
  }

  Future<void> stopRecording() async {
    if (state.state != RecitationState.recording) return;
    _recordingTimer?.cancel();
    _ampSub?.cancel();
    _ampSub = null;

    final path = await _recorder.stop();
    if (path != null && path.isNotEmpty) {
      _currentRecordingPath = path;
    } else {
      _currentRecordingPath ??= 'recording_${DateTime.now().millisecondsSinceEpoch}';
    }
    state = state.copyWith(
      state: RecitationState.processing,
      currentRecordingPath: _currentRecordingPath,
    );

    if (state.ayah != null && _currentRecordingPath != null) {
      try {
        final inferenceMode = _ref?.read(inferenceConfigProvider) ?? InferenceMode.auto;
        final settings = _ref?.read(settingsProvider) ?? const AppSettings();
        final rawResult = await _scorer.scoreRecording(
          audioPath: _currentRecordingPath!,
          ayah: state.ayah!,
          recordingDuration: state.recordingDuration,
          mode: inferenceMode,
          scoringDifficulty: settings.scoringDifficulty,
        );
        final result = rawResult.copyWith(audioPath: _currentRecordingPath);
        state = state.copyWith(
          state: RecitationState.scored,
          result: result,
          currentRecordingPath: _currentRecordingPath,
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

  /// Deletes the recorded audio file from disk and resets the session cleanly.
  Future<void> deleteRecording() async {
    _recordingTimer?.cancel();
    _ampSub?.cancel();
    _ampSub = null;
    if (_currentRecordingPath != null && !kIsWeb) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[RecitationController] Delete recording error: $e');
      }
    }
    _currentRecordingPath = null;
    await retry();
  }

  Future<void> retry() async {
    _recordingTimer?.cancel();
    _ampSub?.cancel();
    _ampSub = null;
    if (state.state == RecitationState.recording) {
      try {
        await _recorder.stop();
      } catch (_) {}
    }
    if (state.state == RecitationState.playing) {
      try {
        await _player.stop();
      } catch (_) {}
    }
    _currentRecordingPath = null;
    state = RecitationData(
      ayah: state.ayah,
      state: RecitationState.idle,
      recordingDuration: Duration.zero,
      error: null,
      isSpeaking: false,
      currentRecordingPath: null,
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _ampSub?.cancel();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }
}

final recitationProvider = StateNotifierProvider.autoDispose<RecitationController, RecitationData>(
  (ref) => RecitationController(ref),
);
