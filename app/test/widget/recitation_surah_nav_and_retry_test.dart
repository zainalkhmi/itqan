import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/quran/models/ayah.dart';
import 'package:itqan/features/recitation/recitation_screen.dart';
import 'package:itqan/features/recitation/recitation_controller.dart';
import 'package:itqan/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('recitation_surah_retry_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('inference_config');
  });

  tearDownAll(() async {
    // Intentionally no-op to prevent Windows file lock hang during background test run
  });

  const testAyah = Ayah(
    surahNumber: 2,
    ayahNumber: 2,
    textUthmani: 'ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ فِيهِ هُدًى لِّلْمُتَّقِينَ',
    translation: 'This is the Book about which there is no doubt, a guidance for those conscious of Allah.',
    words: [
      Word(position: 1, textUthmani: 'ذَٰلِكَ', transliteration: 'dhalika'),
      Word(position: 2, textUthmani: 'ٱلْكِتَٰبُ', transliteration: 'al-kitabu'),
      Word(position: 3, textUthmani: 'لَا', transliteration: 'la'),
      Word(position: 4, textUthmani: 'رَيْبَ', transliteration: 'rayba'),
      Word(position: 5, textUthmani: 'فِيهِ', transliteration: 'feehi'),
      Word(position: 6, textUthmani: 'هُدًى', transliteration: 'hudan'),
      Word(position: 7, textUthmani: 'لِّلْمُتَّقِينَ', transliteration: 'lil-muttaqeen'),
    ],
  );

  Widget createWidget() {
    return const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: RecitationScreen(ayah: testAyah, surahName: 'Al-Baqarah'),
      ),
    );
  }

  group('Recitation Previous/Next Surah and Retry Action Tests', () {
    testWidgets('renders Previous Surah and Next Surah buttons above reciter controls', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Checks that Prev Surah and Next Surah icon buttons are visible
      expect(find.byIcon(Icons.skip_previous_rounded), findsWidgets);
      expect(find.byIcon(Icons.skip_next_rounded), findsWidgets);

      // Checks that Ayah navigation icon buttons are visible
      expect(find.byIcon(Icons.chevron_left_rounded), findsWidgets);
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);

      // Checks that the compact Surah & Ayah picker pill is visible
      expect(find.textContaining('Al-Baqarah'), findsWidgets);

      // Checks reciter controls (Listen, Record, Retry)
      expect(find.text('Listen First'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tapping Retry resets session smoothly and triggers feedback', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final retryFinder = find.widgetWithText(GestureDetector, 'Retry');
      expect(retryFinder, findsOneWidget);

      await tester.tap(retryFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Sesi di-reset. Siap mengulang bacaan ayat ini!'), findsOneWidget);
    });
  });
}
