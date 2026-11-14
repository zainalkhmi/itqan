import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/offline/offline_download_screen.dart';
import 'package:itqan/features/offline/services/audio_download_service.dart';

void main() {
  group('OfflineDownloadScreen Widget Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('offline_screen_test_');
      Hive.init(tempDir.path);
      await Hive.openBox('quran_cache');
      AudioDownloadService().setBaseDirForTesting(tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('renders storage stats, batch buttons, search bar, and surah list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OfflineDownloadScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header and storage stats
      expect(find.text('Offline Quran & Audio'), findsOneWidget);
      expect(find.text('Offline Storage Used'), findsOneWidget);
      expect(find.text('Juz \'Amma Audio (~35MB)'), findsOneWidget);
      expect(find.text('All Quran Text (~2MB)'), findsOneWidget);

      // Verify Search bar and Filter chips
      expect(find.text('All (114)'), findsOneWidget);
      expect(find.text('Downloaded'), findsOneWidget);
      expect(find.text('Juz \'Amma (37)'), findsOneWidget);

      // Verify Surah list items are rendered
      expect(find.text('Al-Fatihah'), findsOneWidget);
      expect(find.textContaining('7 Ayahs'), findsOneWidget);
    });

    testWidgets('filtering by Juz Amma displays surahs 78 to 114', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OfflineDownloadScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Juz \'Amma (37)' chip
      await tester.tap(find.text('Juz \'Amma (37)'));
      await tester.pumpAndSettle();

      // Surah 1 should be filtered out
      expect(find.text('Al-Fatihah'), findsNothing);
      // Surah 78 An-Naba should be visible
      expect(find.text('An-Naba'), findsOneWidget);
    });

    testWidgets('search query filters surah list by name or number', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OfflineDownloadScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query 'Ikhlas'
      await tester.enterText(find.byType(TextField), 'Ikhlas');
      await tester.pumpAndSettle();

      expect(find.text('Al-Ikhlas'), findsOneWidget);
      expect(find.text('Al-Fatihah'), findsNothing);
    });
  });
}
