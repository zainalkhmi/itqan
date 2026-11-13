import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/qiraat_type.dart';

final qiraatServiceProvider = Provider<QiraatService>((ref) {
  return QiraatService();
});

class QiraatService {
  static const String boxKey = 'active_qiraat';
  QiraatRiwayah _activeRiwayah = QiraatRiwayah.hafs;

  QiraatRiwayah get activeRiwayah => _activeRiwayah;
  QiraatInfo get activeQiraatInfo => getQiraatInfo(_activeRiwayah);

  Future<void> init() async {
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        final saved = box.get(boxKey);
        if (saved != null) {
          _activeRiwayah = QiraatRiwayah.values.firstWhere(
            (r) => r.name == saved,
            orElse: () => QiraatRiwayah.hafs,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> setActiveRiwayah(QiraatRiwayah riwayah) async {
    _activeRiwayah = riwayah;
    try {
      if (Hive.isBoxOpen('settings')) {
        await Hive.box('settings').put(boxKey, riwayah.name);
      }
    } catch (_) {}
  }

  List<QiraatInfo> getAllQiraat() => [
    const QiraatInfo(
      riwayah: QiraatRiwayah.hafs,
      name: 'Hafs \'an \'Asim',
      arabicName: 'حَفْص عَنْ عَاصِم',
      imam: 'Imam \'Asim al-Kufi (d. 127 H)',
      rawi: 'Hafs bin Sulayman (d. 180 H)',
      primaryRegion: 'Global / Standard (90% of Muslim World)',
      description: 'The standard and most widespread recitation worldwide, codified through the Kufic transmission chain.',
      phoneticRules: [
        'Madd Tabee\'i: 2 harakat count (400-500ms)',
        'Madd Muttasil & Munfasil: 4 or 5 harakat count',
        'Madd Lazim: strictly 6 harakat count',
        'Distinct Hamzah articulation without regular Naql (transfer)',
        'Imalah occurs only once in the entire Quran (Surah Hud 11:41)',
      ],
      sampleDifferences: {
        'Al-Fatihah 1:4': 'مَٰلِكِ يَوْمِ ٱلدِّينِ (with Alif elongation)',
        'Al-Baqarah 2:9': 'يُخَٰدِعُونَ ٱللَّهَ وَٱلَّذِينَ ءَامَنُوا وَمَا يَخْدَعُونَ',
        'Al-Baqarah 2:10': 'بِمَا كَانُوا۟ يَكْذِبُونَ (with fathah & sukun)',
      },
      reciters: [
        QiraatReciter(
          id: 'alafasy',
          name: 'Mishary Rashid Alafasy',
          arabicName: 'مشاري راشد العفاسي',
          audioBaseUrl: 'https://everyayah.com/data/Alafasy_128kbps',
        ),
        QiraatReciter(
          id: 'husary_hafs',
          name: 'Mahmoud Khalil Al-Husary',
          arabicName: 'محمود خليل الحصري',
          audioBaseUrl: 'https://everyayah.com/data/Husary_128kbps',
        ),
        QiraatReciter(
          id: 'abdulbasit',
          name: 'Abdul Basit Murattal',
          arabicName: 'عبد الباسط عبد الصمد',
          audioBaseUrl: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps',
        ),
      ],
    ),

    const QiraatInfo(
      riwayah: QiraatRiwayah.warsh,
      name: 'Warsh \'an Nafi\'',
      arabicName: 'وَرْش عَنْ نَافِع',
      imam: 'Imam Nafi\' al-Madani (d. 169 H)',
      rawi: 'Abu Sa\'id Uthman al-Misri (Warsh, d. 197 H)',
      primaryRegion: 'North & West Africa (Morocco, Algeria, Mauritania, Senegal)',
      description: 'The premier recitation of Madinah preserved through Egypt and the Maghrib, celebrated for phonetic ease and melodic flow.',
      phoneticRules: [
        'Naql: transfers vowel of Hamzah to preceding quiescent consonant (e.g., قَدْ أَفْلَحَ -> قَدَفْلَحَ)',
        'Tarqiq of Ra\' (thin R) when preceded by a permanent Kasrah or quiescent Yaa',
        'Taghlidh of Lam (thick L) when preceded by Saadh, Dhaad, or Taa (e.g., صَلَاة -> صَلاَة)',
        'Madd Badal: flexibility of 2, 4, or 6 harakat counts on words like ءَامَنُوا',
        'Taqleel (Imalah Sughra) on specific Alif endings (Dhat al-Yaa)',
      ],
      sampleDifferences: {
        'Al-Fatihah 1:4': 'مَلِكِ يَوْمِ الدِّينِ (without Alif elongation)',
        'Al-Baqarah 2:9': 'يُخَادِعُونَ اللَّهَ وَالَّذِينَ آمَنُوا وَمَا يُخَادِعُونَ',
        'Al-Baqarah 2:10': 'بِمَا كَانُوا يُكَذِّبُونَ (with shaddah on Thal)',
      },
      reciters: [
        QiraatReciter(
          id: 'yassine_warsh',
          name: 'Yassine Al-Jazairi (Warsh)',
          arabicName: 'ياسين الجزائري',
          audioBaseUrl: 'https://everyayah.com/data/Yassine_Al-Jazairi_Warsh_64kbps',
        ),
        QiraatReciter(
          id: 'husary_warsh',
          name: 'Al-Husary (Warsh an Nafi)',
          arabicName: 'محمود خليل الحصري (ورش)',
          audioBaseUrl: 'https://everyayah.com/data/Warsh_Husary_128kbps',
        ),
      ],
    ),

    const QiraatInfo(
      riwayah: QiraatRiwayah.qalun,
      name: 'Qalun \'an Nafi\'',
      arabicName: 'قَالُون عَنْ نَافِع',
      imam: 'Imam Nafi\' al-Madani (d. 169 H)',
      rawi: 'Isa bin Mina (Qalun, d. 220 H)',
      primaryRegion: 'Libya, Tunisia, parts of Chad and West Africa',
      description: 'The primary student of Imam Nafi\' in Madinah, celebrated for exceptional clarity in pronunciation and vocal cadence.',
      phoneticRules: [
        'Silat Mim al-Jam\': vocalizing plural Mim with an optional or required Waw elongation (عَلَيْهِمُو)',
        'Tashil: softening the second of two adjacent Hamzahs in the same word (e.g., ءَأَنذَرْتَهُمْ)',
        'Sukoon on specific vowelled Yaa endings (Yaa\'at al-Idhafah)',
        'Madd Munfasil optional shortening (Qasr: 2 harakat) or elongation (4 harakat)',
      ],
      sampleDifferences: {
        'Al-Fatihah 1:4': 'مَلِكِ يَوْمِ الدِّينِ (Malik without Alif)',
        'Al-Fatihah 1:7': 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمُو (with Silat Mim al-Jam\')',
        'Al-Baqarah 2:6': 'سَوَاءٌ عَلَيْهِمُو ءَاهـَنذَرْتَهُمُو (Tashil + Silat Mim)',
      },
      reciters: [
        QiraatReciter(
          id: 'hudaifi_qalun',
          name: 'Ali Al-Hudaifi (Qalun)',
          arabicName: 'علي بن عبد الرحمن الحذيفي (قالون)',
          audioBaseUrl: 'https://everyayah.com/data/Ali_Hudaifi_Qaloon_128kbps',
        ),
        QiraatReciter(
          id: 'dukali_qalun',
          name: 'Al-Dukali Muhammad Al-Alim',
          arabicName: 'الدكالي محمد العالم (قالون)',
          audioBaseUrl: 'https://everyayah.com/data/Dukali_Qaloon_128kbps',
        ),
      ],
    ),

    const QiraatInfo(
      riwayah: QiraatRiwayah.duri,
      name: 'Ad-Duri \'an Abi \'Amr',
      arabicName: 'الدُّورِي عَنْ أَبِي عَمْرٍو',
      imam: 'Imam Abu \'Amr al-Basri (d. 154 H)',
      rawi: 'Abu \'Umar Hafs bin Umar ad-Duri (d. 246 H)',
      primaryRegion: 'Sudan, Somalia, parts of Yemen and East Africa',
      description: 'The venerable Basran transmission chain renowned for classical Arabic dialectal contractions (Idgham Kabir) and Imalah.',
      phoneticRules: [
        'Idgham Kabir: complete merging of two vowelled consonants across words (الرَّحِيمِ مَلِكِ -> الرَّحِيمَِّلِكِ)',
        'Imalah Kubra: tilting Alif distinctly towards Yaa after Ra\' (e.g., أَبْصَارِهِمْ pronounced Abseerihim)',
        'Tashil and Isqat: dropping or softening double consecutive Hamzahs across words',
        'Ikhtilas: slight vowel reduction in specific morphological transitions',
      ],
      sampleDifferences: {
        'Al-Fatihah 1:4': 'مَلِكِ يَوْمِ الدِّينِ (Malik without Alif)',
        'Al-Baqarah 2:19': 'فِي آذَانِهِم مِّنَ الصَّوَاعِقِ حَذَرَ الْمَوْتِ (with Imalah on Dhat ar-Ra)',
        'Al-Baqarah 2:20': 'يَخْطَفُ أَبْصِيرَهُمْ (Imalah Kubra on Abseerihim)',
      },
      reciters: [
        QiraatReciter(
          id: 'zubair_duri',
          name: 'Al-Fateh Muhammad Zubair (Sudan)',
          arabicName: 'الفاتح محمد زبير (الدوري)',
          audioBaseUrl: 'https://everyayah.com/data/Al-Fateh_Zubair_Duri_128kbps',
        ),
        QiraatReciter(
          id: 'nourin_duri',
          name: 'Nurin Mohamed Siddiq (Sudan)',
          arabicName: 'نورين محمد صديق (الدوري)',
          audioBaseUrl: 'https://everyayah.com/data/Nourin_Siddiq_Duri_128kbps',
        ),
      ],
    ),
  ];

  QiraatInfo getQiraatInfo(QiraatRiwayah riwayah) {
    return getAllQiraat().firstWhere(
      (q) => q.riwayah == riwayah,
      orElse: () => getAllQiraat().first,
    );
  }

  String getAyahTextVariant(int surah, int ayah, String defaultText) {
    if (surah == 1 && ayah == 4) {
      if (_activeRiwayah == QiraatRiwayah.hafs) {
        return 'مَٰلِكِ يَوْمِ ٱلدِّينِ';
      } else {
        return 'مَلِكِ يَوْمِ الدِّينِ';
      }
    }
    return defaultText;
  }
}
