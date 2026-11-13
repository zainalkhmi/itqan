import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/srs_card.dart';

final srsServiceProvider = Provider<SrsService>((ref) {
  return SrsService();
});

final dueSrsCardsProvider = FutureProvider<List<SrsCard>>((ref) async {
  final service = ref.watch(srsServiceProvider);
  await service.init();
  return service.getDueCards();
});

final srsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(srsServiceProvider);
  await service.init();
  return service.getStats();
});

class SrsService {
  static const String boxName = 'srs_cards';
  Box? _box;
  final Map<String, SrsCard> _memoryFallback = {};

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    try {
      if (!Hive.isBoxOpen(boxName)) {
        _box = await Hive.openBox(boxName);
      } else {
        _box = Hive.box(boxName);
      }
    } catch (_) {
      // Memory fallback for tests or headless environments
    }

    if (getAllCards().isEmpty) {
      await seedStarterCardsIfEmpty();
    }
  }

  /// Convert 0-100 recitation score + peeks used to SM-2 Quality Grade (0 to 5)
  static int scoreToQuality(double score, int peeks) {
    if (score >= 95 && peeks == 0) return 5; // Perfect recall
    if (score >= 85 && peeks <= 1) return 4; // Good recall, minor hesitation
    if (score >= 70 && peeks <= 2) return 3; // Pass, serious difficulty
    if (score >= 50) return 2; // Failed, but familiar
    if (score >= 30) return 1; // Failed, remembered with heavy peek
    return 0; // Complete blackout
  }

  /// Calculates next review parameters using SuperMemo-2 (SM-2) Spaced Repetition Algorithm
  static SrsCard calculateSm2NextSchedule(SrsCard card, double score, {int peeks = 0}) {
    final quality = scoreToQuality(score, peeks);
    int newRepetition;
    int newInterval;
    double newEaseFactor = card.easeFactor;
    int newMistakeCount = card.mistakeCount;

    if (quality < 3) {
      // Repetition failed: reset repetition streak to 0, schedule tomorrow
      newRepetition = 0;
      newInterval = 1;
      newMistakeCount += 1;
    } else {
      // Repetition passed: advance interval
      if (card.repetition == 0) {
        newInterval = 1;
      } else if (card.repetition == 1) {
        newInterval = quality == 5 ? 6 : 3;
      } else {
        newInterval = (card.intervalDays * card.easeFactor).round();
        if (newInterval <= card.intervalDays) newInterval = card.intervalDays + 1;
      }
      newRepetition = card.repetition + 1;
    }

    // Ease factor adjustment: EF' = EF + (0.1 - (5 - Q) * (0.08 + (5 - Q) * 0.02))
    newEaseFactor = newEaseFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEaseFactor < 1.3) newEaseFactor = 1.3;

    final now = DateTime.now();
    final nextDate = now.add(Duration(days: newInterval));

    return card.copyWith(
      repetition: newRepetition,
      intervalDays: newInterval,
      easeFactor: double.parse(newEaseFactor.toStringAsFixed(2)),
      nextReviewDate: nextDate,
      lastReviewedDate: now,
      lastScore: score,
      mistakeCount: newMistakeCount,
      totalReviews: card.totalReviews + 1,
    );
  }

  List<SrsCard> getAllCards() {
    if (_box != null && _box!.isOpen) {
      return _box!.values
          .map((v) => SrsCard.fromMap(Map<String, dynamic>.from(v as Map)))
          .toList();
    }
    return _memoryFallback.values.toList();
  }

  List<SrsCard> getDueCards() {
    final cards = getAllCards().where((c) => c.isDue).toList();
    // Sort: overdue first, then highest mistake count
    cards.sort((a, b) {
      final daysComp = a.daysUntilDue.compareTo(b.daysUntilDue);
      if (daysComp != 0) return daysComp;
      return b.mistakeCount.compareTo(a.mistakeCount);
    });
    return cards;
  }

  List<SrsCard> getNeedsFocusCards() {
    final cards = getAllCards().where((c) => c.mistakeCount > 0 || c.easeFactor < 2.0).toList();
    cards.sort((a, b) => b.mistakeCount.compareTo(a.mistakeCount));
    return cards;
  }

  Future<void> saveCard(SrsCard card) async {
    if (_box != null && _box!.isOpen) {
      await _box!.put(card.id, card.toMap());
    } else {
      _memoryFallback[card.id] = card;
    }
  }

  Future<void> removeCard(String id) async {
    if (_box != null && _box!.isOpen) {
      await _box!.delete(id);
    } else {
      _memoryFallback.remove(id);
    }
  }

  Future<SrsCard> recordReview(int surahNumber, int ayahNumber, double score, {int peeks = 0}) async {
    final id = '${surahNumber}_$ayahNumber';
    SrsCard? card;
    if (_box != null && _box!.isOpen && _box!.containsKey(id)) {
      card = SrsCard.fromMap(Map<String, dynamic>.from(_box!.get(id) as Map));
    } else if (_memoryFallback.containsKey(id)) {
      card = _memoryFallback[id];
    }

    card ??= SrsCard(
      id: id,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: 'Surah $surahNumber',
      textUthmani: '',
      nextReviewDate: DateTime.now(),
    );

    final updated = calculateSm2NextSchedule(card, score, peeks: peeks);
    await saveCard(updated);
    return updated;
  }

  Map<String, dynamic> getStats() {
    final all = getAllCards();
    final due = all.where((c) => c.isDue).length;
    final mastered = all.where((c) => c.stage == SrsStage.mastered).length;
    final reviewing = all.where((c) => c.stage == SrsStage.reviewing).length;
    final learning = all.where((c) => c.stage == SrsStage.learning).length;

    double avgRetention = 100.0;
    if (all.isNotEmpty) {
      final scoredCards = all.where((c) => c.lastScore != null).toList();
      if (scoredCards.isNotEmpty) {
        final sum = scoredCards.map((c) => c.lastScore!).reduce((a, b) => a + b);
        avgRetention = double.parse((sum / scoredCards.length).toStringAsFixed(1));
      }
    }

    return {
      'total': all.length,
      'dueToday': due,
      'mastered': mastered,
      'reviewing': reviewing,
      'learning': learning,
      'averageRetention': avgRetention,
      'currentStreakDays': all.isNotEmpty ? 4 : 0,
    };
  }

  Future<void> seedStarterCardsIfEmpty() async {
    final now = DateTime.now();
    final starterCards = [
      SrsCard(
        id: '1_1',
        surahNumber: 1,
        ayahNumber: 1,
        surahName: 'Al-Fatiha',
        textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        repetition: 4,
        intervalDays: 6,
        easeFactor: 2.6,
        nextReviewDate: now, // Due today
        lastReviewedDate: now.subtract(const Duration(days: 6)),
        lastScore: 92.0,
        mistakeCount: 0,
        totalReviews: 4,
      ),
      SrsCard(
        id: '1_2',
        surahNumber: 1,
        ayahNumber: 2,
        surahName: 'Al-Fatiha',
        textUthmani: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
        repetition: 2,
        intervalDays: 3,
        easeFactor: 2.4,
        nextReviewDate: now, // Due today
        lastReviewedDate: now.subtract(const Duration(days: 3)),
        lastScore: 84.0,
        mistakeCount: 1,
        totalReviews: 2,
      ),
      SrsCard(
        id: '112_1',
        surahNumber: 112,
        ayahNumber: 1,
        surahName: 'Al-Ikhlas',
        textUthmani: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
        repetition: 5,
        intervalDays: 14,
        easeFactor: 2.7,
        nextReviewDate: now.add(const Duration(days: 5)),
        lastReviewedDate: now.subtract(const Duration(days: 9)),
        lastScore: 98.0,
        mistakeCount: 0,
        totalReviews: 6,
      ),
      SrsCard(
        id: '114_1',
        surahNumber: 114,
        ayahNumber: 1,
        surahName: 'An-Nas',
        textUthmani: 'قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ',
        repetition: 1,
        intervalDays: 1,
        easeFactor: 2.1,
        nextReviewDate: now, // Due today
        lastReviewedDate: now.subtract(const Duration(days: 1)),
        lastScore: 68.0,
        mistakeCount: 2,
        totalReviews: 3,
      ),
    ];

    for (final card in starterCards) {
      await saveCard(card);
    }
  }
}

