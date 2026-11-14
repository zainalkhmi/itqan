import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/scoring/models/score_result.dart';

void main() {
  group('Mistake Detection Models & Color Coding', () {
    test('WordScore with mistakeType incorrect has correct color and isMistake true', () {
      const ws = WordScore(
        word: 'عذاب',
        score: 0.45,
        mistakeType: MistakeType.incorrect,
        error: 'Substituted letter',
      );

      expect(ws.isMistake, isTrue);
      expect(ws.statusColor, equals(const Color(0xFFEF4444))); // Red
    });

    test('WordScore with mistakeType missed has orange color and isMistake true', () {
      const ws = WordScore(
        word: 'وباليوم',
        score: 0.20,
        mistakeType: MistakeType.missed,
      );

      expect(ws.isMistake, isTrue);
      expect(ws.statusColor, equals(const Color(0xFFF97316))); // Orange
    });

    test('WordScore with high score has green correct color and isMistake false', () {
      const ws = WordScore(
        word: 'الله',
        score: 0.95,
        mistakeType: MistakeType.none,
      );

      expect(ws.isMistake, isFalse);
      expect(ws.statusColor, equals(const Color(0xFF10B981))); // Green
    });

    test('RecitationMistake holds expected and recited comparisons', () {
      const m = RecitationMistake(
        verseKey: '2:7',
        type: MistakeType.incorrect,
        title: 'Incorrect words',
        expectedText: 'غشاوة ولهم عذاب عظيم',
        recitedText: 'غشاوة ولهم عذاب اليم',
        highlightedWord: 'عظيم',
        detail: 'Replaced with alim',
      );

      expect(m.verseKey, equals('2:7'));
      expect(m.type, equals(MistakeType.incorrect));
      expect(m.title, equals('Incorrect words'));
      expect(m.color, equals(const Color(0xFFEF4444)));
      expect(m.expectedText, contains('عظيم'));
      expect(m.recitedText, contains('اليم'));
    });

    test('ScoreResult maintains mistakes list and copyWith updates properly', () {
      const mistake = RecitationMistake(
        verseKey: '2:8',
        type: MistakeType.missed,
        title: 'Missed words',
        expectedText: 'يقول آمنا بالله',
        highlightedWord: 'آمنا',
      );

      const result = ScoreResult(
        overall: 78.0,
        wordAccuracy: 75.0,
        letterAccuracy: 80.0,
        tajweed: 85.0,
        fluency: 80.0,
        wordScores: [],
        mistakes: [mistake],
        surahNumber: 2,
        ayahNumber: 8,
      );

      expect(result.mistakes.length, equals(1));
      expect(result.mistakes.first.title, equals('Missed words'));

      final updated = result.copyWith(overall: 82.0);
      expect(updated.overall, equals(82.0));
      expect(updated.mistakes.length, equals(1));
    });
  });
}

