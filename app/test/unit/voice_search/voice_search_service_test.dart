import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/voice_search/models/voice_search_match.dart';
import 'package:itqan/features/voice_search/services/voice_search_service.dart';

void main() {
  late Directory tempDir;
  late VoiceSearchService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('voice_search_test_');
    Hive.init(tempDir.path);
    service = VoiceSearchService();
    await service.init();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VoiceSearchService Tests', () {
    test('searchOffline correctly matches Surah Al-Fatihah from query', () {
      final results = service.searchOffline('الحمد لله رب العالمين');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.surah, equals(1));
      expect(results.first.ayah, equals(2));
      expect(results.first.confidence, greaterThanOrEqualTo(80.0));
    });

    test('searchOffline correctly matches Al-Ikhlas from query', () {
      final results = service.searchOffline('قل هو الله احد');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.surah, equals(112));
      expect(results.first.ayah, equals(1));
      expect(results.first.confidence, greaterThanOrEqualTo(80.0));
    });

    test('identifyRecitation saves and retrieves search history', () async {
      await service.identifyRecitation(textQuery: 'قل هو الله احد');
      final history = service.getHistory();
      expect(history.isNotEmpty, isTrue);
      expect(history.first.surah, equals(112));
    });
  });
}
