import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/adaptive/adaptive_service.dart';

void main() {
  group('AdaptiveService Diagnostic Assessment', () {
    test('determineLevel correctly categorizes proficiency', () {
      expect(AdaptiveService.determineLevel(92.0), equals('advanced'));
      expect(AdaptiveService.determineLevel(85.0), equals('advanced'));
      expect(AdaptiveService.determineLevel(84.9), equals('intermediate'));
      expect(AdaptiveService.determineLevel(70.0), equals('intermediate'));
      expect(AdaptiveService.determineLevel(69.9), equals('beginner'));
      expect(AdaptiveService.determineLevel(45.0), equals('beginner'));
    });

    test('diagnosticAyahs contains 3 calibrated verses covering core tajweed challenges', () {
      final ayahs = AdaptiveService.diagnosticAyahs;
      expect(ayahs.length, equals(3));
      expect(ayahs[0].surahNumber, equals(1)); // Al-Fatiha
      expect(ayahs[1].surahNumber, equals(112)); // Al-Ikhlas
      expect(ayahs[2].surahNumber, equals(114)); // An-Nas
    });

    test('analyzeDynamicDifficulty adjusts tolerance for high performance', () {
      final sessions = [
        {'overall': 92.0},
        {'overall': 94.0},
        {'overall': 91.0},
        {'overall': 95.0},
      ];
      final res = AdaptiveService.analyzeDynamicDifficulty(
        sessions: sessions,
        currentLevel: 'beginner',
      );
      expect(res['adaptiveLevel'], equals('intermediate'));
      expect(res['toleranceOffset'], equals(-3.0));
      expect(res['rollingAverage'], greaterThanOrEqualTo(90.0));
    });

    test('analyzeDynamicDifficulty adjusts tolerance for struggling performance', () {
      final sessions = [
        {'overall': 60.0},
        {'overall': 58.0},
        {'overall': 62.0},
      ];
      final res = AdaptiveService.analyzeDynamicDifficulty(
        sessions: sessions,
        currentLevel: 'intermediate',
      );
      expect(res['toleranceOffset'], equals(5.0)); // Gives forgiveness
    });
  });
}

