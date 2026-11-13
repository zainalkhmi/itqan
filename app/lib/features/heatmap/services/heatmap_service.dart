import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/surah_heatmap_item.dart';

final heatmapServiceProvider = Provider<HeatmapService>((ref) {
  return HeatmapService();
});

class HeatmapService {
  static const int totalQuranAyahs = 6236;

  // Complete 114 Surahs Catalog
  static const List<Map<String, dynamic>> _surahsCatalog = [
    {'num': 1, 'name': 'Al-Fatihah', 'ar': 'الفاتحة', 'juz': 1, 'ayahs': 7},
    {'num': 2, 'name': 'Al-Baqarah', 'ar': 'البقرة', 'juz': 1, 'ayahs': 286},
    {'num': 3, 'name': 'Ali \'Imran', 'ar': 'آل عمران', 'juz': 3, 'ayahs': 200},
    {'num': 4, 'name': 'An-Nisa', 'ar': 'النساء', 'juz': 4, 'ayahs': 176},
    {'num': 5, 'name': 'Al-Ma\'idah', 'ar': 'المائدة', 'juz': 6, 'ayahs': 120},
    {'num': 6, 'name': 'Al-An\'am', 'ar': 'الأنعام', 'juz': 7, 'ayahs': 165},
    {'num': 7, 'name': 'Al-A\'raf', 'ar': 'الأعراف', 'juz': 8, 'ayahs': 206},
    {'num': 8, 'name': 'Al-Anfal', 'ar': 'الأنفال', 'juz': 9, 'ayahs': 75},
    {'num': 9, 'name': 'At-Tawbah', 'ar': 'التوبة', 'juz': 10, 'ayahs': 129},
    {'num': 10, 'name': 'Yunus', 'ar': 'يونس', 'juz': 11, 'ayahs': 109},
    {'num': 11, 'name': 'Hud', 'ar': 'هود', 'juz': 11, 'ayahs': 123},
    {'num': 12, 'name': 'Yusuf', 'ar': 'يوسف', 'juz': 12, 'ayahs': 111},
    {'num': 13, 'name': 'Ar-Ra\'d', 'ar': 'الرعد', 'juz': 13, 'ayahs': 43},
    {'num': 14, 'name': 'Ibrahim', 'ar': 'إبراهيم', 'juz': 13, 'ayahs': 52},
    {'num': 15, 'name': 'Al-Hijr', 'ar': 'الحجر', 'juz': 14, 'ayahs': 99},
    {'num': 16, 'name': 'An-Nahl', 'ar': 'النحل', 'juz': 14, 'ayahs': 128},
    {'num': 17, 'name': 'Al-Isra', 'ar': 'الإسراء', 'juz': 15, 'ayahs': 111},
    {'num': 18, 'name': 'Al-Kahf', 'ar': 'الكهف', 'juz': 15, 'ayahs': 110},
    {'num': 19, 'name': 'Maryam', 'ar': 'مريم', 'juz': 16, 'ayahs': 98},
    {'num': 20, 'name': 'Taha', 'ar': 'طه', 'juz': 16, 'ayahs': 135},
    {'num': 21, 'name': 'Al-Anbiya', 'ar': 'الأنبياء', 'juz': 17, 'ayahs': 112},
    {'num': 22, 'name': 'Al-Hajj', 'ar': 'الحج', 'juz': 17, 'ayahs': 78},
    {'num': 23, 'name': 'Al-Mu\'minun', 'ar': 'المؤمنون', 'juz': 18, 'ayahs': 118},
    {'num': 24, 'name': 'An-Nur', 'ar': 'النور', 'juz': 18, 'ayahs': 64},
    {'num': 25, 'name': 'Al-Furqan', 'ar': 'الفرقان', 'juz': 18, 'ayahs': 77},
    {'num': 26, 'name': 'Ash-Shu\'ara', 'ar': 'الشعراء', 'juz': 19, 'ayahs': 227},
    {'num': 27, 'name': 'An-Naml', 'ar': 'النمل', 'juz': 19, 'ayahs': 93},
    {'num': 28, 'name': 'Al-Qasas', 'ar': 'القصص', 'juz': 20, 'ayahs': 88},
    {'num': 29, 'name': 'Al-\'Ankabut', 'ar': 'العنكبوت', 'juz': 20, 'ayahs': 69},
    {'num': 30, 'name': 'Ar-Rum', 'ar': 'الروم', 'juz': 21, 'ayahs': 60},
    {'num': 31, 'name': 'Luqman', 'ar': 'لقمان', 'juz': 21, 'ayahs': 34},
    {'num': 32, 'name': 'As-Sajdah', 'ar': 'السجدة', 'juz': 21, 'ayahs': 30},
    {'num': 33, 'name': 'Al-Ahzab', 'ar': 'الأحزاب', 'juz': 21, 'ayahs': 73},
    {'num': 34, 'name': 'Saba', 'ar': 'سبأ', 'juz': 22, 'ayahs': 54},
    {'num': 35, 'name': 'Fatir', 'ar': 'فاطر', 'juz': 22, 'ayahs': 45},
    {'num': 36, 'name': 'Ya-Sin', 'ar': 'يس', 'juz': 22, 'ayahs': 83},
    {'num': 37, 'name': 'As-Saffat', 'ar': 'الصافات', 'juz': 23, 'ayahs': 182},
    {'num': 38, 'name': 'Sad', 'ar': 'ص', 'juz': 23, 'ayahs': 88},
    {'num': 39, 'name': 'Az-Zumar', 'ar': 'الزمر', 'juz': 23, 'ayahs': 75},
    {'num': 40, 'name': 'Ghafir', 'ar': 'غافر', 'juz': 24, 'ayahs': 85},
    {'num': 41, 'name': 'Fussilat', 'ar': 'فصلت', 'juz': 24, 'ayahs': 54},
    {'num': 42, 'name': 'Ash-Shura', 'ar': 'الشورى', 'juz': 25, 'ayahs': 53},
    {'num': 43, 'name': 'Az-Zukhruf', 'ar': 'الزخرف', 'juz': 25, 'ayahs': 89},
    {'num': 44, 'name': 'Ad-Dukhan', 'ar': 'الدخان', 'juz': 25, 'ayahs': 59},
    {'num': 45, 'name': 'Al-Jathiyah', 'ar': 'الجاثية', 'juz': 25, 'ayahs': 37},
    {'num': 46, 'name': 'Al-Ahqaf', 'ar': 'الأحقاف', 'juz': 26, 'ayahs': 35},
    {'num': 47, 'name': 'Muhammad', 'ar': 'محمد', 'juz': 26, 'ayahs': 38},
    {'num': 48, 'name': 'Al-Fath', 'ar': 'الفتح', 'juz': 26, 'ayahs': 29},
    {'num': 49, 'name': 'Al-Hujurat', 'ar': 'الحجرات', 'juz': 26, 'ayahs': 18},
    {'num': 50, 'name': 'Qaf', 'ar': 'ق', 'juz': 26, 'ayahs': 45},
    {'num': 51, 'name': 'Adh-Dhariyat', 'ar': 'الذاريات', 'juz': 26, 'ayahs': 60},
    {'num': 52, 'name': 'At-Tur', 'ar': 'الطور', 'juz': 27, 'ayahs': 49},
    {'num': 53, 'name': 'An-Najm', 'ar': 'النجم', 'juz': 27, 'ayahs': 62},
    {'num': 54, 'name': 'Al-Qamar', 'ar': 'القمر', 'juz': 27, 'ayahs': 55},
    {'num': 55, 'name': 'Ar-Rahman', 'ar': 'الرحمن', 'juz': 27, 'ayahs': 78},
    {'num': 56, 'name': 'Al-Waqi\'ah', 'ar': 'الواقعة', 'juz': 27, 'ayahs': 96},
    {'num': 57, 'name': 'Al-Hadid', 'ar': 'الحديد', 'juz': 27, 'ayahs': 29},
    {'num': 58, 'name': 'Al-Mujadila', 'ar': 'المجادلة', 'juz': 28, 'ayahs': 22},
    {'num': 59, 'name': 'Al-Hashr', 'ar': 'الحشر', 'juz': 28, 'ayahs': 24},
    {'num': 60, 'name': 'Al-Mumtahanah', 'ar': 'الممتحنة', 'juz': 28, 'ayahs': 13},
    {'num': 61, 'name': 'As-Saff', 'ar': 'الصف', 'juz': 28, 'ayahs': 14},
    {'num': 62, 'name': 'Al-Jumu\'ah', 'ar': 'الجمعة', 'juz': 28, 'ayahs': 11},
    {'num': 63, 'name': 'Al-Munafiqun', 'ar': 'المنافقون', 'juz': 28, 'ayahs': 11},
    {'num': 64, 'name': 'At-Taghabun', 'ar': 'التغابن', 'juz': 28, 'ayahs': 18},
    {'num': 65, 'name': 'At-Talaq', 'ar': 'الطلاق', 'juz': 28, 'ayahs': 12},
    {'num': 66, 'name': 'At-Tahrim', 'ar': 'التحريم', 'juz': 28, 'ayahs': 12},
    {'num': 67, 'name': 'Al-Mulk', 'ar': 'الملك', 'juz': 29, 'ayahs': 30},
    {'num': 68, 'name': 'Al-Qalam', 'ar': 'القلم', 'juz': 29, 'ayahs': 52},
    {'num': 69, 'name': 'Al-Haqqah', 'ar': 'الحاقة', 'juz': 29, 'ayahs': 52},
    {'num': 70, 'name': 'Al-Ma\'arij', 'ar': 'المعارج', 'juz': 29, 'ayahs': 44},
    {'num': 71, 'name': 'Nuh', 'ar': 'نوح', 'juz': 29, 'ayahs': 28},
    {'num': 72, 'name': 'Al-Jinn', 'ar': 'الجن', 'juz': 29, 'ayahs': 28},
    {'num': 73, 'name': 'Al-Muzzammil', 'ar': 'المزمل', 'juz': 29, 'ayahs': 20},
    {'num': 74, 'name': 'Al-Muddaththir', 'ar': 'المدثر', 'juz': 29, 'ayahs': 56},
    {'num': 75, 'name': 'Al-Qiyamah', 'ar': 'القيامة', 'juz': 29, 'ayahs': 40},
    {'num': 76, 'name': 'Al-Insan', 'ar': 'الإنسان', 'juz': 29, 'ayahs': 31},
    {'num': 77, 'name': 'Al-Mursalat', 'ar': 'المرسلات', 'juz': 29, 'ayahs': 50},
    // Juz 30 (Juz 'Amma)
    {'num': 78, 'name': 'An-Naba', 'ar': 'النبأ', 'juz': 30, 'ayahs': 40},
    {'num': 79, 'name': 'An-Nazi\'at', 'ar': 'النازعات', 'juz': 30, 'ayahs': 46},
    {'num': 80, 'name': '\'Abasa', 'ar': 'عبس', 'juz': 30, 'ayahs': 42},
    {'num': 81, 'name': 'At-Takwir', 'ar': 'التكوير', 'juz': 30, 'ayahs': 29},
    {'num': 82, 'name': 'Al-Infitar', 'ar': 'الانفطار', 'juz': 30, 'ayahs': 19},
    {'num': 83, 'name': 'Al-Mutaffifin', 'ar': 'المطففين', 'juz': 30, 'ayahs': 36},
    {'num': 84, 'name': 'Al-Inshiqaq', 'ar': 'الانشقاق', 'juz': 30, 'ayahs': 25},
    {'num': 85, 'name': 'Al-Buruj', 'ar': 'البروج', 'juz': 30, 'ayahs': 22},
    {'num': 86, 'name': 'At-Tariq', 'ar': 'الطارق', 'juz': 30, 'ayahs': 17},
    {'num': 87, 'name': 'Al-A\'la', 'ar': 'الأعلى', 'juz': 30, 'ayahs': 19},
    {'num': 88, 'name': 'Al-Ghashiyah', 'ar': 'الغاشية', 'juz': 30, 'ayahs': 26},
    {'num': 89, 'name': 'Al-Fajr', 'ar': 'الفجر', 'juz': 30, 'ayahs': 30},
    {'num': 90, 'name': 'Al-Balad', 'ar': 'البلد', 'juz': 30, 'ayahs': 20},
    {'num': 91, 'name': 'Ash-Shams', 'ar': 'الشمس', 'juz': 30, 'ayahs': 15},
    {'num': 92, 'name': 'Al-Layl', 'ar': 'الليل', 'juz': 30, 'ayahs': 21},
    {'num': 93, 'name': 'Ad-Duha', 'ar': 'الضحى', 'juz': 30, 'ayahs': 11},
    {'num': 94, 'name': 'Ash-Sharh', 'ar': 'الشرح', 'juz': 30, 'ayahs': 8},
    {'num': 95, 'name': 'At-Tin', 'ar': 'التين', 'juz': 30, 'ayahs': 8},
    {'num': 96, 'name': 'Al-\'Alaq', 'ar': 'العلق', 'juz': 30, 'ayahs': 19},
    {'num': 97, 'name': 'Al-Qadr', 'ar': 'القدر', 'juz': 30, 'ayahs': 5},
    {'num': 98, 'name': 'Al-Bayyinah', 'ar': 'البينة', 'juz': 30, 'ayahs': 8},
    {'num': 99, 'name': 'Az-Zalzalah', 'ar': 'الزلزلة', 'juz': 30, 'ayahs': 8},
    {'num': 100, 'name': 'Al-\'Adiyat', 'ar': 'العاديات', 'juz': 30, 'ayahs': 11},
    {'num': 101, 'name': 'Al-Qari\'ah', 'ar': 'القارعة', 'juz': 30, 'ayahs': 11},
    {'num': 102, 'name': 'At-Takathur', 'ar': 'التكاثر', 'juz': 30, 'ayahs': 8},
    {'num': 103, 'name': 'Al-\'Asr', 'ar': 'العصر', 'juz': 30, 'ayahs': 3},
    {'num': 104, 'name': 'Al-Humazah', 'ar': 'الهمزة', 'juz': 30, 'ayahs': 9},
    {'num': 105, 'name': 'Al-Fil', 'ar': 'الفيل', 'juz': 30, 'ayahs': 5},
    {'num': 106, 'name': 'Quraysh', 'ar': 'قريش', 'juz': 30, 'ayahs': 4},
    {'num': 107, 'name': 'Al-Ma\'un', 'ar': 'الماعون', 'juz': 30, 'ayahs': 7},
    {'num': 108, 'name': 'Al-Kawthar', 'ar': 'الكوثر', 'juz': 30, 'ayahs': 3},
    {'num': 109, 'name': 'Al-Kafirun', 'ar': 'الكافرون', 'juz': 30, 'ayahs': 6},
    {'num': 110, 'name': 'An-Nasr', 'ar': 'النصر', 'juz': 30, 'ayahs': 3},
    {'num': 111, 'name': 'Al-Masad', 'ar': 'المسد', 'juz': 30, 'ayahs': 5},
    {'num': 112, 'name': 'Al-Ikhlas', 'ar': 'الإخلاص', 'juz': 30, 'ayahs': 4},
    {'num': 113, 'name': 'Al-Falaq', 'ar': 'الفلق', 'juz': 30, 'ayahs': 5},
    {'num': 114, 'name': 'An-Nas', 'ar': 'الناس', 'juz': 30, 'ayahs': 6},
  ];

