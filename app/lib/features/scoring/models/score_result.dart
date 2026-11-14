import 'package:flutter/material.dart';

enum MistakeType {
  none,
  incorrect, // Mispronounced or wrong word (Red)
  missed,    // Skipped or omitted word (Orange)
  extra,     // Inserted extra word not in ayah (Pink/Coral)
  tajweed,   // Pronunciation/Makhraj/Madd issue (Amber)
}

class RecitationMistake {
  final String verseKey;
  final MistakeType type;
  final String title;
  final String expectedText;
  final String recitedText;
  final String highlightedWord;
  final int wordIndex;
  final String detail;
  final List<String> similarVerses;

  const RecitationMistake({
    required this.verseKey,
    required this.type,
    required this.title,
    required this.expectedText,
    this.recitedText = '',
    required this.highlightedWord,
    this.wordIndex = 0,
    this.detail = '',
    this.similarVerses = const [],
  });

  Color get color {
    switch (type) {
      case MistakeType.incorrect:
        return const Color(0xFFEF4444);
      case MistakeType.missed:
        return const Color(0xFFF97316);
      case MistakeType.extra:
        return const Color(0xFFEC4899);
      case MistakeType.tajweed:
        return const Color(0xFFFBBF24);
      case MistakeType.none:
        return const Color(0xFF10B981);
    }
  }
}

class WordScore {
  final String word;
  final double score; // 0-1
  final String? error;
  final String? transcribedAs;
  final MistakeType mistakeType;

  const WordScore({
    required this.word,
    required this.score,
    this.error,
    this.transcribedAs,
    this.mistakeType = MistakeType.none,
  });

  bool get isMistake =>
      mistakeType != MistakeType.none ||
      (error != null && error!.isNotEmpty) ||
      score < 0.70;

  Color get statusColor {
    switch (mistakeType) {
      case MistakeType.incorrect:
        return const Color(0xFFEF4444);
      case MistakeType.missed:
        return const Color(0xFFF97316);
      case MistakeType.extra:
        return const Color(0xFFEC4899);
      case MistakeType.tajweed:
        return const Color(0xFFFBBF24);
      case MistakeType.none:
        if (score >= 0.85) return const Color(0xFF10B981);
        if (score >= 0.65) return const Color(0xFFFBBF24);
        return const Color(0xFFEF4444);
    }
  }
}

class ScoreResult {
  final double overall;
  final double wordAccuracy;
  final double letterAccuracy;
  final double tajweed;
  final double fluency;
  final List<WordScore> wordScores;
  final List<RecitationMistake> mistakes;
  final int surahNumber;
  final int ayahNumber;
  final String? transcription;
  final String? aiModel;
  final String? hifzMode;
  final int peeksUsed;

  const ScoreResult({
    required this.overall,
    required this.wordAccuracy,
    required this.letterAccuracy,
    required this.tajweed,
    required this.fluency,
    required this.wordScores,
    this.mistakes = const [],
    required this.surahNumber,
    required this.ayahNumber,
    this.transcription,
    this.aiModel,
    this.hifzMode,
    this.peeksUsed = 0,
  });

  ScoreResult copyWith({
    double? overall,
    double? wordAccuracy,
    double? letterAccuracy,
    double? tajweed,
    double? fluency,
    List<WordScore>? wordScores,
    List<RecitationMistake>? mistakes,
    int? surahNumber,
    int? ayahNumber,
    String? transcription,
    String? aiModel,
    String? hifzMode,
    int? peeksUsed,
  }) {
    return ScoreResult(
      overall: overall ?? this.overall,
      wordAccuracy: wordAccuracy ?? this.wordAccuracy,
      letterAccuracy: letterAccuracy ?? this.letterAccuracy,
      tajweed: tajweed ?? this.tajweed,
      fluency: fluency ?? this.fluency,
      wordScores: wordScores ?? this.wordScores,
      mistakes: mistakes ?? this.mistakes,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      transcription: transcription ?? this.transcription,
      aiModel: aiModel ?? this.aiModel,
      hifzMode: hifzMode ?? this.hifzMode,
      peeksUsed: peeksUsed ?? this.peeksUsed,
    );
  }

  Color get color {
    if (overall >= 85) return const Color(0xFF34D399);
    if (overall >= 65) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  String get grade {
    if (overall >= 90) return 'Excellent';
    if (overall >= 80) return 'Very Good';
    if (overall >= 70) return 'Good';
    if (overall >= 60) return 'Fair';
    return 'Needs Practice';
  }
}
