import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/heatmap/models/surah_heatmap_item.dart';
import 'package:itqan/features/heatmap/services/heatmap_service.dart';

void main() {
  late Directory tempDir;
  late HeatmapService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('heatmap_test_');
    Hive.init(tempDir.path);
    service = HeatmapService();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HeatmapService Tests', () {
    test('getHeatmapItems returns all 114 Surahs with metadata', () async {
      final items = await service.getHeatmapItems();
      expect(items.length, equals(114));
      expect(items.first.surahNumber, equals(1));
      expect(items.first.name, equals('Al-Fatihah'));
      expect(items.last.surahNumber, equals(114));
      expect(items.last.name, equals('An-Nas'));
    });

    test('getHeatmapItems covers Juz 30 (Juz Amma) accurately', () async {
      final items = await service.getHeatmapItems();
      final juzAmma = items.where((s) => s.juzNumber == 30).toList();
      expect(juzAmma.length, equals(37)); // Surahs 78 - 114
      expect(juzAmma.first.surahNumber, equals(78));
      expect(juzAmma.last.surahNumber, equals(114));
    });

    test('computeStats correctly aggregates Quran completion', () async {
      final items = await service.getHeatmapItems();
      final stats = service.computeStats(items);
      expect(stats['totalQuranAyahs'], equals(6236));
      expect(stats['progressPct'], isNotNull);
      expect(stats['totalMastered'], isNonNegative);
    });
  });
}

