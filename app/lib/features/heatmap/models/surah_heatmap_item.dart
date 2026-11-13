enum MemorizationStatus {
  mutqin,   // >= 90% (Emerald Green)
  strong,   // 80 - 89% (Mint/Light Green)
  review,   // 70 - 79% (Amber/Yellow)
  weak,     // < 70% (Rose/Red)
  untested, // Not yet recited (Muted Charcoal)
}

class SurahHeatmapItem {
  final int surahNumber;
  final String name;
  final String arabicName;
  final int juzNumber;
  final int totalAyahs;
  final double retentionScore;
  final int testedAyahs;
  final int masteredAyahs;
  final int weakAyahs;
  final MemorizationStatus status;

  const SurahHeatmapItem({
    required this.surahNumber,
    required this.name,
    required this.arabicName,
    required this.juzNumber,
    required this.totalAyahs,
    required this.retentionScore,
    required this.testedAyahs,
    required this.masteredAyahs,
    required this.weakAyahs,
    required this.status,
  });

  SurahHeatmapItem copyWith({
    double? retentionScore,
    int? testedAyahs,
    int? masteredAyahs,
    int? weakAyahs,
    MemorizationStatus? status,
  }) {
    return SurahHeatmapItem(
      surahNumber: surahNumber,
      name: name,
      arabicName: arabicName,
      juzNumber: juzNumber,
      totalAyahs: totalAyahs,
      retentionScore: retentionScore ?? this.retentionScore,
      testedAyahs: testedAyahs ?? this.testedAyahs,
      masteredAyahs: masteredAyahs ?? this.masteredAyahs,
      weakAyahs: weakAyahs ?? this.weakAyahs,
      status: status ?? this.status,
    );
  }
}

