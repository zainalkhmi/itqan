import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/learning/learning_data.dart';

void main() {
  group('LearningData Modules Verification', () {
    test('contains comprehensive tajweed rules', () {
      final rules = LearningData.tajweedRules;
      expect(rules.length, greaterThanOrEqualTo(5));
      final titles = rules.map((r) => r.title.toLowerCase()).toList();
      expect(titles.any((t) => t.contains('idgham')), isTrue);
      expect(titles.any((t) => t.contains('ikhfa')), isTrue);
      expect(titles.any((t) => t.contains('madd')), isTrue);
      expect(titles.any((t) => t.contains('qalqalah')), isTrue);
      expect(titles.any((t) => t.contains('ghunnah')), isTrue);
    });

    test('makhraj letters cover key articulation zones', () {
      final letters = LearningData.makhrajLetters;
      expect(letters.isNotEmpty, isTrue);
      final areas = letters.map((l) => l.articulationArea.toLowerCase()).toList();
      expect(areas.any((a) => a.contains('throat')), isTrue);
      expect(areas.any((a) => a.contains('tongue')), isTrue);
    });

    test('minimal pairs contain contrasting similar consonants', () {
      final pairs = LearningData.minimalPairs;
      expect(pairs.length, greaterThanOrEqualTo(6));
      // Sad vs Seen
      final sadSeen = pairs.firstWhere((p) => p.letterA == 'ص' && p.letterB == 'س');
      expect(sadSeen.wordA, contains('ص'));
      expect(sadSeen.wordB, contains('س'));
    });

    test('quiz questions are valid with correct answer indices', () {
      final quiz = LearningData.quizQuestions;
      expect(quiz.isNotEmpty, isTrue);
      for (final q in quiz) {
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(q.correctIndex, lessThan(q.options.length));
        expect(q.explanation.isNotEmpty, isTrue);
      }
    });
  });
}

