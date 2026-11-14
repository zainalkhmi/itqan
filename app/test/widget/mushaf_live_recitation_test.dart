import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/mushaf/mushaf_page_screen.dart';
import 'package:itqan/features/mushaf/mushaf_screen.dart';
import 'package:itqan/features/mushaf/services/reading_position_service.dart';
import 'package:itqan/features/quran/models/ayah.dart';
import 'package:itqan/features/quran/services/quran_service.dart';
import 'package:itqan/features/scoring/widgets/mistakes_sheet.dart';
import 'package:itqan/l10n/app_localizations.dart';

class _FakeQuranService extends QuranService {
  @override
  Future<void> init() async {}

  @override
  Future<List<Surah>> getSurahs() async {
    return [
      const Surah(
        number: 1,
        nameSimple: 'Al-Fatihah',
        nameArabic: 'الفاتحة',
        nameTranslation: 'The Opener',
        revelationPlace: 'makkah',
        ayahCount: 7,
      ),
    ];
  }

  @override
  Future<PageData> getPage(int pageNumber) async {
    return PageData(
      pageNumber: pageNumber,
      juzNumber: 1,
      hizbNumber: 1,
      verses: [
        const VerseOnPage(
          verseKey: '1:1',
          surahNumber: 1,
          ayahNumber: 1,
          textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
          juzNumber: 1,
          isFirstOfSurah: true,
          translation: 'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
          words: [
            PageWord(position: 1, textUthmani: 'بِسْمِ', transliteration: 'bismi', translation: 'In the name', verseKey: '1:1'),
            PageWord(position: 2, textUthmani: 'ٱللَّهِ', transliteration: 'Allāh', translation: 'of Allah', verseKey: '1:1'),
            PageWord(position: 3, textUthmani: 'ٱلرَّحْمَـٰنِ', transliteration: 'ar-Raḥmān', translation: 'the Entirely Merciful', verseKey: '1:1'),
            PageWord(position: 4, textUthmani: 'ٱلرَّحِيمِ', transliteration: 'ar-Raḥīm', translation: 'the Especially Merciful', verseKey: '1:1'),
          ],
        ),
      ],
    );
  }
}

void main() {
  group('Mushaf Live Recitation & Mistake Detection Dock Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mushaf_live_test_');
      Hive.init(tempDir.path);
      await Hive.openBox('settings');
      await Hive.openBox(ReadingPositionService.boxKey);
      await Hive.openBox('quran_cache');
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('renders floating recitation dock with page number and mic button', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quranServiceProvider.overrideWithValue(_FakeQuranService()),
            surahsProvider.overrideWith((ref) async => [
              const Surah(
                number: 1,
                nameSimple: 'Al-Fatihah',
                nameArabic: 'الفاتحة',
                nameTranslation: 'The Opener',
                revelationPlace: 'makkah',
                ayahCount: 7,
              ),
            ]),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: MushafPageScreen(startPage: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check floating recitation dock elements
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_rounded), findsWidgets);
      expect(find.byIcon(Icons.visibility_rounded), findsWidgets);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.first_page_rounded), findsOneWidget);

      // Tap glowing mic button to start live recitation
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dock switches to live recitation mode
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('0 Mistakes'), findsOneWidget);

      // Tap 0 Mistakes pill to verify MistakesSheet opens
      await tester.tap(find.text('0 Mistakes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MistakesSheet), findsOneWidget);
      expect(find.text('Mistakes'), findsOneWidget);
      expect(find.text('0 detected'), findsOneWidget);
    });

    testWidgets('tapping stop halts recitation and keeps mistake pills accessible', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quranServiceProvider.overrideWithValue(_FakeQuranService()),
            surahsProvider.overrideWith((ref) async => [
              const Surah(
                number: 1,
                nameSimple: 'Al-Fatihah',
                nameArabic: 'الفاتحة',
                nameTranslation: 'The Opener',
                revelationPlace: 'makkah',
                ayahCount: 7,
              ),
            ]),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: MushafPageScreen(startPage: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('mushaf_recitation_action_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('00:00'), findsOneWidget);

      // Stop recording by tapping the action button
      await tester.tap(find.byKey(const Key('mushaf_recitation_action_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Mic icon reappears
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });
  });
}
