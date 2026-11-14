import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/quran/data/quran_catalog.dart';

void main() {
  group('QuranCatalog Complete 114 Surahs Catalog', () {
    test('contains exactly 114 Surahs', () {
      expect(QuranCatalog.surahs.length, equals(114));
    });

    test('first surah is Al-Fatihah with 7 ayahs', () {
      final fatihah = QuranCatalog.getSurah(1);
      expect(fatihah.number, equals(1));
      expect(fatihah.nameSimple, equals('Al-Fatihah'));
      expect(fatihah.nameArabic, equals('الفاتحة'));
      expect(fatihah.ayahCount, equals(7));
      expect(QuranCatalog.getAyahCount(1), equals(7));
    });

    test('second surah is Al-Baqarah with 286 ayahs', () {
      final baqarah = QuranCatalog.getSurah(2);
      expect(baqarah.number, equals(2));
      expect(baqarah.nameSimple, equals('Al-Baqarah'));
      expect(baqarah.nameArabic, equals('البقرة'));
      expect(baqarah.ayahCount, equals(286));
      expect(QuranCatalog.getAyahCount(2), equals(286));
    });

    test('last surah is An-Nas with 6 ayahs', () {
      final nas = QuranCatalog.getSurah(114);
      expect(nas.number, equals(114));
      expect(nas.nameSimple, equals('An-Nas'));
      expect(nas.nameArabic, equals('الناس'));
      expect(nas.ayahCount, equals(6));
      expect(QuranCatalog.getAyahCount(114), equals(6));
    });

    test('surah numbers are strictly sequential from 1 to 114', () {
      for (int i = 0; i < 114; i++) {
        expect(QuranCatalog.surahs[i].number, equals(i + 1));
      }
    });

    test('search by exact number works', () {
      final res = QuranCatalog.search('36');
      expect(res.isNotEmpty, isTrue);
      expect(res.first.nameSimple, equals('Ya-Sin'));
    });

    test('search by name fragment works case-insensitively', () {
      final res = QuranCatalog.search('kahf');
      expect(res.isNotEmpty, isTrue);
      expect(res.any((s) => s.number == 18), isTrue);
    });

    test('search by Arabic text works', () {
      final res = QuranCatalog.search('الإخلاص');
      expect(res.isNotEmpty, isTrue);
      expect(res.first.number, equals(112));
    });
  });
}

