import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../quran/data/quran_catalog.dart';
import '../../quran/models/ayah.dart';
import '../../quran/services/quran_service.dart';

/// Service managing offline Quran text downloads, caching and offline fallback data
class OfflineQuranService {
  static final OfflineQuranService _instance = OfflineQuranService._internal();
  factory OfflineQuranService() => _instance;
  OfflineQuranService._internal();

  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  Future<bool> isQuranTextDownloaded() async {
    try {
      final box = Hive.isBoxOpen('quran_cache')
          ? Hive.box('quran_cache')
          : await Hive.openBox('quran_cache');
      return box.get('offline_quran_text_complete', defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  Future<int> getOfflineSurahCount() async {
    try {
      final box = Hive.isBoxOpen('quran_cache')
          ? Hive.box('quran_cache')
          : await Hive.openBox('quran_cache');
      int count = 0;
      for (int i = 1; i <= 114; i++) {
        if (box.containsKey('ayahs_$i')) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Downloads text and word alignments for all 114 surahs into Hive local cache
  Future<bool> downloadAllQuranText({
    Function(int completed, int total, double progress)? onProgress,
  }) async {
    if (_isDownloading) return false;
    _isDownloading = true;
    _downloadProgress = 0.0;

    final qService = QuranService();
    await qService.init();

    int completed = 0;
    const total = 114;

    try {
      for (int s = 1; s <= total; s++) {
        if (!_isDownloading) break; // Cancelled

        try {
          await qService.getAyahs(s);
          completed++;
        } catch (e) {
          debugPrint('[OfflineQuranService] Failed caching surah $s: $e');
        }

        _downloadProgress = completed / total;
        onProgress?.call(completed, total, _downloadProgress);
      }

      final box = Hive.box('quran_cache');
      await box.put('offline_quran_text_complete', completed >= 110);
      _isDownloading = false;
      return completed >= 110;
    } catch (e) {
      _isDownloading = false;
      debugPrint('[OfflineQuranService] Error during batch download: $e');
      return false;
    }
  }

  void cancelDownload() {
    _isDownloading = false;
  }

  /// Pre-seeded offline fallback ayahs for essential surahs when totally offline
  static List<Ayah>? getBundledCoreAyahs(int surahNumber) {
    switch (surahNumber) {
      case 1:
        return const [
          Ayah(
            surahNumber: 1,
            ayahNumber: 1,
            textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
            translation: 'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
            words: [
              Word(position: 1, textUthmani: 'بِسْمِ', transliteration: 'bismi'),
              Word(position: 2, textUthmani: 'ٱللَّهِ', transliteration: 'l-lahi'),
              Word(position: 3, textUthmani: 'ٱلرَّحْمَـٰنِ', transliteration: 'r-rahmani'),
              Word(position: 4, textUthmani: 'ٱلرَّحِيمِ', transliteration: 'r-rahim'),
            ],
          ),
          Ayah(
            surahNumber: 1,
            ayahNumber: 2,
            textUthmani: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
            translation: '[All] praise is [due] to Allah, Lord of the worlds.',
            words: [
              Word(position: 1, textUthmani: 'ٱلْحَمْدُ', transliteration: 'al-hamdu'),
              Word(position: 2, textUthmani: 'لِلَّهِ', transliteration: 'lillahi'),
              Word(position: 3, textUthmani: 'رَبِّ', transliteration: 'rabbi'),
              Word(position: 4, textUthmani: 'ٱلْعَـٰلَمِينَ', transliteration: 'al-alamin'),
            ],
          ),
          Ayah(
            surahNumber: 1,
            ayahNumber: 3,
            textUthmani: 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
            translation: 'The Entirely Merciful, the Especially Merciful.',
            words: [
              Word(position: 1, textUthmani: 'ٱلرَّحْمَـٰنِ', transliteration: 'ar-rahmani'),
              Word(position: 2, textUthmani: 'ٱلرَّحِيمِ', transliteration: 'ar-rahim'),
            ],
          ),
          Ayah(
            surahNumber: 1,
            ayahNumber: 4,
            textUthmani: 'مَـٰلِكِ يَوْمِ ٱلدِّينِ',
            translation: 'Sovereign of the Day of Recompense.',
            words: [
              Word(position: 1, textUthmani: 'مَـٰلِكِ', transliteration: 'maliki'),
              Word(position: 2, textUthmani: 'يَوْمِ', transliteration: 'yawmi'),
              Word(position: 3, textUthmani: 'ٱلدِّينِ', transliteration: 'ad-din'),
            ],
          ),
          Ayah(
            surahNumber: 1,
            ayahNumber: 5,
            textUthmani: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
            translation: 'It is You we worship and You we ask for help.',
            words: [
              Word(position: 1, textUthmani: 'إِيَّاكَ', transliteration: 'iyyaka'),
              Word(position: 2, textUthmani: 'نَعْبُدُ', transliteration: 'na\'budu'),
              Word(position: 3, textUthmani: 'وَإِيَّاكَ', transliteration: 'wa-iyyaka'),
              Word(position: 4, textUthmani: 'نَسْتَعِينُ', transliteration: 'nasta\'in'),
            ],
          ),
          Ayah(
            surahNumber: 1,
            ayahNumber: 6,
            textUthmani: 'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ',
            translation: 'Guide us to the straight path.',
            words: [
              Word(position: 1, textUthmani: 'ٱهْدِنَا', transliteration: 'ihdina'),
              Word(position: 2, textUthmani: 'ٱلصِّرَٰطَ', transliteration: 'as-sirata'),
              Word(position: 3, textUthmani: 'ٱلْمُسْتَقِيمَ', transliteration: 'al-mustaqim'),
            ],
          ),
          Ayah(
            surahNumber: 1,
            ayahNumber: 7,
            textUthmani: 'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ',
            translation: 'The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray.',
            words: [
              Word(position: 1, textUthmani: 'صِرَٰطَ', transliteration: 'sirata'),
              Word(position: 2, textUthmani: 'ٱلَّذِينَ', transliteration: 'alladhina'),
              Word(position: 3, textUthmani: 'أَنْعَمْتَ', transliteration: 'an\'amta'),
              Word(position: 4, textUthmani: 'عَلَيْهِمْ', transliteration: '\'alayhim'),
              Word(position: 5, textUthmani: 'غَيْرِ', transliteration: 'ghayri'),
              Word(position: 6, textUthmani: 'ٱلْمَغْضُوبِ', transliteration: 'al-maghdubi'),
              Word(position: 7, textUthmani: 'عَلَيْهِمْ', transliteration: '\'alayhim'),
              Word(position: 8, textUthmani: 'وَلَا', transliteration: 'wa-la'),
              Word(position: 9, textUthmani: 'ٱلضَّآلِّينَ', transliteration: 'ad-dallin'),
            ],
          ),
        ];

      case 112:
        return const [
          Ayah(
            surahNumber: 112,
            ayahNumber: 1,
            textUthmani: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
            translation: 'Say, "He is Allah, [who is] One."',
            words: [
              Word(position: 1, textUthmani: 'قُلْ', transliteration: 'qul'),
              Word(position: 2, textUthmani: 'هُوَ', transliteration: 'huwa'),
              Word(position: 3, textUthmani: 'ٱللَّهُ', transliteration: 'l-lahu'),
              Word(position: 4, textUthmani: 'أَحَدٌ', transliteration: 'ahad'),
            ],
          ),
          Ayah(
            surahNumber: 112,
            ayahNumber: 2,
            textUthmani: 'ٱللَّهُ ٱلصَّمَدُ',
            translation: 'Allah, the Eternal Refuge.',
            words: [
              Word(position: 1, textUthmani: 'ٱللَّهُ', transliteration: 'l-lahu'),
              Word(position: 2, textUthmani: 'ٱلصَّمَدُ', transliteration: 'as-samad'),
            ],
          ),
          Ayah(
            surahNumber: 112,
            ayahNumber: 3,
            textUthmani: 'لَمْ يَلِدْ وَلَمْ يُولَدْ',
            translation: 'He neither begets nor is born.',
            words: [
              Word(position: 1, textUthmani: 'لَمْ', transliteration: 'lam'),
              Word(position: 2, textUthmani: 'يَلِدْ', transliteration: 'yalid'),
              Word(position: 3, textUthmani: 'وَلَمْ', transliteration: 'wa-lam'),
              Word(position: 4, textUthmani: 'يُولَدْ', transliteration: 'yulad'),
            ],
          ),
          Ayah(
            surahNumber: 112,
            ayahNumber: 4,
            textUthmani: 'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ',
            translation: 'Nor is there to Him any equivalent.',
            words: [
              Word(position: 1, textUthmani: 'وَلَمْ', transliteration: 'wa-lam'),
              Word(position: 2, textUthmani: 'يَكُن', transliteration: 'yakun'),
              Word(position: 3, textUthmani: 'لَّهُۥ', transliteration: 'lahu'),
              Word(position: 4, textUthmani: 'كُفُوًا', transliteration: 'kufuwan'),
              Word(position: 5, textUthmani: 'أَحَدٌۢ', transliteration: 'ahad'),
            ],
          ),
        ];

      case 114:
        return const [
          Ayah(
            surahNumber: 114,
            ayahNumber: 1,
            textUthmani: 'قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ',
            translation: 'Say, "I seek refuge in the Lord of mankind."',
            words: [
              Word(position: 1, textUthmani: 'قُلْ', transliteration: 'qul'),
              Word(position: 2, textUthmani: 'أَعُوذُ', transliteration: 'a\'udhu'),
              Word(position: 3, textUthmani: 'بِرَبِّ', transliteration: 'bi-rabbi'),
              Word(position: 4, textUthmani: 'ٱلنَّاسِ', transliteration: 'an-nas'),
            ],
          ),
        ];

      default:
        return null;
    }
  }
}

