import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/offline/services/offline_quran_service.dart';

void main() {
  group('OfflineQuranService Tests', () {
    late Directory tempDir;
    late OfflineQuranService service;

    setUp(() async {
      service = OfflineQuranService();
      tempDir = await Directory.systemTemp.createTemp('offline_quran_test_');
      Hive.init(tempDir.path);
      await Hive.openBox('quran_cache');
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('getBundledCoreAyahs returns complete Al-Fatihah data offline', () {
      final fatihah = OfflineQuranService.getBundledCoreAyahs(1);
      expect(fatihah, isNotNull);
      expect(fatihah!.length, equals(7));

      // Verse 1 Basmalah
      expect(fatihah[0].surahNumber, equals(1));
      expect(fatihah[0].ayahNumber, equals(1));
      expect(fatihah[0].textUthmani, contains('بِسْمِ ٱللَّهِ'));
      expect(fatihah[0].words.length, equals(4));
      expect(fatihah[0].words.first.transliteration, equals('bismi'));

      // Verse 7
      expect(fatihah[6].ayahNumber, equals(7));
      expect(fatihah[6].textUthmani, contains('ٱلضَّآلِّينَ'));
    });

    test('getBundledCoreAyahs returns Al-Ikhlas and An-Nas', () {
      final ikhlas = OfflineQuranService.getBundledCoreAyahs(112);
      expect(ikhlas, isNotNull);
      expect(ikhlas!.length, equals(4));
      expect(ikhlas[0].textUthmani, contains('قُلْ هُوَ ٱللَّهُ أَحَدٌ'));

      final nas = OfflineQuranService.getBundledCoreAyahs(114);
      expect(nas, isNotNull);
      expect(nas!.first.textUthmani, contains('قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ'));

      final unknown = OfflineQuranService.getBundledCoreAyahs(2);
      expect(unknown, isNull);
    });

    test('isQuranTextDownloaded and getOfflineSurahCount read Hive cache correctly', () async {
      final box = Hive.box('quran_cache');
      expect(await service.isQuranTextDownloaded(), isFalse);
      expect(await service.getOfflineSurahCount(), equals(0));

      // Simulate caching surah 1 and surah 112
      await box.put('ayahs_1', '[]');
      await box.put('ayahs_112', '[]');
      expect(await service.getOfflineSurahCount(), equals(2));

      await box.put('offline_quran_text_complete', true);
      expect(await service.isQuranTextDownloaded(), isTrue);
    });
  });
}

