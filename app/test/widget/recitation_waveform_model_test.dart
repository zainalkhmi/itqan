import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/quran/models/ayah.dart';
import 'package:itqan/features/recitation/recitation_screen.dart';
import 'package:itqan/features/recitation/widgets/waveform_visualizer.dart';
import 'package:itqan/features/scoring/services/inference_config_service.dart';
import 'package:itqan/l10n/app_localizations.dart';

class _FakeInferenceConfigNotifier extends InferenceConfigNotifier {
  _FakeInferenceConfigNotifier(InferenceMode mode) : super() {
    state = mode;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('recitation_waveform_model_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('inference_config');
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

  Widget createWidget(InferenceMode mode) {
    return ProviderScope(
      overrides: [
        inferenceConfigProvider.overrideWith((ref) => _FakeInferenceConfigNotifier(mode)),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: RecitationScreen(ayah: testAyah, surahName: 'Al-Fatihah'),
      ),
    );
  }

  group('Recitation Waveform Model Name Tests', () {
    testWidgets('shows TajweedFormer V4 above waveform when tajweedFormer mode selected in settings', (tester) async {
      await tester.pumpWidget(createWidget(InferenceMode.tajweedFormer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('TajweedFormer V4'), findsAtLeastNWidgets(1));
      expect(find.byType(WaveformVisualizer), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('shows Whisper AI above waveform when mlServer mode selected in settings', (tester) async {
      await tester.pumpWidget(createWidget(InferenceMode.mlServer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Whisper AI'), findsAtLeastNWidgets(1));
      expect(find.byType(WaveformVisualizer), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('shows On-Device INT8 ONNX above waveform when onDevice mode selected in settings', (tester) async {
      await tester.pumpWidget(createWidget(InferenceMode.onDevice));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('On-Device INT8 ONNX'), findsAtLeastNWidgets(1));
      expect(find.byType(WaveformVisualizer), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('shows Acoustic Engine above waveform when acoustic mode selected in settings', (tester) async {
      await tester.pumpWidget(createWidget(InferenceMode.acoustic));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Acoustic Engine'), findsAtLeastNWidgets(1));
      expect(find.byType(WaveformVisualizer), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('shows Auto (TajweedFormer V4) above waveform when auto mode selected in settings', (tester) async {
      await tester.pumpWidget(createWidget(InferenceMode.auto));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Auto (TajweedFormer V4)'), findsAtLeastNWidgets(1));
      expect(find.byType(WaveformVisualizer), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
