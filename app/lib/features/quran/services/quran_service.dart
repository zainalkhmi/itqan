import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/ayah.dart';

// ─── Page Data Models ────────────────────────────────────────────────────────

class PageWord {
  final int id;
  final int position;
  final int lineNumber;
  final String charTypeName;
  final String audioUrl;
  final String textUthmani;
  final String transliteration;
  final String translation;
  final String verseKey;

  const PageWord({
    this.id = 0,
    this.position = 0,
    this.lineNumber = 1,
    this.charTypeName = 'word',
    this.audioUrl = '',
    required this.textUthmani,
    required this.transliteration,
    required this.translation,
    this.verseKey = '',
  });

  bool get isVerseEnd => charTypeName == 'end';

  factory PageWord.fromJson(Map<String, dynamic> json, {String verseKey = ''}) {
    return PageWord(
      id: json['id'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
      lineNumber: json['line_number'] as int? ?? 1,
      charTypeName: json['char_type_name'] as String? ?? 'word',
      audioUrl: json['audio_url'] as String? ?? '',
      textUthmani: json['text_uthmani'] as String? ?? json['text'] as String? ?? '',
      transliteration: json['transliteration']?['text'] as String? ?? '',
      translation: json['translation']?['text'] as String? ?? '',
      verseKey: verseKey,
    );
  }
}

class VerseOnPage {
  final String verseKey;
  final int surahNumber;
  final int ayahNumber;
  final String textUthmani;
  final int juzNumber;
  final bool isFirstOfSurah;
  final List<PageWord> words;
  final String translation;

  const VerseOnPage({
    required this.verseKey,
    required this.surahNumber,
    required this.ayahNumber,
    required this.textUthmani,
    required this.juzNumber,
    required this.isFirstOfSurah,
    required this.words,
    required this.translation,
  });
}

class PageData {
  final int pageNumber;
  final int juzNumber;
  final int hizbNumber;
  final List<VerseOnPage> verses;

  const PageData({
    required this.pageNumber,
    required this.juzNumber,
    required this.hizbNumber,
    required this.verses,
  });
}

// ─── QuranService ─────────────────────────────────────────────────────────────

class QuranService {
  static const String _baseUrl = 'https://api.quran.com/api/v4';
  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  late Box _cacheBox;

  Future<void> init() async {
    _cacheBox = await Hive.openBox('quran_cache');
  }

  Future<List<Surah>> getSurahs() async {
    const cacheKey = 'surahs';
    final cached = _cacheBox.get(cacheKey);
    if (cached != null) {
      final List<dynamic> list = jsonDecode(cached as String);
      return list.map((j) => Surah.fromJson(j as Map<String, dynamic>)).toList();
    }

    final response = await _dio.get('/chapters?language=en');
    final chapters = response.data['chapters'] as List<dynamic>;
    final surahs = chapters.map((j) => Surah.fromJson(j as Map<String, dynamic>)).toList();

    await _cacheBox.put(cacheKey, jsonEncode(chapters));
    return surahs;
  }

  Future<List<Ayah>> getAyahs(int surahNumber) async {
    final cacheKey = 'ayahs_$surahNumber';
    final cached = _cacheBox.get(cacheKey);
    if (cached != null) {
      final List<dynamic> list = jsonDecode(cached as String);
      return list.map((j) => Ayah.fromJson(j as Map<String, dynamic>, surahNumber: surahNumber)).toList();
    }

    final response = await _dio.get(
      '/verses/by_chapter/$surahNumber',
      queryParameters: {
        'words': 'true',
        'translations': '131',
        'word_fields': 'text_uthmani,transliteration',
        'per_page': '300',
      },
    );

    final verses = response.data['verses'] as List<dynamic>;
    final ayahs = verses.map((j) => Ayah.fromJson(j as Map<String, dynamic>, surahNumber: surahNumber)).toList();

    await _cacheBox.put(cacheKey, jsonEncode(verses));
    return ayahs;
  }

  Future<PageData> getPage(int pageNumber) async {
    final cacheKey = 'page_$pageNumber';
    final cached = _cacheBox.get(cacheKey);

    List<dynamic> verses;
    if (cached != null) {
      verses = jsonDecode(cached as String) as List<dynamic>;
    } else {
      final response = await _dio.get(
        '/verses/by_page/$pageNumber',
        queryParameters: {
          'words': 'true',
          'translations': '131',
          'word_fields': 'text_uthmani,transliteration,translation,line_number,position,audio_url,char_type_name',
          'fields': 'text_uthmani,verse_key,page_number,juz_number,hizb_number',
          'per_page': '50',
        },
      );
      verses = response.data['verses'] as List<dynamic>;
      await _cacheBox.put(cacheKey, jsonEncode(verses));
    }

    if (verses.isEmpty) {
      return PageData(pageNumber: pageNumber, juzNumber: 0, hizbNumber: 0, verses: []);
    }

    int juzNumber = 0;
    int hizbNumber = 0;
    int? prevSurah;
    final verseList = <VerseOnPage>[];

    for (final v in verses) {
      final vMap = v as Map<String, dynamic>;
      final verseKey = vMap['verse_key'] as String? ?? '';
      final parts = verseKey.split(':');
      final surahNum = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final ayahNum = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

      juzNumber = vMap['juz_number'] as int? ?? juzNumber;
      hizbNumber = vMap['hizb_number'] as int? ?? hizbNumber;

      final words = (vMap['words'] as List<dynamic>? ?? [])
          .map((w) => PageWord.fromJson(w as Map<String, dynamic>, verseKey: verseKey))
          .toList();

      String translation = '';
      final translations = vMap['translations'] as List<dynamic>?;
      if (translations != null && translations.isNotEmpty) {
        translation = translations.first['text'] as String? ?? '';
        translation = translation.replaceAll(RegExp(r'<[^>]*>'), '');
      }

      verseList.add(VerseOnPage(
        verseKey: verseKey,
        surahNumber: surahNum,
        ayahNumber: ayahNum,
        textUthmani: vMap['text_uthmani'] as String? ?? '',
        juzNumber: juzNumber,
        isFirstOfSurah: prevSurah == null || surahNum != prevSurah,
        words: words,
        translation: translation,
      ));
      prevSurah = surahNum;
    }

    return PageData(
      pageNumber: pageNumber,
      juzNumber: juzNumber,
      hizbNumber: hizbNumber,
      verses: verseList,
    );
  }
}
