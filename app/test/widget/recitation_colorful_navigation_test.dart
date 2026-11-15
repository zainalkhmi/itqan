import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/quran/models/ayah.dart';
import 'package:itqan/features/recitation/recitation_screen.dart';
import 'package:itqan/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('recitation_colorful_nav_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('inference_config');
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  const testAyah = Ayah(
    surahNumber: 1,
    ayahNumber: 1,
    textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
    translation: 'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
    words: [
      Word(position: 1, textUthmani: 'بِسْمِ', transliteration: 'bismi'),
      Word(position: 2, textUthmani: 'ٱللَّهِ', transliteration: 'llahi'),
      Word(position: 3, textUthmani: 'ٱلرَّحْمَٰنِ', transliteration: 'r-rahmani'),
      Word(position: 4, textUthmani: 'ٱلرَّحِيمِ', transliteration: 'r-rahim'),
    ],
  );

  testWidgets('RecitationScreen displays colorful Previous and Next ayah navigation buttons above recitation button', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: RecitationScreen(ayah: testAyah, surahName: 'Al-Fatihah'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check Previous button exists
    expect(find.text('Previous'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

    // Check Next button exists
    expect(find.text('Next'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    // Check center Ayah selector pill exists
    expect(find.textContaining('Ayah 1'), findsWidgets);
    expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);

    // Verify Previous is above the Listen First / Record row
    final prevPosition = tester.getCenter(find.text('Previous'));
    final listenPosition = tester.getCenter(find.text('Listen First'));
    expect(prevPosition.dy, lessThan(listenPosition.dy));
  });
}
