class VoiceSearchMatch {
  final int surah;
  final int ayah;
  final String surahName;
  final String surahArabic;
  final String textUthmani;
  final String translation;
  final double confidence;
  final String? matchedQuery;

  const VoiceSearchMatch({
    required this.surah,
    required this.ayah,
    required this.surahName,
    required this.surahArabic,
    required this.textUthmani,
    required this.translation,
    required this.confidence,
    this.matchedQuery,
  });

  factory VoiceSearchMatch.fromJson(Map<String, dynamic> json) {
    return VoiceSearchMatch(
      surah: json['surah'] as int? ?? 1,
      ayah: json['ayah'] as int? ?? 1,
      surahName: json['surahName'] as String? ?? 'Surah',
      surahArabic: json['surahArabic'] as String? ?? '',
      textUthmani: json['textUthmani'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 80.0,
      matchedQuery: json['matchedQuery'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'surah': surah,
    'ayah': ayah,
    'surahName': surahName,
    'surahArabic': surahArabic,
    'textUthmani': textUthmani,
    'translation': translation,
    'confidence': confidence,
    'matchedQuery': matchedQuery,
  };
}
