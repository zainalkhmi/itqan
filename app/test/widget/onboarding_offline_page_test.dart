import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/onboarding/onboarding_screen.dart';
import 'package:itqan/features/settings/settings_service.dart';
import 'package:itqan/features/offline/services/audio_download_service.dart';

void main() {
  group('Onboarding Offline Pack Page Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('onboarding_offline_test_');
      Hive.init(tempDir.path);
      await Hive.openBox('settings');
      await Hive.openBox('quran_cache');
      AudioDownloadService().setBaseDirForTesting(tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('onboarding 4-page flow reaches offline pack download step', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Page 0: Welcome page
      expect(find.text('Itqan'), findsOneWidget);
      // Tap arrow icon to go to Level page
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pumpAndSettle();

      // Page 1: Level page
      expect(find.text('Beginner'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Page 2: Goal page
      expect(find.text('20 min'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 3: Offline pack page
      expect(find.text('Unduh Paket Offline'), findsOneWidget);
      expect(find.textContaining('Audio Juz \'Amma'), findsOneWidget);
      expect(find.text('Unduh Sekarang (~35MB)'), findsOneWidget);
      expect(find.text('Unduh Nanti di Pengaturan'), findsOneWidget);
    });
  });
}
