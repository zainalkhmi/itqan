import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/offline/services/audio_download_service.dart';

void main() {
  group('AudioDownloadService Tests', () {
    late AudioDownloadService service;
    late Directory tempDir;

    setUp(() async {
      service = AudioDownloadService();
      tempDir = await Directory.systemTemp.createTemp('audio_download_test_');
      service.setBaseDirForTesting(tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('getCdnUrl formats Quran.com CDN URLs correctly', () {
      expect(
        service.getCdnUrl(1, 1),
        equals('https://verses.quran.com/Alafasy/mp3/001001.mp3'),
      );
      expect(
        service.getCdnUrl(2, 255),
        equals('https://verses.quran.com/Alafasy/mp3/002255.mp3'),
      );
      expect(
        service.getCdnUrl(114, 6),
        equals('https://verses.quran.com/Alafasy/mp3/114006.mp3'),
      );
    });

    test('getLocalAudioPath constructs correct filesystem path', () {
      final path = service.getLocalAudioPath(1, 2);
      expect(path, isNotNull);
      expect(path!.replaceAll(r'\', '/'), contains('1_2.mp3'));
    });

    test('formatBytes handles zero, KB, MB, and GB boundaries', () {
      expect(AudioDownloadService.formatBytes(0), equals('0 B'));
      expect(AudioDownloadService.formatBytes(-5), equals('0 B'));
      expect(AudioDownloadService.formatBytes(500), equals('500.0 B'));
      expect(AudioDownloadService.formatBytes(1024), equals('1.0 KB'));
      expect(AudioDownloadService.formatBytes(1536), equals('1.5 KB'));
      expect(AudioDownloadService.formatBytes(1048576), equals('1.0 MB'));
      expect(AudioDownloadService.formatBytes(36700160), equals('35.0 MB'));
      expect(AudioDownloadService.formatBytes(1073741824), equals('1.0 GB'));
    });

    test('isAyahAudioDownloaded detects existing audio file with size > 1024', () async {
      final path = service.getLocalAudioPath(1, 1)!;
      final file = File(path);

      expect(service.isAyahAudioDownloaded(1, 1), isFalse);

      // Create file smaller than 1024 bytes -> should still report false
      await file.writeAsBytes(List.filled(500, 0));
      expect(service.isAyahAudioDownloaded(1, 1), isFalse);

      // Create valid audio file (> 1024 bytes)
      await file.writeAsBytes(List.filled(2048, 1));
      expect(service.isAyahAudioDownloaded(1, 1), isTrue);
    });

    test('getSurahDownloadedCount and isSurahAudioDownloaded reflect downloaded ayahs', () async {
      // Surah 1 has 7 ayahs
      expect(service.getSurahDownloadedCount(1), equals(0));
      expect(service.isSurahAudioDownloaded(1), isFalse);

      // Create 3 ayahs for Surah 1
      for (int i = 1; i <= 3; i++) {
        final f = File(service.getLocalAudioPath(1, i)!);
        await f.writeAsBytes(List.filled(2048, 1));
      }

      expect(service.getSurahDownloadedCount(1), equals(3));
      expect(service.isSurahAudioDownloaded(1), isFalse);

      // Create remaining 4 ayahs (total 7)
      for (int i = 4; i <= 7; i++) {
        final f = File(service.getLocalAudioPath(1, i)!);
        await f.writeAsBytes(List.filled(2048, 1));
      }

      expect(service.getSurahDownloadedCount(1), equals(7));
      expect(service.isSurahAudioDownloaded(1), isTrue);
    });

    test('deleteSurahAudio removes all downloaded ayahs for a surah', () async {
      for (int i = 1; i <= 3; i++) {
        final f = File(service.getLocalAudioPath(1, i)!);
        await f.writeAsBytes(List.filled(2048, 1));
      }
      expect(service.getSurahDownloadedCount(1), equals(3));

      await service.deleteSurahAudio(1);
      expect(service.getSurahDownloadedCount(1), equals(0));
    });

    test('getTotalAudioStorageBytes sums file sizes in audio directory', () async {
      final f1 = File(service.getLocalAudioPath(1, 1)!);
      final f2 = File(service.getLocalAudioPath(1, 2)!);
      await f1.writeAsBytes(List.filled(2000, 1));
      await f2.writeAsBytes(List.filled(3000, 1));

      final total = await service.getTotalAudioStorageBytes();
      expect(total, equals(5000));
    });
  });
}
