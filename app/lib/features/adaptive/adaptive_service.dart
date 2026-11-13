import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../settings/settings_service.dart';

class DiagnosticAyah {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String textUthmani;
  final String focusArea;

  const DiagnosticAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.textUthmani,
    required this.focusArea,
  });
}

class AdaptiveService {
  /// 3 diagnostic ayahs covering common Tajweed, Makhraj, and Fluency challenges
  static const List<DiagnosticAyah> diagnosticAyahs = [
    DiagnosticAyah(
      surahNumber: 1,
      ayahNumber: 2,
      surahName: 'Al-Fatiha',
      textUthmani: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
      focusArea: 'Throat letters (Ḥā / ‘Ayn) & Madd ‘Āriḍ lis-Sukūn',
    ),
    DiagnosticAyah(
      surahNumber: 112,
      ayahNumber: 1,
      surahName: 'Al-Ikhlas',
      textUthmani: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
      focusArea: 'Deep palate (Qāf vs Kāf) & Qalqalah on Dāl',
    ),
    DiagnosticAyah(
      surahNumber: 114,
      ayahNumber: 1,
      surahName: 'An-Nas',
      textUthmani: 'قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ',
      focusArea: 'Dhāl interdental & Ghunnah on Nūn Musyaddadah',
    ),
  ];

  /// Evaluates diagnostic scores and determines the recommended proficiency level
  static String determineLevel(double averageScore) {
    if (averageScore >= 85.0) {
      return 'advanced';
    } else if (averageScore >= 70.0) {
      return 'intermediate';
    } else {
      return 'beginner';
    }
  }

  /// Calculates dynamic difficulty adjustment and adaptive tolerance based on rolling session history
  static Map<String, dynamic> analyzeDynamicDifficulty({
    required List<Map> sessions,
    required String currentLevel,
  }) {
    if (sessions.isEmpty) {
      return {
        'adaptiveLevel': currentLevel,
        'rollingAverage': 0.0,
        'toleranceOffset': 0.0,
        'recommendation': 'Take the diagnostic test or start practicing to calibrate difficulty.',
      };
    }

    // Take the last 5 sessions
    final recent = sessions.reversed.take(5).toList();
    final scores = recent.map((s) => (s['overall'] as num?)?.toDouble() ?? 75.0).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;

    String suggestedLevel = currentLevel;
    double tolerance = 0.0;
    String advice = 'Your practice difficulty is well-balanced.';

    if (avg >= 90.0 && recent.length >= 3) {
      if (currentLevel == 'beginner') {
        suggestedLevel = 'intermediate';
        advice = 'Impressive accuracy! Ready to advance to Intermediate level.';
      } else if (currentLevel == 'intermediate') {
        suggestedLevel = 'advanced';
        advice = 'Mastery demonstrated. Advanced strict Tajweed criteria recommended.';
      }
      tolerance = -3.0; // Stricter tolerance
    } else if (avg < 65.0 && recent.length >= 3) {
      tolerance = 5.0; // More forgiving tolerance
      advice = 'We will ease difficulty slightly to focus on core pronunciation foundation.';
    }

    return {
      'adaptiveLevel': suggestedLevel,
      'rollingAverage': double.parse(avg.toStringAsFixed(1)),
      'toleranceOffset': tolerance,
      'recommendation': advice,
    };
  }

  /// Applies the evaluated placement level to settings and persists in Hive
  static Future<void> applyPlacementLevel({
    required WidgetRef ref,
    required String newLevel,
    required double placementScore,
  }) async {
    final settings = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).update(
      settings.copyWith(
        level: newLevel,
        scoringDifficulty: newLevel,
      ),
    );

    // Save placement badge in settings box
    if (!Hive.isBoxOpen('settings')) {
      await Hive.openBox('settings');
    }
    final box = Hive.box('settings');
    await box.put('placement_test_completed', true);
    await box.put('placement_score', placementScore);
    await box.put('placement_date', DateTime.now().toIso8601String());
  }
}

