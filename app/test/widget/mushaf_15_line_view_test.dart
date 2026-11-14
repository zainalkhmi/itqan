import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/mushaf/models/mushaf_layout.dart';
import 'package:itqan/features/mushaf/widgets/mushaf_15_line_view.dart';
import 'package:itqan/features/quran/models/ayah.dart';

void main() {
  group('Mushaf15LineView Widget Tests', () {
    late MushafPageLayout sampleLayout;
    final surahMap = {
      1: const Surah(
        number: 1,
        nameSimple: 'Al-Fatihah',
        nameArabic: 'الفاتحة',
        nameTranslation: 'The Opener',
        revelationPlace: 'makkah',
        ayahCount: 7,
      ),
    };

    setUp(() {
      final lines = <MushafLine>[
        const MushafLine(
          lineNumber: 1,
          lineType: LineType.surahHeader,
          isCentered: true,
          surahNumber: 1,
          surahNameArabic: 'الفاتحة',
          surahNameSimple: 'Al-Fatihah',
          revelationPlace: 'makkah',
          ayahCount: 7,
        ),
        const MushafLine(
          lineNumber: 2,
          lineType: LineType.basmallah,
          isCentered: true,
          surahNumber: 1,
        ),
      ];

      for (int i = 3; i <= 15; i++) {
        lines.add(MushafLine(
          lineNumber: i,
          lineType: LineType.ayahText,
          words: [
            MushafWordItem(
              id: i,
              position: 1,
              verseKey: '1:$i',
              surahNumber: 1,
              ayahNumber: i,
              textUthmani: 'كلمة$i',
              transliteration: 'kalimah$i',
              translation: 'word$i',
              isVerseEnd: true,
            ),
          ],
        ));
      }

      sampleLayout = MushafPageLayout(
        pageNumber: 1,
        juzNumber: 1,
        hizbNumber: 1,
        edition: MushafEdition.madinah15Lines,
        lines: lines,
      );
    });

    testWidgets('Mushaf15LineView renders 15 lines and page header/footer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              width: 400,
              child: Mushaf15LineView(
                layout: sampleLayout,
                surahMap: surahMap,
                isHifzMode: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Surah header and Basmallah rendered
      expect(find.text('۞ الفاتحة ۞'), findsOneWidget);
      expect(find.text('بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'), findsOneWidget);

      // Ayah words rendered
      expect(find.text('كلمة3'), findsOneWidget);
    });

    testWidgets('Hifz mode masks words and tapping peeks/unmasks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              width: 400,
              child: Mushaf15LineView(
                layout: sampleLayout,
                surahMap: surahMap,
                isHifzMode: true, // HIFZ MODE ENABLED
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Words should be masked with placeholder '····'
      expect(find.text('····'), findsWidgets);
      expect(find.text('كلمة3'), findsNothing);

      // Tap on the first masked word placeholder to peek/reveal
      await tester.tap(find.text('····').first);
      await tester.pumpAndSettle();

      // Word should now be unmasked
      expect(find.text('كلمة3'), findsOneWidget);
    });

    testWidgets('Tapping word in normal mode opens word sheet with meaning', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              width: 400,
              child: Mushaf15LineView(
                layout: sampleLayout,
                surahMap: surahMap,
                isHifzMode: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap word 'كلمة3'
      await tester.tap(find.text('كلمة3'));
      await tester.pumpAndSettle();

      // Modal bottom sheet should appear with word translation and Practice button
      expect(find.text('word3'), findsOneWidget);
      expect(find.text('kalimah3'), findsOneWidget);
      expect(find.text('Practice Ayah with AI'), findsOneWidget);
    });

    testWidgets('Tajweed enabled shows rule info and QPC V4 details in word sheet', (tester) async {
      final tajweedLines = <MushafLine>[
        const MushafLine(
          lineNumber: 1,
          lineType: LineType.ayahText,
          words: [
            MushafWordItem(
              id: 1,
              position: 1,
              verseKey: '1:1',
              surahNumber: 1,
              ayahNumber: 1,
              textUthmani: 'بِسْمِ',
              transliteration: 'bismi',
              translation: 'In the name',
              tajweedRule: 'ghunnah',
              qpcV4Glyph: 'ﱁ',
            ),
          ],
        ),
      ];

      final tajweedLayout = MushafPageLayout(
        pageNumber: 1,
        juzNumber: 1,
        hizbNumber: 1,
        edition: MushafEdition.madinah15Lines,
        lines: tajweedLines,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              width: 400,
              child: Mushaf15LineView(
                layout: tajweedLayout,
                surahMap: surahMap,
                isHifzMode: false,
                showTajweed: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap word 'بِسْمِ'
      await tester.tap(find.text('بِسْمِ'));
      await tester.pumpAndSettle();

      // Word sheet should contain Tajweed badge and QPC V4 script badge
      expect(find.textContaining('QPC V4 Script'), findsOneWidget);
      expect(find.textContaining('Ghunnah'), findsWidgets);
    });
  });
}
