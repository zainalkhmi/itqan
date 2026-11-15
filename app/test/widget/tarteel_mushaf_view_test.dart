import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/mushaf/models/mushaf_layout.dart';
import 'package:itqan/features/mushaf/widgets/mushaf_tarteel_view.dart';
import 'package:itqan/features/quran/models/ayah.dart';

void main() {
  group('TarteelMushafView Widget Tests', () {
    late MushafPageLayout sampleLayout;
    final surahMap = {
      2: const Surah(
        number: 2,
        nameSimple: 'Al-Baqarah',
        nameArabic: 'البقرة',
        nameTranslation: 'The Cow',
        revelationPlace: 'madinah',
        ayahCount: 286,
      ),
    };

    setUp(() {
      final lines = <MushafLine>[
        const MushafLine(
          lineNumber: 1,
          lineType: LineType.surahHeader,
          isCentered: true,
          surahNumber: 2,
          surahNameArabic: 'البقرة',
          surahNameSimple: 'Al-Baqarah',
          revelationPlace: 'madinah',
          ayahCount: 286,
        ),
        const MushafLine(
          lineNumber: 2,
          lineType: LineType.basmallah,
          isCentered: true,
          surahNumber: 2,
        ),
        MushafLine(
          lineNumber: 3,
          lineType: LineType.ayahText,
          words: [
            const MushafWordItem(
              id: 1,
              position: 1,
              verseKey: '2:6',
              surahNumber: 2,
              ayahNumber: 6,
              textUthmani: 'إِنَّ',
              transliteration: 'inna',
              translation: 'Indeed',
            ),
            const MushafWordItem(
              id: 2,
              position: 2,
              verseKey: '2:6',
              surahNumber: 2,
              ayahNumber: 6,
              textUthmani: 'ٱلَّذِينَ',
              transliteration: 'alladhīna',
              translation: 'those who',
            ),
            const MushafWordItem(
              id: 3,
              position: 3,
              verseKey: '2:6',
              surahNumber: 2,
              ayahNumber: 6,
              textUthmani: 'كَفَرُوا۟',
              transliteration: 'kafarū',
              translation: 'disbelieved',
              isVerseEnd: true,
            ),
          ],
        ),
      ];

      sampleLayout = MushafPageLayout(
        pageNumber: 2,
        juzNumber: 1,
        hizbNumber: 1,
        edition: MushafEdition.madinah15Lines,
        lines: lines,
      );
    });

    testWidgets('TarteelMushafView renders large legible Arabic text and header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TarteelMushafView(
              layout: sampleLayout,
              surahMap: surahMap,
              fontSize: 26.0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Surah header and Basmallah
      expect(find.text('۞ سُورَةُ البقرة ۞'), findsOneWidget);
      expect(find.text('بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'), findsOneWidget);

      // Large legible Arabic words
      expect(find.text('إِنَّ'), findsOneWidget);
      expect(find.text('ٱلَّذِينَ'), findsOneWidget);
      expect(find.text('كَفَرُوا۟'), findsOneWidget);

      // Verify font size is 26.0
      final textWidget = tester.widget<Text>(find.text('إِنَّ'));
      expect(textWidget.style?.fontSize, 26.0);
    });

    testWidgets('TarteelMushafView renders mistake words in red and correct words in green', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TarteelMushafView(
              layout: sampleLayout,
              surahMap: surahMap,
              fontSize: 26.0,
              mistakeWordKeys: {'2:6:2'}, // 'ٱلَّذِينَ'
              correctWordKeys: {'2:6:1'}, // 'إِنَّ'
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final correctWord = tester.widget<Text>(find.text('إِنَّ'));
      expect(correctWord.style?.color, const Color(0xFF10B981)); // Green

      final mistakeWord = tester.widget<Text>(find.text('ٱلَّذِينَ'));
      expect(mistakeWord.style?.color, const Color(0xFFEF4444)); // Red
    });

    testWidgets('TarteelMushafView in Hifz mode masks words and reveals on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TarteelMushafView(
              layout: sampleLayout,
              surahMap: surahMap,
              isHifzMode: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All words masked as ····
      expect(find.text('····'), findsWidgets);

      // Tap on the first masked word to reveal it
      await tester.tap(find.text('····').first);
      await tester.pumpAndSettle();

      // Word 'إِنَّ' is revealed
      expect(find.text('إِنَّ'), findsOneWidget);
    });
  });
}
