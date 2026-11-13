import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/memorization/models/srs_card.dart';
import 'package:itqan/features/memorization/services/srs_service.dart';

void main() {
  group('SrsCard Model & Status Tests', () {
    test('isDue correctly calculates for past and future dates', () {
      final now = DateTime.now();
      final overdueCard = SrsCard(
        id: '1_1',
        surahNumber: 1,
        ayahNumber: 1,
        surahName: 'Al-Fatiha',
        textUthmani: 'بِسْمِ ٱللَّهِ',
        nextReviewDate: now.subtract(const Duration(days: 1)),
      );
      expect(overdueCard.isDue, isTrue);

      final futureCard = SrsCard(
        id: '1_2',
        surahNumber: 1,
        ayahNumber: 2,
        surahName: 'Al-Fatiha',
        textUthmani: 'ٱلْحَمْدُ لِلَّهِ',
        nextReviewDate: now.add(const Duration(days: 3)),
      );
      expect(futureCard.isDue, isFalse);
    });

    test('stage correctly identifies learning, reviewing, mastered', () {
      final learning = SrsCard(
        id: '1_1',
        surahNumber: 1,
        ayahNumber: 1,
        surahName: 'Al-Fatiha',
        textUthmani: 'بِسْمِ ٱللَّهِ',
        repetition: 0,
        nextReviewDate: DateTime.now(),
      );
      expect(learning.stage, equals(SrsStage.learning));

      final reviewing = learning.copyWith(repetition: 3);
      expect(reviewing.stage, equals(SrsStage.reviewing));

      final mastered = learning.copyWith(repetition: 5);
      expect(mastered.stage, equals(SrsStage.mastered));
    });

    test('serialization toMap and fromMap preserves data', () {
      final card = SrsCard(
        id: '112_1',
        surahNumber: 112,
        ayahNumber: 1,
        surahName: 'Al-Ikhlas',
        textUthmani: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
        repetition: 3,
        intervalDays: 8,
        easeFactor: 2.6,
        nextReviewDate: DateTime(2026, 12, 1),
        lastReviewedDate: DateTime(2026, 11, 23),
        lastScore: 94.0,
        mistakeCount: 1,
        totalReviews: 4,
      );

      final map = card.toMap();
      final revived = SrsCard.fromMap(map);

      expect(revived.id, equals('112_1'));
      expect(revived.surahNumber, equals(112));
      expect(revived.ayahNumber, equals(1));
      expect(revived.repetition, equals(3));
      expect(revived.intervalDays, equals(8));
      expect(revived.easeFactor, equals(2.6));
      expect(revived.mistakeCount, equals(1));
    });
  });

  group('SM-2 Algorithm Scheduling Tests', () {
    test('scoreToQuality converts grades with peek penalties correctly', () {
      expect(SrsService.scoreToQuality(96, 0), equals(5)); // Perfect
      expect(SrsService.scoreToQuality(96, 1), equals(4)); // 1 peek penalty
      expect(SrsService.scoreToQuality(88, 0), equals(4)); // Good
      expect(SrsService.scoreToQuality(72, 1), equals(3)); // Pass
      expect(SrsService.scoreToQuality(60, 0), equals(2)); // Failed
      expect(SrsService.scoreToQuality(20, 0), equals(0)); // Blackout
    });

    test('failed recitation resets repetition and schedules 1 day interval', () {
      final card = SrsCard(
        id: '1_1',
        surahNumber: 1,
        ayahNumber: 1,
        surahName: 'Al-Fatiha',
        textUthmani: 'بِسْمِ ٱللَّهِ',
        repetition: 3,
        intervalDays: 7,
        easeFactor: 2.5,
        nextReviewDate: DateTime.now(),
      );

      // Score 50 (< 70 => quality 2)
      final scheduled = SrsService.calculateSm2NextSchedule(card, 50);

      expect(scheduled.repetition, equals(0));
      expect(scheduled.intervalDays, equals(1));
      expect(scheduled.mistakeCount, equals(1));
      expect(scheduled.easeFactor, lessThan(2.5));
    });

    test('successful recitations increase repetition and interval exponentially', () {
      final card = SrsCard(
        id: '1_1',
        surahNumber: 1,
        ayahNumber: 1,
        surahName: 'Al-Fatiha',
        textUthmani: 'بِسْمِ ٱللَّهِ',
        repetition: 0,
        intervalDays: 1,
        easeFactor: 2.5,
        nextReviewDate: DateTime.now(),
      );

      // Repetition 0 -> 1: interval 1 day
      final first = SrsService.calculateSm2NextSchedule(card, 90);
      expect(first.repetition, equals(1));
      expect(first.intervalDays, equals(1));

      // Repetition 1 -> 2: interval 3-6 days
      final second = SrsService.calculateSm2NextSchedule(first, 95);
      expect(second.repetition, equals(2));
      expect(second.intervalDays, greaterThanOrEqualTo(3));

      // Repetition 2 -> 3: interval = previous * easeFactor
      final third = SrsService.calculateSm2NextSchedule(second, 95);
      expect(third.repetition, equals(3));
      expect(third.intervalDays, greaterThan(second.intervalDays));
    });
  });
}

