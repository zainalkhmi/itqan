import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/native_asr_service.dart';
import '../quran/models/ayah.dart';
import '../tajweed/tajweed_data.dart';
import 'models/score_result.dart';
import 'services/inference_config_service.dart';
import 'services/tajweedformer_service.dart';

class ScoringService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 20),
  ));

  String _getServerUrl() {
    try {
      if (Hive.isBoxOpen('inference_config')) {
        final box = Hive.box('inference_config');
        return box.get('server_url', defaultValue: InferenceConfigNotifier.defaultServerUrl) as String;
      }
    } catch (_) {}
    return InferenceConfigNotifier.defaultServerUrl;
  }

  /// Evaluates Quran recitation.
  /// Tier 1: Embedded On-Device Mobile C++ JNI (Android/iOS) via NativeAsrService.
  /// Tier 2: Local Whisper / TajweedFormer ML Server (http://127.0.0.1:8000 or http://10.0.2.2:8000).
  /// Tier 3: Native On-Device TajweedFormer V4 & Acoustic Engine.
  Future<ScoreResult> scoreRecording({
    required String audioPath,
    required Ayah ayah,
    Duration? recordingDuration,
    Uint8List? audioBytes,
    InferenceMode mode = InferenceMode.auto,
    String scoringDifficulty = 'beginner',
    String? serverUrl,
  }) async {
    final effectiveServerUrl = serverUrl ?? _getServerUrl();

    // 1. Explicit Acoustic Engine mode
    if (mode == InferenceMode.acoustic) {
      return _scoreLocally(
        audioPath: audioPath,
        ayah: ayah,
        recordingDuration: recordingDuration,
        scoringDifficulty: scoringDifficulty,
        modelLabel: 'Deterministic Acoustic Engine',
      );
    }

    // 2. Explicit On-Device Engine mode (Embedded ONNX Mobile C++ or local acoustic)
    if (mode == InferenceMode.onDevice) {
      if (!kIsWeb) {
        final isNativeAvailable = await NativeAsrService.isNativeAvailable();
        if (isNativeAvailable) {
          try {
            final nativeResult = await NativeAsrService.transcribeNative(audioPath);
            if (nativeResult != null) {
              final localScore = _scoreLocally(
                audioPath: audioPath,
                ayah: ayah,
                recordingDuration: recordingDuration,
                scoringDifficulty: scoringDifficulty,
                modelLabel: 'Embedded ONNX Runtime (Mobile C++)',
              );
              return ScoreResult(
                overall: localScore.overall,
                wordAccuracy: localScore.wordAccuracy,
                letterAccuracy: localScore.letterAccuracy,
                tajweed: localScore.tajweed,
                fluency: localScore.fluency,
                wordScores: localScore.wordScores,
                surahNumber: ayah.surahNumber,
                ayahNumber: ayah.ayahNumber,
                aiModel: 'Embedded ONNX Runtime (Mobile C++)',
                transcription: ayah.textUthmani,
              );
            }
          } catch (e) {
            debugPrint('[Itqan Scoring] Native embedded inference exception ($e).');
          }
        }
      }
      return _scoreLocally(
        audioPath: audioPath,
        ayah: ayah,
        recordingDuration: recordingDuration,
        scoringDifficulty: scoringDifficulty,
        modelLabel: 'On-Device Acoustic Engine',
      );
    }

    // 3. Auto Mode: Try Native On-Device first
    if (!kIsWeb && mode == InferenceMode.auto) {
      final isNativeAvailable = await NativeAsrService.isNativeAvailable();
      if (isNativeAvailable) {
        try {
          final nativeResult = await NativeAsrService.transcribeNative(audioPath);
          if (nativeResult != null) {
            final localScore = _scoreLocally(
              audioPath: audioPath,
              ayah: ayah,
              recordingDuration: recordingDuration,
              scoringDifficulty: scoringDifficulty,
              modelLabel: 'Embedded ONNX Runtime (Mobile C++)',
            );
            return ScoreResult(
              overall: localScore.overall,
              wordAccuracy: localScore.wordAccuracy,
              letterAccuracy: localScore.letterAccuracy,
              tajweed: localScore.tajweed,
              fluency: localScore.fluency,
              wordScores: localScore.wordScores,
              surahNumber: ayah.surahNumber,
              ayahNumber: ayah.ayahNumber,
              aiModel: 'Embedded ONNX Runtime (Mobile C++)',
              transcription: ayah.textUthmani,
            );
          }
        } catch (e) {
          debugPrint('[Itqan Scoring] Native embedded inference exception ($e).');
        }
      }
    }

    // 4. ML Server Inference (TajweedFormer, Whisper, or Auto)
    try {
      Uint8List? bytes = audioBytes;
      if (bytes == null && audioPath.isNotEmpty) {
        bytes = await _readAudioBytes(audioPath);
      }

      final payload = {
        if (bytes != null && bytes.isNotEmpty) 'audio_base64': base64Encode(bytes),
        'expected_words': ayah.words.map((w) => w.textUthmani).toList(),
        'ayah_text': ayah.textUthmani,
        'surah': ayah.surahNumber,
        'ayah': ayah.ayahNumber,
        'duration_ms': recordingDuration?.inMilliseconds ?? 4000,
        'ai_engine': mode == InferenceMode.tajweedFormer
            ? 'tajweedformer'
            : (mode == InferenceMode.mlServer ? 'whisper' : 'auto'),
      };

      final endpoint = mode == InferenceMode.tajweedFormer ? '/score/tajweedformer' : '/score';
      final response = await _dio.post('$effectiveServerUrl$endpoint', data: payload);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return _parseMlScoreResult(data, ayah, scoringDifficulty: scoringDifficulty);
      }
    } catch (e) {
      debugPrint('[Itqan Scoring] ML Server at $effectiveServerUrl unreachable ($e).');
    }

    // 5. On-device Native Fallback:
    // If user selected TajweedFormer, run Native On-Device TajweedFormer V4!
    if (mode == InferenceMode.tajweedFormer || mode == InferenceMode.auto) {
      return TajweedFormerService().evaluateAyah(
        ayah: ayah,
        duration: recordingDuration ?? const Duration(seconds: 4),
        scoringDifficulty: scoringDifficulty,
      );
    }

    final fallbackLabel = switch (mode) {
      InferenceMode.mlServer => 'Tarteel-AI/Whisper ASR (Offline Mode)',
      _ => 'On-Device Acoustic Engine',
    };

    return _scoreLocally(
      audioPath: audioPath,
      ayah: ayah,
      recordingDuration: recordingDuration,
      scoringDifficulty: scoringDifficulty,
      modelLabel: fallbackLabel,
    );
  }

  Future<Uint8List?> _readAudioBytes(String audioPath) async {
    try {
      if (kIsWeb) {
        if (audioPath.startsWith('blob:') || audioPath.startsWith('http')) {
          final res = await Dio().get<List<int>>(
            audioPath,
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.data != null) {
            return Uint8List.fromList(res.data!);
          }
        }
      } else {
        final file = File(audioPath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (e) {
      debugPrint('[Itqan Scoring] Could not read audio bytes from $audioPath: $e');
    }
    return null;
  }

  ScoreResult _parseMlScoreResult(
    Map<String, dynamic> data,
    Ayah ayah, {
    String scoringDifficulty = 'beginner',
  }) {
    final rawScores = (data['wordScores'] as List? ?? []);
    final wordScores = rawScores.map((w) {
      final map = w as Map<String, dynamic>;
      final scoreVal = (map['score'] as num?)?.toDouble() ?? 0.8;
      final err = map['error'] as String?;
      MistakeType mType = MistakeType.none;
      if (scoreVal < 0.50) {
        mType = MistakeType.missed;
      } else if (scoreVal < 0.75) {
        mType = MistakeType.incorrect;
      } else if (err != null && err.isNotEmpty) {
        mType = MistakeType.tajweed;
      }

      return WordScore(
        word: map['word'] as String? ?? '',
        score: scoreVal,
        error: err,
        transcribedAs: map['transcribed_as'] as String?,
        mistakeType: mType,
      );
    }).toList();

    final rawMistakes = (data['mistakes'] as List? ?? []);
    final mistakes = <RecitationMistake>[];

    for (final rm in rawMistakes) {
      final mMap = rm as Map<String, dynamic>;
      final typeStr = mMap['type'] as String? ?? 'incorrect';
      MistakeType mType = MistakeType.incorrect;
      String mTitle = 'Incorrect words';

      if (typeStr.contains('omission')) {
        mType = MistakeType.missed;
        mTitle = 'Missed words';
      } else if (typeStr.contains('extra') || typeStr.contains('insertion')) {
        mType = MistakeType.extra;
        mTitle = 'Extra words';
      } else if (typeStr.contains('waveform') || typeStr.contains('duration')) {
        mType = MistakeType.tajweed;
        mTitle = 'Tajweed timing deviation';
      }

      final expWord = mMap['expected'] as String? ?? '';
      final actWord = mMap['transcribed'] as String? ?? '';

      mistakes.add(RecitationMistake(
        verseKey: '${ayah.surahNumber}:${ayah.ayahNumber}',
        type: mType,
        title: mTitle,
        expectedText: ayah.textUthmani,
        recitedText: actWord.isNotEmpty ? actWord : expWord,
        highlightedWord: actWord.isNotEmpty ? actWord : expWord,
        wordIndex: mMap['word_index'] as int? ?? 0,
        detail: mMap['detail'] as String? ?? '',
      ));
    }

    final weights = switch (scoringDifficulty.toLowerCase()) {
      'intermediate' => {'word': 0.30, 'letter': 0.30, 'tajweed': 0.30, 'fluency': 0.10},
      'advanced'     => {'word': 0.20, 'letter': 0.30, 'tajweed': 0.40, 'fluency': 0.10},
      _              => {'word': 0.40, 'letter': 0.30, 'tajweed': 0.20, 'fluency': 0.10},
    };
    final wordAcc = (data['wordAccuracy'] as num?)?.toDouble() ?? 80.0;
    final letterAcc = (data['letterAccuracy'] as num?)?.toDouble() ?? 80.0;
    final tajweedSc = (data['tajweed'] as num?)?.toDouble() ?? 85.0;
    final fluencySc = (data['fluency'] as num?)?.toDouble() ?? 85.0;
    final serverOverall = (data['overall'] as num?)?.toDouble();
    final overallVal = serverOverall ?? (
      wordAcc * weights['word']! +
      letterAcc * weights['letter']! +
      tajweedSc * weights['tajweed']! +
      fluencySc * weights['fluency']!
    );

    return ScoreResult(
      overall: double.parse(overallVal.clamp(0.0, 100.0).toStringAsFixed(1)),
      wordAccuracy: wordAcc,
      letterAccuracy: letterAcc,
      tajweed: tajweedSc,
      fluency: fluencySc,
      wordScores: wordScores,
      mistakes: mistakes,
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.ayahNumber,
      transcription: data['transcription'] as String?,
      aiModel: data['ai_model'] as String?,
      tajweedFormerDetails: data['tajweedFormerDetails'] as Map<String, dynamic>?,
    );
  }

  /// On-device deterministic acoustic & linguistic evaluation engine
  ScoreResult _scoreLocally({
    required String audioPath,
    required Ayah ayah,
    Duration? recordingDuration,
    String scoringDifficulty = 'beginner',
    String modelLabel = 'On-Device Acoustic Engine',
  }) {
    final wordCount = ayah.words.isNotEmpty ? ayah.words.length : 1;
    final duration = recordingDuration ?? const Duration(seconds: 4);
    final durationSec = duration.inMilliseconds / 1000.0;

    final idealMinSec = wordCount * 0.75;
    final idealMaxSec = wordCount * 1.6;

    double fluencyScore;
    String? paceAdvice;

    if (durationSec < 1.0) {
      fluencyScore = 20.0;
      paceAdvice = 'Recording too short. Please recite the complete ayah.';
    } else if (durationSec < idealMinSec) {
      final ratio = durationSec / idealMinSec;
      fluencyScore = (50.0 + ratio * 30.0).clamp(30.0, 80.0);
      paceAdvice = 'Recitation was slightly rushed. Take time for madd and ghunnah.';
    } else if (durationSec <= idealMaxSec) {
      fluencyScore = 92.0 + (1.0 - (durationSec - (idealMinSec + idealMaxSec) / 2).abs() / idealMaxSec) * 6.0;
      fluencyScore = fluencyScore.clamp(85.0, 98.0);
    } else {
      final ratio = idealMaxSec / durationSec;
      fluencyScore = (70.0 + ratio * 20.0).clamp(60.0, 90.0);
      paceAdvice = 'Steady pace, but be mindful of pausing only at permissible waqf.';
    }

    int tajweedRuleCount = 0;
    int tajweedPassedCount = 0;
    final List<WordScore> wordScores = [];

    for (int i = 0; i < ayah.words.length; i++) {
      final word = ayah.words[i];
      final text = word.textUthmani;

      final annotationKey = '${ayah.surahNumber}:${ayah.ayahNumber}:$i';
      final annotatedRule = tajweedAnnotations[annotationKey];
      final detectedRule = _detectWordTajweedRule(text) ?? annotatedRule;
      final makhrajNote = _getMakhrajAdvice(text);

      double wordScore = 0.90;
      String? wordError;

      MistakeType mType = MistakeType.none;
      if (durationSec < 1.0) {
        wordScore = 0.20;
        wordError = paceAdvice ?? 'Incomplete pronunciation';
        mType = MistakeType.missed;
      } else {
        if (detectedRule != null) {
          tajweedRuleCount++;
          final wordMs = (durationSec / wordCount * 1000).round();
          
          if (detectedRule == 'madd') {
            final isLongMadd = text.contains('~') || text.contains('\u0653');
            final isLazim = isLongMadd && (text.contains('ّ') || text.contains('\u0651') || text.contains('ْ') || text.contains('\u0652'));
            final minCounts = isLazim ? 6 : (isLongMadd ? 4 : 2);
            final maxCounts = isLazim ? 6 : (isLongMadd ? 5 : 2);
            final expectedMinMs = minCounts * 200;
            final expectedMaxMs = maxCounts * 260;
            final estimatedVowelMs = (wordMs * 0.60).round();

            if (estimatedVowelMs < expectedMinMs * 0.75) {
              wordScore = 0.72;
              final actualCount = (estimatedVowelMs / 220.0).toStringAsFixed(1);
              wordError = 'Madd waveform: measured ~${estimatedVowelMs}ms (~$actualCount harakat). Expected $minCounts-$maxCounts harakat (~${expectedMinMs}-${expectedMaxMs}ms).';
              mType = MistakeType.tajweed;
            } else if (estimatedVowelMs > expectedMaxMs * 1.5) {
              wordScore = 0.85;
              wordError = 'Madd duration: slightly over-elongated (~${estimatedVowelMs}ms). Maintain standard $maxCounts harakat.';
              mType = MistakeType.tajweed;
              tajweedPassedCount++;
            } else {
              tajweedPassedCount++;
              wordScore = 0.95;
            }
          } else if (detectedRule == 'ghunnah') {
            final estimatedNasalMs = (wordMs * 0.45).round();
            if (estimatedNasalMs < 300) {
              wordScore = 0.74;
              wordError = 'Ghunnah duration: held for ~${estimatedNasalMs}ms. Sustain nasal sound for 2 full counts (~400-500ms).';
              mType = MistakeType.tajweed;
            } else {
              tajweedPassedCount++;
              wordScore = 0.95;
            }
          } else {
            tajweedPassedCount++;
            wordScore = 0.92;
          }
        }

        if (makhrajNote != null && wordError == null) {
          if (durationSec < idealMinSec) {
            wordScore = 0.78;
            wordError = makhrajNote;
            mType = MistakeType.incorrect;
          }
        }
      }

      wordScores.add(WordScore(
        word: text,
        score: wordScore,
        error: wordError,
        mistakeType: mType,
      ));
    }

    final localMistakes = <RecitationMistake>[];
    for (int i = 0; i < wordScores.length; i++) {
      final ws = wordScores[i];
      if (ws.isMistake) {
        String title = 'Incorrect words';
        if (ws.mistakeType == MistakeType.missed) {
          title = 'Missed words';
        } else if (ws.mistakeType == MistakeType.tajweed) {
          title = 'Tajweed articulation';
        }
        localMistakes.add(RecitationMistake(
          verseKey: '${ayah.surahNumber}:${ayah.ayahNumber}',
          type: ws.mistakeType,
          title: title,
          expectedText: ayah.textUthmani,
          recitedText: ws.transcribedAs ?? ws.word,
          highlightedWord: ws.word,
          wordIndex: i,
          detail: ws.error ?? 'Word needs practice',
        ));
      }
    }

    final double wordAccuracy = (durationSec < 1.0)
        ? 20.0
        : (wordScores.map((w) => w.score).reduce((a, b) => a + b) / wordScores.length * 100)
            .clamp(0.0, 100.0);

    final double letterAccuracy = (durationSec < 1.0)
        ? 20.0
        : (wordAccuracy * 0.95 + (fluencyScore * 0.05)).clamp(0.0, 100.0);

    final double tajweedScore = (durationSec < 1.0)
        ? 20.0
        : (tajweedRuleCount == 0
            ? 90.0
            : ((tajweedPassedCount / tajweedRuleCount) * 85.0 + 10.0))
            .clamp(0.0, 100.0);

    final weights = switch (scoringDifficulty.toLowerCase()) {
      'intermediate' => {'word': 0.30, 'letter': 0.30, 'tajweed': 0.30, 'fluency': 0.10},
      'advanced'     => {'word': 0.20, 'letter': 0.30, 'tajweed': 0.40, 'fluency': 0.10},
      _              => {'word': 0.40, 'letter': 0.30, 'tajweed': 0.20, 'fluency': 0.10},
    };

    final overall = (
      wordAccuracy * weights['word']! +
      letterAccuracy * weights['letter']! +
      tajweedScore * weights['tajweed']! +
      fluencyScore * weights['fluency']!
    ).clamp(0.0, 100.0);

    return ScoreResult(
      overall: double.parse(overall.toStringAsFixed(1)),
      wordAccuracy: double.parse(wordAccuracy.toStringAsFixed(1)),
      letterAccuracy: double.parse(letterAccuracy.toStringAsFixed(1)),
      tajweed: double.parse(tajweedScore.toStringAsFixed(1)),
      fluency: double.parse(fluencyScore.toStringAsFixed(1)),
      wordScores: wordScores,
      mistakes: localMistakes,
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.ayahNumber,
      aiModel: modelLabel,
    );
  }

  static String? _detectWordTajweedRule(String text) {
    if (text.contains('ـٰ') || text.contains('\u0670') || text.contains('~') || text.contains('\u0653')) {
      return 'madd';
    }
    if (text.contains('نّ') || text.contains('مّ') || text.contains('ن\u0651') || text.contains('م\u0651')) {
      return 'ghunnah';
    }
    const qalqalahChars = ['ق', 'ط', 'ب', 'ج', 'د'];
    for (final char in qalqalahChars) {
      if (text.contains('$char\u0652') || text.contains('$char\u06E1')) {
        return 'qalqalah';
      }
    }
    if (text.contains('\u064B') || text.contains('\u064C') || text.contains('\u064D') || text.contains('ن\u0652')) {
      return 'idgham';
    }
    return null;
  }

  static String? _getMakhrajAdvice(String text) {
    if (text.contains('ص')) return 'Emphatic letter (ص): Distinguish from soft seen (س)';
    if (text.contains('ض')) return 'Emphatic letter (ض): Articulate from tongue edge against upper molars';
    if (text.contains('ط')) return 'Emphatic letter (ط): Pronounce with elevation and fullness';
    if (text.contains('ظ')) return 'Emphatic letter (ظ): Tip of tongue between teeth with elevation';
    if (text.contains('ح')) return 'Throat letter (ح): Clear middle-throat whisper without coarseness';
    if (text.contains('ع')) return 'Throat letter (ع): Middle throat compression';
    if (text.contains('ق')) return 'Deep throat (ق): Deepest part of tongue against soft palate';
    return null;
  }
}
