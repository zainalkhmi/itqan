import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/scoring/models/score_result.dart';
import 'package:itqan/features/scoring/widgets/mistakes_sheet.dart';

void main() {
  group('MistakesSheet Widget Tests (Tarteel-Style Mistake Detection)', () {
    testWidgets('renders empty state when mistakes list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MistakesSheet(mistakes: []),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mistakes'), findsOneWidget);
      expect(find.text('No recitation mistakes detected!'), findsOneWidget);
    });

    testWidgets('renders mistake cards with Expected vs Recited comparisons', (tester) async {
      const sampleMistakes = [
        RecitationMistake(
          verseKey: '2:7',
          type: MistakeType.incorrect,
          title: 'Incorrect words',
          expectedText: 'غشاوة ولهم عذاب عظيم',
          recitedText: 'غشاوة ولهم عذاب اليم',
          highlightedWord: 'اليم',
        ),
        RecitationMistake(
          verseKey: '2:8',
          type: MistakeType.missed,
          title: 'Missed words',
          expectedText: 'يقول آمنا بالله وباليوم الاخر',
          highlightedWord: 'وباليوم الاخر',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MistakesSheet(mistakes: sampleMistakes),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header count
      expect(find.text('2 detected'), findsOneWidget);

      // Check verse badges
      expect(find.text('2:7'), findsOneWidget);
      expect(find.text('2:8'), findsOneWidget);

      // Check mistake titles
      expect(find.text('Incorrect words'), findsOneWidget);
      expect(find.text('Missed words'), findsOneWidget);

      // Check "See similar verses" buttons
      expect(find.text('See similar verses'), findsNWidgets(2));
    });
  });
}

