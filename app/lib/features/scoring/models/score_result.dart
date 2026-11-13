import 'package:flutter/material.dart';

class WordScore {
  final String word;
  final double score; // 0-1
  final String? error;
  final String? transcribedAs;

  const WordScore({
    required this.word,
    required this.score,
    this.error,
    this.transcribedAs,
  });
}

class ScoreResult {
  final double overall;
  final double wordAccuracy;
  final double letterAccuracy;
  final double tajweed;
  final double fluency;
  final List<WordScore> wordScores;
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
