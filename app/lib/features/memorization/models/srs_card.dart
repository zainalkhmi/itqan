enum SrsStage {
  learning, // repetition 0 (new or failed recently)
  reviewing, // repetition 1..4 (in active spaced repetition cycle)
  mastered, // repetition >= 5 (well established long-term memory)
}

class SrsCard {
  final String id; // Format: "${surahNumber}_${ayahNumber}"
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String textUthmani;
  final int repetition; // Number of consecutive successful reviews (grade >= 3)
  final int intervalDays; // Current interval in days before next review
  final double easeFactor; // SM-2 ease factor (starts at 2.5, min 1.3)
  final DateTime nextReviewDate;
  final DateTime? lastReviewedDate;
  final double? lastScore;
  final int mistakeCount;
  final int totalReviews;

  const SrsCard({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.textUthmani,
    this.repetition = 0,
    this.intervalDays = 1,
    this.easeFactor = 2.5,
    required this.nextReviewDate,
    this.lastReviewedDate,
    this.lastScore,
    this.mistakeCount = 0,
    this.totalReviews = 0,
  });

  bool get isDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDay = DateTime(nextReviewDate.year, nextReviewDate.month, nextReviewDate.day);
    return !reviewDay.isAfter(today);
  }

  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDay = DateTime(nextReviewDate.year, nextReviewDate.month, nextReviewDate.day);
    return reviewDay.difference(today).inDays;
  }

  SrsStage get stage {
    if (repetition >= 5) return SrsStage.mastered;
    if (repetition >= 1) return SrsStage.reviewing;
    return SrsStage.learning;
  }

  String get stageName {
    switch (stage) {
      case SrsStage.learning:
        return 'Learning';
      case SrsStage.reviewing:
        return 'Reviewing ($intervalDays d)';
      case SrsStage.mastered:
        return 'Mastered';
    }
  }

  SrsCard copyWith({
    String? id,
    int? surahNumber,
    int? ayahNumber,
    String? surahName,
    String? textUthmani,
    int? repetition,
    int? intervalDays,
    double? easeFactor,
    DateTime? nextReviewDate,
    DateTime? lastReviewedDate,
    double? lastScore,
    int? mistakeCount,
    int? totalReviews,
  }) {
    return SrsCard(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      surahName: surahName ?? this.surahName,
      textUthmani: textUthmani ?? this.textUthmani,
      repetition: repetition ?? this.repetition,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewedDate: lastReviewedDate ?? this.lastReviewedDate,
      lastScore: lastScore ?? this.lastScore,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'surahName': surahName,
    'textUthmani': textUthmani,
    'repetition': repetition,
    'intervalDays': intervalDays,
    'easeFactor': easeFactor,
    'nextReviewDate': nextReviewDate.toIso8601String(),
    'lastReviewedDate': lastReviewedDate?.toIso8601String(),
    'lastScore': lastScore,
    'mistakeCount': mistakeCount,
    'totalReviews': totalReviews,
  };

  factory SrsCard.fromMap(Map map) => SrsCard(
    id: map['id']?.toString() ?? '',
    surahNumber: (map['surahNumber'] as num?)?.toInt() ?? 1,
    ayahNumber: (map['ayahNumber'] as num?)?.toInt() ?? 1,
    surahName: map['surahName']?.toString() ?? '',
    textUthmani: map['textUthmani']?.toString() ?? '',
    repetition: (map['repetition'] as num?)?.toInt() ?? 0,
    intervalDays: (map['intervalDays'] as num?)?.toInt() ?? 1,
    easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
    nextReviewDate: map['nextReviewDate'] != null
        ? DateTime.parse(map['nextReviewDate'])
        : DateTime.now(),
    lastReviewedDate: map['lastReviewedDate'] != null
        ? DateTime.parse(map['lastReviewedDate'])
        : null,
    lastScore: (map['lastScore'] as num?)?.toDouble(),
    mistakeCount: (map['mistakeCount'] as num?)?.toInt() ?? 0,
    totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
  );
}

