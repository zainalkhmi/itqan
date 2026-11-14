import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/recitation/widgets/surah_ayah_picker_sheet.dart';

void main() {
  group('SurahAyahPickerSheet Widget Tests', () {
    testWidgets('renders surah search, catalog items, and ayah chips', (tester) async {
      int? chosenSurah;
      int? chosenAyah;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurahAyahPickerSheet(
              initialSurahNumber: 1,
              initialAyahNumber: 1,
              onSelected: (s, a) {
                chosenSurah = s;
                chosenAyah = a;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and search input
      expect(find.text('Jump to Any Surah & Ayah'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify Al-Fatihah is rendered
      expect(find.text('Al-Fatihah'), findsWidgets);
      expect(find.text('الفاتحة'), findsWidgets);

      // Verify Ayah chips are present (1 through 7 for Al-Fatihah)
      expect(find.text('7'), findsWidgets);

      // Tap on Ayah 3
      await tester.tap(find.text('3').first);
      await tester.pumpAndSettle();

      expect(chosenSurah, equals(1));
      expect(chosenAyah, equals(3));
    });
  });
}