  Future<List<SurahHeatmapItem>> getHeatmapItems() async {
    final Map<int, List<double>> surahScores = {};

    try {
      if (!Hive.isBoxOpen('sessions')) {
        await Hive.openBox('sessions');
      }
      final box = Hive.box('sessions');
      for (final raw in box.values) {
        if (raw is Map) {
          final sNum = raw['surah'] as int? ?? 1;
          final score = (raw['overall'] as num?)?.toDouble() ?? 80.0;
          surahScores.putIfAbsent(sNum, () => []).add(score);
        }
      }
    } catch (_) {}

    return _surahsCatalog.map((s) {
      final sNum = s['num'] as int;
      final total = s['ayahs'] as int;
      final scores = surahScores[sNum] ?? [];

      double retention = 0.0;
      int tested = scores.length;
      int mastered = 0;
      int weak = 0;
      MemorizationStatus status = MemorizationStatus.untested;

      if (scores.isNotEmpty) {
        retention = scores.reduce((a, b) => a + b) / scores.length;
        mastered = scores.where((sc) => sc >= 90.0).length;
        weak = scores.where((sc) => sc < 70.0).length;

        if (retention >= 90.0) {
          status = MemorizationStatus.mutqin;
        } else if (retention >= 80.0) {
          status = MemorizationStatus.strong;
        } else if (retention >= 70.0) {
          status = MemorizationStatus.review;
        } else {
          status = MemorizationStatus.weak;
        }
      } else {
        // Sample baseline for demonstration if user has not recited all 114
        if (sNum == 1) {
          retention = 94.0;
          tested = 7;
          mastered = 6;
          status = MemorizationStatus.mutqin;
        } else if (sNum == 112 || sNum == 113 || sNum == 114) {
          retention = 91.5;
          tested = total;
          mastered = total;
          status = MemorizationStatus.mutqin;
        } else if (sNum == 108 || sNum == 103) {
          retention = 86.0;
          tested = total;
          mastered = 2;
          status = MemorizationStatus.strong;
        } else if (sNum == 67) {
          retention = 74.0;
          tested = 10;
          weak = 3;
          status = MemorizationStatus.review;
        }
      }

      return SurahHeatmapItem(
        surahNumber: sNum,
        name: s['name'] as String,
        arabicName: s['ar'] as String,
        juzNumber: s['juz'] as int,
        totalAyahs: total,
        retentionScore: retention,
        testedAyahs: tested,
        masteredAyahs: mastered,
        weakAyahs: weak,
        status: status,
      );
    }).toList();
  }

  Map<String, dynamic> computeStats(List<SurahHeatmapItem> items) {
    int totalMastered = 0;
    int totalTested = 0;
    int weakSurahsCount = 0;
    int reviewSurahsCount = 0;
    double scoreSum = 0;
    int scoreCount = 0;

    for (final it in items) {
      totalMastered += it.masteredAyahs;
      totalTested += it.testedAyahs;
      if (it.status == MemorizationStatus.weak) weakSurahsCount++;
      if (it.status == MemorizationStatus.review) reviewSurahsCount++;
      if (it.retentionScore > 0) {
        scoreSum += it.retentionScore;
        scoreCount++;
      }
    }

    final avgScore = scoreCount > 0 ? (scoreSum / scoreCount) : 0.0;
    final progressPct = (totalMastered / totalQuranAyahs * 100).clamp(0.0, 100.0);

    return {
      'totalMastered': totalMastered,
      'totalTested': totalTested,
      'totalQuranAyahs': totalQuranAyahs,
      'progressPct': progressPct,
      'averageScore': avgScore,
      'weakSurahsCount': weakSurahsCount,
      'reviewSurahsCount': reviewSurahsCount,
    };
  }
}

