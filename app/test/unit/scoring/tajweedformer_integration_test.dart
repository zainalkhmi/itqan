import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/scoring/models/score_result.dart';
import 'package:itqan/features/scoring/scoring_service.dart';
import 'package:itqan/features/scoring/services/inference_config_service.dart';
import 'package:itqan/features/quran/models/ayah.dart';

void main() {
  group('TajweedFormer V4 Integration Tests (Quran Lab)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tajweedformer_test_');
      Hive.init(tempDir.path);
      await Hive.openBox('inference_config');
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('InferenceMode enum includes tajweedFormer mode', () {
      expect(InferenceMode.values, contains(InferenceMode.tajweedFormer));
      expect(InferenceMode.tajweedFormer.name, equals('tajweedFormer'));
    });

    test('InferenceConfigNotifier persists and restores tajweedFormer mode', () async {
      final notifier = InferenceConfigNotifier();
      await notifier.setMode(InferenceMode.tajweedFormer);
      expect(notifier.state, equals(InferenceMode.tajweedFormer));

      final box = Hive.box('inference_config');
      expect(box.get('mode'), equals('tajweedFormer'));

      // Check status check for TajweedFormer
      final status = await notifier.checkStatus();
      expect(status.mode, equals(InferenceMode.tajweedFormer));
      expect(status.modelName, equals('Quran-Lab/TajweedFormer-v4'));
    });

    test('ScoreResult accurately stores and copies tajweedFormerDetails', () {
      final details = {
        'engine': 'Quran-Lab/TajweedFormer-v4',
        'vendor': 'Quran Lab (quranlab.ai)',
        'maddCount': 3,
        'ghunnahCount': 2,
        'qalqalahCount': 1,
        'tempo': 'Normal (Tadwir)',
      };

      const result = ScoreResult(
        overall: 95.0,
        wordAccuracy: 96.0,
        letterAccuracy: 97.0,
        tajweed: 98.0,
        fluency: 94.0,
        wordScores: [],
        surahNumber: 1,
        ayahNumber: 1,
        aiModel: 'Quran-Lab/TajweedFormer-v4',
        tajweedFormerDetails: {
          'engine': 'Quran-Lab/TajweedFormer-v4',
          'vendor': 'Quran Lab (quranlab.ai)',
          'maddCount': 3,
          'ghunnahCount': 2,
          'qalqalahCount': 1,
          'tempo': 'Normal (Tadwir)',
        },
      );

      expect(result.tajweedFormerDetails, isNotNull);
      expect(result.tajweedFormerDetails!['engine'], equals('Quran-Lab/TajweedFormer-v4'));
      expect(result.tajweedFormerDetails!['maddCount'], equals(3));
      expect(result.tajweedFormerDetails!['ghunnahCount'], equals(2));
      expect(result.tajweedFormerDetails!['qalqalahCount'], equals(1));

      final copied = result.copyWith(overall: 98.0);
      expect(copied.overall, equals(98.0));
      expect(copied.tajweedFormerDetails!['vendor'], equals('Quran Lab (quranlab.ai)'));
    });

    test('ScoringService falls back gracefully or queries TajweedFormer endpoint', () async {
      final service = ScoringService();
      const ayah = Ayah(
        surahNumber: 1,
        ayahNumber: 1,
        textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        translation: 'In the name of Allah...',
        words: [
          Word(position: 1, textUthmani: 'بِسْمِ', transliteration: 'bismi'),
          Word(position: 2, textUthmani: 'ٱللَّهِ', transliteration: 'l-lahi'),
          Word(position: 3, textUthmani: 'ٱلرَّحْمَـٰنِ', transliteration: 'r-rahmani'),
          Word(position: 4, textUthmani: 'ٱلرَّحِيمِ', transliteration: 'r-rahim'),
        ],
      );

      final result = await service.scoreRecording(
        audioPath: '',
        ayah: ayah,
        mode: InferenceMode.tajweedFormer,
      );

      expect(result, isNotNull);
      expect(result.overall, greaterThan(0));
      expect(result.wordScores.length, equals(4));
    });
  });
}
