import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/mushaf/models/mushaf_layout.dart';
import 'package:itqan/features/mushaf/services/mushaf_layout_service.dart';
import 'package:itqan/features/quran/services/quran_service.dart';
import 'package:itqan/features/quran/models/ayah.dart';

void main() {
  group('MushafLayoutService Tests (QUL 15-Line Mushaf Layout)', () {
    late MushafLayoutService layoutService;

    setUp(() {
      layoutService = MushafLayoutService();
    });

    test('Empty PageData returns guaranteed 15 lines', () {
      const pageData = PageData(
        pageNumber: 100,
        juzNumber: 5,
        hizbNumber: 10,
        verses: [],
      );

      final layout = layoutService.buildPageLayout(pageData);

      expect(layout.pageNumber, equals(100));
      expect(layout.lines.length, equals(15));
      for (int i = 0; i < 15; i++) {
        expect(layout.lines[i].lineNumber, equals(i + 1));
      }
    });

    test('Algorithmic layout distributes words and creates exactly 15 lines', () {
      final words1 = List.generate(
        10,
        (i) => PageWord(
          id: i + 1,
          position: i + 1,
          lineNumber: 1, // Default uncalibrated
          textUthmani: 'كلمة$i',
          transliteration: 'kalimah$i',
          translation: 'word$i',
        ),
      );

      final words2 = List.generate(
        15,
        (i) => PageWord(
          id: i + 11,
          position: i + 1,
          lineNumber: 1,
          textUthmani: 'كلمة${i + 10}',
          transliteration: 'kalimah${i + 10}',
          translation: 'word${i + 10}',
        ),
      );

      final verses = [
        VerseOnPage(
          verseKey: '2:10',
          surahNumber: 2,
          ayahNumber: 10,
          textUthmani: 'اية 10',
          juzNumber: 1,
          isFirstOfSurah: false,
          words: words1,
          translation: 'Verse 10',
        ),
        VerseOnPage(
          verseKey: '2:11',
          surahNumber: 2,
          ayahNumber: 11,
          textUthmani: 'اية 11',
          juzNumber: 1,
          isFirstOfSurah: false,
          words: words2,
          translation: 'Verse 11',
        ),
      ];

      final pageData = PageData(
        pageNumber: 3,
        juzNumber: 1,
        hizbNumber: 1,
        verses: verses,
      );

      final layout = layoutService.buildPageLayout(pageData);

      expect(layout.lines.length, equals(15));
      final totalWordsInLayout = layout.lines
          .where((l) => l.isAyah)
          .fold<int>(0, (sum, l) => sum + l.words.length);

      expect(totalWordsInLayout, equals(25));
    });

    test('Surah start on page inserts Header and Basmallah lines', () {
      final words = [
        const PageWord(
          id: 1,
          position: 1,
          lineNumber: 1,
          textUthmani: 'الْحَمْدُ',
          transliteration: 'al-hamdu',
          translation: 'All praise',
        ),
        const PageWord(
          id: 2,
          position: 2,
          lineNumber: 1,
          textUthmani: 'لِلَّهِ',
          transliteration: 'lillahi',
          translation: 'is due to Allah',
        ),
      ];

      final verses = [
        VerseOnPage(
          verseKey: '112:1',
          surahNumber: 112,
          ayahNumber: 1,
          textUthmani: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
          juzNumber: 30,
          isFirstOfSurah: true,
          words: words,
          translation: 'Say, He is Allah, [who is] One',
        ),
      ];

      final pageData = PageData(
        pageNumber: 604,
        juzNumber: 30,
        hizbNumber: 60,
        verses: verses,
      );

      final surahMap = {
        112: const Surah(
          number: 112,
          nameSimple: 'Al-Ikhlas',
          nameArabic: 'الإخلاص',
          nameTranslation: 'The Sincerity',
          revelationPlace: 'makkah',
          ayahCount: 4,
        ),
      };

      final layout = layoutService.buildPageLayout(pageData, surahMap: surahMap);

      expect(layout.lines.length, equals(15));
      expect(layout.lines[0].lineType, equals(LineType.surahHeader));
      expect(layout.lines[0].surahNumber, equals(112));
      expect(layout.lines[0].surahNameArabic, equals('الإخلاص'));

      expect(layout.lines[1].lineType, equals(LineType.basmallah));
      expect(layout.lines[1].isCentered, isTrue);

      expect(layout.lines[2].lineType, equals(LineType.ayahText));
    });

    test('Surah 9 (At-Tawbah) includes Header but excludes Basmallah', () {
      final words = [
        const PageWord(
          id: 1,
          position: 1,
          lineNumber: 1,
          textUthmani: 'بَرَاءَةٌ',
          transliteration: 'baraatun',
          translation: '[This is a declaration of] disassociation',
        ),
      ];

      final verses = [
        VerseOnPage(
          verseKey: '9:1',
          surahNumber: 9,
          ayahNumber: 1,
          textUthmani: 'بَرَاءَةٌ مِّنَ اللَّهِ',
          juzNumber: 10,
          isFirstOfSurah: true,
          words: words,
          translation: 'Declaration',
        ),
      ];

      final pageData = PageData(
        pageNumber: 187,
        juzNumber: 10,
        hizbNumber: 20,
        verses: verses,
      );

      final layout = layoutService.buildPageLayout(pageData);

      expect(layout.lines.length, equals(15));
      expect(layout.lines[0].lineType, equals(LineType.surahHeader));
      expect(layout.lines[0].surahNumber, equals(9));

      // Line 2 must be AyahText, NOT Basmallah!
      expect(layout.lines[1].lineType, equals(LineType.ayahText));
    });

    test('Explicit QUL lines mapping correctly maps lines 3 to 15', () {
      final words = [
        const PageWord(
          id: 1,
          position: 1,
          lineNumber: 3,
          textUthmani: 'الٓمٓ',
          transliteration: 'Alif Lam Meem',
          translation: 'Alif Lam Meem',
        ),
        const PageWord(
          id: 2,
          position: 1,
          lineNumber: 4,
          textUthmani: 'ذَٰلِكَ',
          transliteration: 'dhalika',
          translation: 'This',
        ),
      ];

      final verses = [
        VerseOnPage(
          verseKey: '2:1',
          surahNumber: 2,
          ayahNumber: 1,
          textUthmani: 'الٓمٓ',
          juzNumber: 1,
          isFirstOfSurah: true,
          words: [words[0]],
          translation: 'Alif Lam Meem',
        ),
        VerseOnPage(
          verseKey: '2:2',
          surahNumber: 2,
          ayahNumber: 2,
          textUthmani: 'ذَٰلِكَ الْكِتَابُ',
          juzNumber: 1,
          isFirstOfSurah: false,
          words: [words[1]],
          translation: 'This is the Book',
        ),
      ];

      final pageData = PageData(
        pageNumber: 2,
        juzNumber: 1,
        hizbNumber: 1,
        verses: verses,
      );

      final layout = layoutService.buildPageLayout(pageData);

      expect(layout.lines.length, equals(15));
      expect(layout.lines[0].lineType, equals(LineType.surahHeader));
      expect(layout.lines[1].lineType, equals(LineType.basmallah));
      expect(layout.lines[2].lineType, equals(LineType.ayahText));
      expect(layout.lines[2].words.first.textUthmani, equals('الٓمٓ'));
      expect(layout.lines[3].words.first.textUthmani, equals('ذَٰلِكَ'));
    });

    test('MushafWordItem fullAudioUrl builds valid CDN URL', () {
      const item1 = MushafWordItem(
        verseKey: '1:1',
        surahNumber: 1,
        ayahNumber: 1,
        textUthmani: 'بِسْمِ',
        audioUrl: 'wbw/001_001_001.mp3',
      );
      expect(item1.fullAudioUrl, equals('https://audio.qurancdn.com/wbw/001_001_001.mp3'));

      const item2 = MushafWordItem(
        verseKey: '1:1',
        surahNumber: 1,
        ayahNumber: 1,
        textUthmani: 'بِسْمِ',
        audioUrl: 'https://example.com/audio.mp3',
      );
      expect(item2.fullAudioUrl, equals('https://example.com/audio.mp3'));
    });

    test('Arabic numerals conversion formats correctly', () {
      expect(MushafLayoutService.toArabicNumerals(1), equals('١'));
      expect(MushafLayoutService.toArabicNumerals(15), equals('١٥'));
      expect(MushafLayoutService.toArabicNumerals(604), equals('٦٠٤'));
    });
  });
}
