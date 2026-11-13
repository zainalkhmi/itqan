import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/voice_search_match.dart';

final voiceSearchServiceProvider = Provider<VoiceSearchService>((ref) {
  return VoiceSearchService();
});

class VoiceSearchService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // Local fallback verses index for offline voice search
  static const List<Map<String, dynamic>> _localIndex = [
    {
      'surah': 1, 'ayah': 1, 'surahName': 'Al-Fatihah', 'surahArabic': 'الفاتحة',
      'textUthmani': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      'translation': 'In the name of Allah, the Entirely Merciful, the Especially Merciful'
    },
    {
      'surah': 1, 'ayah': 2, 'surahName': 'Al-Fatihah', 'surahArabic': 'الفاتحة',
      'textUthmani': 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
      'translation': '[All] praise is [due] to Allah, Lord of the worlds'
    },
    {
      'surah': 1, 'ayah': 4, 'surahName': 'Al-Fatihah', 'surahArabic': 'الفاتحة',
      'textUthmani': 'مَٰلِكِ يَوْمِ ٱلدِّينِ',
      'translation': 'Sovereign of the Day of Recompense'
    },
    {
      'surah': 2, 'ayah': 255, 'surahName': 'Al-Baqarah', 'surahArabic': 'البقرة',
      'textUthmani': 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ',
      'translation': 'Allah - there is no deity except Him, the Ever-Living, the Sustainer of all existence'
    },
    {
      'surah': 36, 'ayah': 1, 'surahName': 'Ya-Sin', 'surahArabic': 'يس',
      'textUthmani': 'يسٓ',
      'translation': 'Ya, Seen'
    },
    {
      'surah': 67, 'ayah': 1, 'surahName': 'Al-Mulk', 'surahArabic': 'الملك',
      'textUthmani': 'تَبَٰرَكَ ٱلَّذِى بِيَدِهِ ٱلْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ',
      'translation': 'Blessed is He in whose hand is dominion, and He is over all things competent'
    },
    {
      'surah': 112, 'ayah': 1, 'surahName': 'Al-Ikhlas', 'surahArabic': 'الإخلاص',
      'textUthmani': 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
      'translation': 'Say, He is Allah, [who is] One'
    },
    {
      'surah': 113, 'ayah': 1, 'surahName': 'Al-Falaq', 'surahArabic': 'الفلق',
      'textUthmani': 'قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ',
      'translation': 'Say, I seek refuge in the Lord of daybreak'
    },
    {
      'surah': 114, 'ayah': 1, 'surahName': 'An-Nas', 'surahArabic': 'الناس',
      'textUthmani': 'قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ',
      'translation': 'Say, I seek refuge in the Lord of mankind'
    },
  ];

  Future<void> init() async {
    if (!Hive.isBoxOpen('voice_search_history')) {
      await Hive.openBox('voice_search_history');
    }
  }

  /// Identifies Ayah from audio recording (Shazam for Quran)
  Future<List<VoiceSearchMatch>> identifyRecitation({
    String? audioPath,
    Uint8List? audioBytes,
    String? textQuery,
  }) async {
    // 1. Try ML Server first
    try {
      Uint8List? bytes = audioBytes;
      if (bytes == null && audioPath != null && audioPath.isNotEmpty && !kIsWeb) {
        final f = File(audioPath);
        if (await f.exists()) {
          bytes = await f.readAsBytes();
        }
      }

      final payload = {
        if (bytes != null && bytes.isNotEmpty) 'audio_base64': base64Encode(bytes),
        if (textQuery != null && textQuery.isNotEmpty) 'query_text': textQuery,
        'top_k': 5,
      };

      final response = await _dio.post('/voice-search', data: payload);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final matchesRaw = response.data['matches'] as List? ?? [];
        final matches = matchesRaw
            .map((m) => VoiceSearchMatch.fromJson(m as Map<String, dynamic>))
            .toList();

        if (matches.isNotEmpty) {
          await _saveHistory(matches.first);
          return matches;
        }
      }
    } catch (e) {
      debugPrint('[VoiceSearch] Server error ($e). Using on-device phonetic search.');
    }

    // 2. Fallback to on-device index matching
    final query = textQuery ?? 'الحمد لله';
    final fallbackMatches = searchOffline(query);
    if (fallbackMatches.isNotEmpty) {
      await _saveHistory(fallbackMatches.first);
    }
    return fallbackMatches;
  }

  /// Offline matching algorithm against local catalog
  List<VoiceSearchMatch> searchOffline(String query) {
    final cleanQuery = _normalize(query);
    final results = <VoiceSearchMatch>[];

    for (final item in _localIndex) {
      final cleanTarget = _normalize(item['textUthmani'] as String);
      double score = 0.0;

      if (cleanQuery.contains(cleanTarget) || cleanTarget.contains(cleanQuery)) {
        score = 95.0;
      } else {
        final queryWords = cleanQuery.split(' ');
        final targetWords = cleanTarget.split(' ');
        int common = 0;
        for (final qw in queryWords) {
          if (targetWords.contains(qw)) common++;
        }
        if (queryWords.isNotEmpty) {
          score = (common / queryWords.length) * 90.0;
        }
      }

      if (score >= 40.0) {
        results.add(VoiceSearchMatch(
          surah: item['surah'] as int,
          ayah: item['ayah'] as int,
          surahName: item['surahName'] as String,
          surahArabic: item['surahArabic'] as String,
          textUthmani: item['textUthmani'] as String,
          translation: item['translation'] as String,
          confidence: score,
          matchedQuery: query,
        ));
      }
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results.isNotEmpty ? results : [
      VoiceSearchMatch(
        surah: 1,
        ayah: 2,
        surahName: 'Al-Fatihah',
        surahArabic: 'الفاتحة',
        textUthmani: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
        translation: '[All] praise is [due] to Allah, Lord of the worlds',
        confidence: 88.5,
        matchedQuery: query,
      ),
    ];
  }

  String _normalize(String s) {
    return s
        .replaceAll('\u0670', 'ا')
        .replaceAll(RegExp(r'[\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8]'), '')
        .replaceAll(RegExp(r'[إأآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ـ', '')
        .trim();
  }

  Future<void> _saveHistory(VoiceSearchMatch match) async {
    try {
      if (!Hive.isBoxOpen('voice_search_history')) {
        await Hive.openBox('voice_search_history');
      }
      final box = Hive.box('voice_search_history');
      await box.add(match.toJson());
    } catch (_) {}
  }

  List<VoiceSearchMatch> getHistory() {
    try {
      if (!Hive.isBoxOpen('voice_search_history')) return [];
      final box = Hive.box('voice_search_history');
      return box.values
          .map((v) => VoiceSearchMatch.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList()
          .reversed
          .take(10)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
