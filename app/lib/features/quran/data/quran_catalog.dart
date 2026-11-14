import '../models/ayah.dart';

/// Complete Canonical 114 Surahs Catalog of the Holy Quran
class QuranCatalog {
  QuranCatalog._();

  static const List<Surah> surahs = [
    Surah(number: 1, nameSimple: 'Al-Fatihah', nameArabic: 'الفاتحة', nameTranslation: 'The Opener', ayahCount: 7, revelationPlace: 'makkah'),
    Surah(number: 2, nameSimple: 'Al-Baqarah', nameArabic: 'البقرة', nameTranslation: 'The Cow', ayahCount: 286, revelationPlace: 'madinah'),
    Surah(number: 3, nameSimple: 'Ali \'Imran', nameArabic: 'آل عمران', nameTranslation: 'Family of Imran', ayahCount: 200, revelationPlace: 'madinah'),
    Surah(number: 4, nameSimple: 'An-Nisa', nameArabic: 'النساء', nameTranslation: 'The Women', ayahCount: 176, revelationPlace: 'madinah'),
    Surah(number: 5, nameSimple: 'Al-Ma\'idah', nameArabic: 'المائدة', nameTranslation: 'The Table Spread', ayahCount: 120, revelationPlace: 'madinah'),
    Surah(number: 6, nameSimple: 'Al-An\'am', nameArabic: 'الأنعام', nameTranslation: 'The Cattle', ayahCount: 165, revelationPlace: 'makkah'),
    Surah(number: 7, nameSimple: 'Al-A\'raf', nameArabic: 'الأعراف', nameTranslation: 'The Heights', ayahCount: 206, revelationPlace: 'makkah'),
    Surah(number: 8, nameSimple: 'Al-Anfal', nameArabic: 'الأنفال', nameTranslation: 'The Spoils of War', ayahCount: 75, revelationPlace: 'madinah'),
    Surah(number: 9, nameSimple: 'At-Tawbah', nameArabic: 'التوبة', nameTranslation: 'The Repentance', ayahCount: 129, revelationPlace: 'madinah'),
    Surah(number: 10, nameSimple: 'Yunus', nameArabic: 'يونس', nameTranslation: 'Jonah', ayahCount: 109, revelationPlace: 'makkah'),
    Surah(number: 11, nameSimple: 'Hud', nameArabic: 'هود', nameTranslation: 'Hud', ayahCount: 123, revelationPlace: 'makkah'),
    Surah(number: 12, nameSimple: 'Yusuf', nameArabic: 'يوسف', nameTranslation: 'Joseph', ayahCount: 111, revelationPlace: 'makkah'),
    Surah(number: 13, nameSimple: 'Ar-Ra\'d', nameArabic: 'الرعد', nameTranslation: 'The Thunder', ayahCount: 43, revelationPlace: 'madinah'),
    Surah(number: 14, nameSimple: 'Ibrahim', nameArabic: 'إبراهيم', nameTranslation: 'Abraham', ayahCount: 52, revelationPlace: 'makkah'),
    Surah(number: 15, nameSimple: 'Al-Hijr', nameArabic: 'الحجر', nameTranslation: 'The Rocky Tract', ayahCount: 99, revelationPlace: 'makkah'),
    Surah(number: 16, nameSimple: 'An-Nahl', nameArabic: 'النحل', nameTranslation: 'The Bee', ayahCount: 128, revelationPlace: 'makkah'),
    Surah(number: 17, nameSimple: 'Al-Isra', nameArabic: 'الإسراء', nameTranslation: 'The Night Journey', ayahCount: 111, revelationPlace: 'makkah'),
    Surah(number: 18, nameSimple: 'Al-Kahf', nameArabic: 'الكهف', nameTranslation: 'The Cave', ayahCount: 110, revelationPlace: 'makkah'),
    Surah(number: 19, nameSimple: 'Maryam', nameArabic: 'مريم', nameTranslation: 'Mary', ayahCount: 98, revelationPlace: 'makkah'),
    Surah(number: 20, nameSimple: 'Taha', nameArabic: 'طه', nameTranslation: 'Ta-Ha', ayahCount: 135, revelationPlace: 'makkah'),
    Surah(number: 21, nameSimple: 'Al-Anbiya', nameArabic: 'الأنبياء', nameTranslation: 'The Prophets', ayahCount: 112, revelationPlace: 'makkah'),
    Surah(number: 22, nameSimple: 'Al-Hajj', nameArabic: 'الحج', nameTranslation: 'The Pilgrimage', ayahCount: 78, revelationPlace: 'madinah'),
    Surah(number: 23, nameSimple: 'Al-Mu\'minun', nameArabic: 'المؤمنون', nameTranslation: 'The Believers', ayahCount: 118, revelationPlace: 'makkah'),
    Surah(number: 24, nameSimple: 'An-Nur', nameArabic: 'النور', nameTranslation: 'The Light', ayahCount: 64, revelationPlace: 'madinah'),
    Surah(number: 25, nameSimple: 'Al-Furqan', nameArabic: 'الفرقان', nameTranslation: 'The Criterion', ayahCount: 77, revelationPlace: 'makkah'),
    Surah(number: 26, nameSimple: 'Ash-Shu\'ara', nameArabic: 'الشعراء', nameTranslation: 'The Poets', ayahCount: 227, revelationPlace: 'makkah'),
    Surah(number: 27, nameSimple: 'An-Naml', nameArabic: 'النمل', nameTranslation: 'The Ant', ayahCount: 93, revelationPlace: 'makkah'),
    Surah(number: 28, nameSimple: 'Al-Qasas', nameArabic: 'القصص', nameTranslation: 'The Stories', ayahCount: 88, revelationPlace: 'makkah'),
    Surah(number: 29, nameSimple: 'Al-\'Ankabut', nameArabic: 'العنكبوت', nameTranslation: 'The Spider', ayahCount: 69, revelationPlace: 'makkah'),
    Surah(number: 30, nameSimple: 'Ar-Rum', nameArabic: 'الروم', nameTranslation: 'The Romans', ayahCount: 60, revelationPlace: 'makkah'),
    Surah(number: 31, nameSimple: 'Luqman', nameArabic: 'لقمان', nameTranslation: 'Luqman', ayahCount: 34, revelationPlace: 'makkah'),
    Surah(number: 32, nameSimple: 'As-Sajdah', nameArabic: 'السجدة', nameTranslation: 'The Prostration', ayahCount: 30, revelationPlace: 'makkah'),
    Surah(number: 33, nameSimple: 'Al-Ahzab', nameArabic: 'الأحزاب', nameTranslation: 'The Combined Forces', ayahCount: 73, revelationPlace: 'madinah'),
    Surah(number: 34, nameSimple: 'Saba', nameArabic: 'سبأ', nameTranslation: 'Sheba', ayahCount: 54, revelationPlace: 'makkah'),
    Surah(number: 35, nameSimple: 'Fatir', nameArabic: 'فاطر', nameTranslation: 'Originator', ayahCount: 45, revelationPlace: 'makkah'),
    Surah(number: 36, nameSimple: 'Ya-Sin', nameArabic: 'يس', nameTranslation: 'Ya Sin', ayahCount: 83, revelationPlace: 'makkah'),
    Surah(number: 37, nameSimple: 'As-Saffat', nameArabic: 'الصافات', nameTranslation: 'Those who set the Ranks', ayahCount: 182, revelationPlace: 'makkah'),
    Surah(number: 38, nameSimple: 'Sad', nameArabic: 'ص', nameTranslation: 'The Letter Sad', ayahCount: 88, revelationPlace: 'makkah'),
    Surah(number: 39, nameSimple: 'Az-Zumar', nameArabic: 'الزمر', nameTranslation: 'The Troops', ayahCount: 75, revelationPlace: 'makkah'),
    Surah(number: 40, nameSimple: 'Ghafir', nameArabic: 'غافر', nameTranslation: 'The Forgiver', ayahCount: 85, revelationPlace: 'makkah'),
    Surah(number: 41, nameSimple: 'Fussilat', nameArabic: 'فصلت', nameTranslation: 'Explained in Detail', ayahCount: 54, revelationPlace: 'makkah'),
    Surah(number: 42, nameSimple: 'Ash-Shuraa', nameArabic: 'الشورى', nameTranslation: 'The Consultation', ayahCount: 53, revelationPlace: 'makkah'),
    Surah(number: 43, nameSimple: 'Az-Zukhruf', nameArabic: 'الزخرف', nameTranslation: 'The Ornaments of Gold', ayahCount: 89, revelationPlace: 'makkah'),
    Surah(number: 44, nameSimple: 'Ad-Dukhan', nameArabic: 'الدخان', nameTranslation: 'The Smoke', ayahCount: 59, revelationPlace: 'makkah'),
    Surah(number: 45, nameSimple: 'Al-Jathiyah', nameArabic: 'الجاثية', nameTranslation: 'The Crouching', ayahCount: 37, revelationPlace: 'makkah'),
    Surah(number: 46, nameSimple: 'Al-Ahqaf', nameArabic: 'الأحقاف', nameTranslation: 'The Wind-Curved Sandhills', ayahCount: 35, revelationPlace: 'makkah'),
    Surah(number: 47, nameSimple: 'Muhammad', nameArabic: 'محمد', nameTranslation: 'Muhammad', ayahCount: 38, revelationPlace: 'madinah'),
    Surah(number: 48, nameSimple: 'Al-Fath', nameArabic: 'الفتح', nameTranslation: 'The Victory', ayahCount: 29, revelationPlace: 'madinah'),
    Surah(number: 49, nameSimple: 'Al-Hujurat', nameArabic: 'الحجرات', nameTranslation: 'The Rooms', ayahCount: 18, revelationPlace: 'madinah'),
    Surah(number: 50, nameSimple: 'Qaf', nameArabic: 'ق', nameTranslation: 'The Letter Qaf', ayahCount: 45, revelationPlace: 'makkah'),
    Surah(number: 51, nameSimple: 'Adh-Dhariyat', nameArabic: 'الذاريات', nameTranslation: 'The Winnowing Winds', ayahCount: 60, revelationPlace: 'makkah'),
    Surah(number: 52, nameSimple: 'At-Tur', nameArabic: 'الطور', nameTranslation: 'The Mount', ayahCount: 49, revelationPlace: 'makkah'),
    Surah(number: 53, nameSimple: 'An-Najm', nameArabic: 'النجم', nameTranslation: 'The Star', ayahCount: 62, revelationPlace: 'makkah'),
    Surah(number: 54, nameSimple: 'Al-Qamar', nameArabic: 'القمر', nameTranslation: 'The Moon', ayahCount: 55, revelationPlace: 'makkah'),
    Surah(number: 55, nameSimple: 'Ar-Rahman', nameArabic: 'الرحمن', nameTranslation: 'The Beneficent', ayahCount: 78, revelationPlace: 'madinah'),
    Surah(number: 56, nameSimple: 'Al-Waqi\'ah', nameArabic: 'الواقعة', nameTranslation: 'The Inevitable', ayahCount: 96, revelationPlace: 'makkah'),
    Surah(number: 57, nameSimple: 'Al-Hadid', nameArabic: 'الحديد', nameTranslation: 'The Iron', ayahCount: 29, revelationPlace: 'madinah'),
    Surah(number: 58, nameSimple: 'Al-Mujadila', nameArabic: 'المجادلة', nameTranslation: 'The Pleading Woman', ayahCount: 22, revelationPlace: 'madinah'),
    Surah(number: 59, nameSimple: 'Al-Hashr', nameArabic: 'الحشر', nameTranslation: 'The Exile', ayahCount: 24, revelationPlace: 'madinah'),
    Surah(number: 60, nameSimple: 'Al-Mumtahanah', nameArabic: 'الممتحنة', nameTranslation: 'She that is to be examined', ayahCount: 13, revelationPlace: 'madinah'),
    Surah(number: 61, nameSimple: 'As-Saf', nameArabic: 'الصف', nameTranslation: 'The Ranks', ayahCount: 14, revelationPlace: 'madinah'),
    Surah(number: 62, nameSimple: 'Al-Jumu\'ah', nameArabic: 'الجمعة', nameTranslation: 'The Congregation', ayahCount: 11, revelationPlace: 'madinah'),
    Surah(number: 63, nameSimple: 'Al-Munafiqun', nameArabic: 'المنافقون', nameTranslation: 'The Hypocrites', ayahCount: 11, revelationPlace: 'madinah'),
    Surah(number: 64, nameSimple: 'At-Taghabun', nameArabic: 'التغابن', nameTranslation: 'The Mutual Disillusion', ayahCount: 18, revelationPlace: 'madinah'),
    Surah(number: 65, nameSimple: 'At-Talaq', nameArabic: 'الطلاق', nameTranslation: 'The Divorce', ayahCount: 12, revelationPlace: 'madinah'),
    Surah(number: 66, nameSimple: 'At-Tahrim', nameArabic: 'التحريم', nameTranslation: 'The Prohibition', ayahCount: 12, revelationPlace: 'madinah'),
    Surah(number: 67, nameSimple: 'Al-Mulk', nameArabic: 'الملك', nameTranslation: 'The Sovereignty', ayahCount: 30, revelationPlace: 'makkah'),
    Surah(number: 68, nameSimple: 'Al-Qalam', nameArabic: 'القلم', nameTranslation: 'The Pen', ayahCount: 52, revelationPlace: 'makkah'),
    Surah(number: 69, nameSimple: 'Al-Haqqah', nameArabic: 'الحاقة', nameTranslation: 'The Reality', ayahCount: 52, revelationPlace: 'makkah'),
    Surah(number: 70, nameSimple: 'Al-Ma\'arij', nameArabic: 'المعارج', nameTranslation: 'The Ascending Stairways', ayahCount: 44, revelationPlace: 'makkah'),
    Surah(number: 71, nameSimple: 'Nuh', nameArabic: 'نوح', nameTranslation: 'Noah', ayahCount: 28, revelationPlace: 'makkah'),
    Surah(number: 72, nameSimple: 'Al-Jinn', nameArabic: 'الجن', nameTranslation: 'The Jinn', ayahCount: 28, revelationPlace: 'makkah'),
    Surah(number: 73, nameSimple: 'Al-Muzzammil', nameArabic: 'المزمل', nameTranslation: 'The Enshrouded One', ayahCount: 20, revelationPlace: 'makkah'),
    Surah(number: 74, nameSimple: 'Al-Muddaththir', nameArabic: 'المدثر', nameTranslation: 'The Cloaked One', ayahCount: 56, revelationPlace: 'makkah'),
    Surah(number: 75, nameSimple: 'Al-Qiyamah', nameArabic: 'القيامة', nameTranslation: 'The Resurrection', ayahCount: 40, revelationPlace: 'makkah'),
    Surah(number: 76, nameSimple: 'Al-Insan', nameArabic: 'الإنسان', nameTranslation: 'The Man', ayahCount: 31, revelationPlace: 'madinah'),
    Surah(number: 77, nameSimple: 'Al-Mursalat', nameArabic: 'المرسلات', nameTranslation: 'The Emissaries', ayahCount: 50, revelationPlace: 'makkah'),
    Surah(number: 78, nameSimple: 'An-Naba', nameArabic: 'النبأ', nameTranslation: 'The Tidings', ayahCount: 40, revelationPlace: 'makkah'),
    Surah(number: 79, nameSimple: 'An-Nazi\'at', nameArabic: 'النازعات', nameTranslation: 'Those who drag forth', ayahCount: 46, revelationPlace: 'makkah'),
    Surah(number: 80, nameSimple: '\'Abasa', nameArabic: 'عبس', nameTranslation: 'He Frowned', ayahCount: 42, revelationPlace: 'makkah'),
    Surah(number: 81, nameSimple: 'At-Takwir', nameArabic: 'التكوير', nameTranslation: 'The Overthrowing', ayahCount: 29, revelationPlace: 'makkah'),
    Surah(number: 82, nameSimple: 'Al-Infitar', nameArabic: 'الانفطار', nameTranslation: 'The Cleaving', ayahCount: 19, revelationPlace: 'makkah'),
    Surah(number: 83, nameSimple: 'Al-Mutaffifin', nameArabic: 'المطففين', nameTranslation: 'The Defrauding', ayahCount: 36, revelationPlace: 'makkah'),
    Surah(number: 84, nameSimple: 'Al-Inshiqaq', nameArabic: 'الانشقاق', nameTranslation: 'The Splitting Open', ayahCount: 25, revelationPlace: 'makkah'),
    Surah(number: 85, nameSimple: 'Al-Buruj', nameArabic: 'البروج', nameTranslation: 'The Mansions of the Stars', ayahCount: 22, revelationPlace: 'makkah'),
    Surah(number: 86, nameSimple: 'At-Tariq', nameArabic: 'الطارق', nameTranslation: 'The Morning Star', ayahCount: 17, revelationPlace: 'makkah'),
    Surah(number: 87, nameSimple: 'Al-A\'la', nameArabic: 'الأعلى', nameTranslation: 'The Most High', ayahCount: 19, revelationPlace: 'makkah'),
    Surah(number: 88, nameSimple: 'Al-Ghashiyah', nameArabic: 'الغاشية', nameTranslation: 'The Overwhelming', ayahCount: 26, revelationPlace: 'makkah'),
    Surah(number: 89, nameSimple: 'Al-Fajr', nameArabic: 'الفجر', nameTranslation: 'The Dawn', ayahCount: 30, revelationPlace: 'makkah'),
    Surah(number: 90, nameSimple: 'Al-Balad', nameArabic: 'البلد', nameTranslation: 'The City', ayahCount: 20, revelationPlace: 'makkah'),
    Surah(number: 91, nameSimple: 'Ash-Shams', nameArabic: 'الشمس', nameTranslation: 'The Sun', ayahCount: 15, revelationPlace: 'makkah'),
    Surah(number: 92, nameSimple: 'Al-Layl', nameArabic: 'الليل', nameTranslation: 'The Night', ayahCount: 21, revelationPlace: 'makkah'),
    Surah(number: 93, nameSimple: 'Ad-Duhaa', nameArabic: 'الضحى', nameTranslation: 'The Morning Hours', ayahCount: 11, revelationPlace: 'makkah'),
    Surah(number: 94, nameSimple: 'Ash-Sharh', nameArabic: 'الشرح', nameTranslation: 'The Relief', ayahCount: 8, revelationPlace: 'makkah'),
    Surah(number: 95, nameSimple: 'At-Tin', nameArabic: 'التين', nameTranslation: 'The Fig', ayahCount: 8, revelationPlace: 'makkah'),
    Surah(number: 96, nameSimple: 'Al-\'Alaq', nameArabic: 'العلق', nameTranslation: 'The Clot', ayahCount: 19, revelationPlace: 'makkah'),
    Surah(number: 97, nameSimple: 'Al-Qadr', nameArabic: 'القدر', nameTranslation: 'The Power', ayahCount: 5, revelationPlace: 'makkah'),
    Surah(number: 98, nameSimple: 'Al-Bayyinah', nameArabic: 'البينة', nameTranslation: 'The Clear Proof', ayahCount: 8, revelationPlace: 'madinah'),
    Surah(number: 99, nameSimple: 'Az-Zalzalah', nameArabic: 'الزلزلة', nameTranslation: 'The Earthquake', ayahCount: 8, revelationPlace: 'madinah'),
    Surah(number: 100, nameSimple: 'Al-\'Adiyat', nameArabic: 'العاديات', nameTranslation: 'The Courser', ayahCount: 11, revelationPlace: 'makkah'),
    Surah(number: 101, nameSimple: 'Al-Qari\'ah', nameArabic: 'القارعة', nameTranslation: 'The Calamity', ayahCount: 11, revelationPlace: 'makkah'),
    Surah(number: 102, nameSimple: 'At-Takathur', nameArabic: 'التكاثر', nameTranslation: 'The Rivalry in world increase', ayahCount: 8, revelationPlace: 'makkah'),
    Surah(number: 103, nameSimple: 'Al-\'Asr', nameArabic: 'العصر', nameTranslation: 'The Declining Day', ayahCount: 3, revelationPlace: 'makkah'),
    Surah(number: 104, nameSimple: 'Al-Humazah', nameArabic: 'الهمزة', nameTranslation: 'The Traducer', ayahCount: 9, revelationPlace: 'makkah'),
    Surah(number: 105, nameSimple: 'Al-Fil', nameArabic: 'الفيل', nameTranslation: 'The Elephant', ayahCount: 5, revelationPlace: 'makkah'),
    Surah(number: 106, nameSimple: 'Quraysh', nameArabic: 'قريش', nameTranslation: 'Quraysh', ayahCount: 4, revelationPlace: 'makkah'),
    Surah(number: 107, nameSimple: 'Al-Ma\'un', nameArabic: 'الماعون', nameTranslation: 'The Small Kindness', ayahCount: 7, revelationPlace: 'makkah'),
    Surah(number: 108, nameSimple: 'Al-Kawthar', nameArabic: 'الكوثر', nameTranslation: 'The Abundance', ayahCount: 3, revelationPlace: 'makkah'),
    Surah(number: 109, nameSimple: 'Al-Kafirun', nameArabic: 'الكافرون', nameTranslation: 'The Disbelievers', ayahCount: 6, revelationPlace: 'makkah'),
    Surah(number: 110, nameSimple: 'An-Nasr', nameArabic: 'النصر', nameTranslation: 'The Divine Support', ayahCount: 3, revelationPlace: 'madinah'),
    Surah(number: 111, nameSimple: 'Al-Masad', nameArabic: 'المسد', nameTranslation: 'The Palm Fiber', ayahCount: 5, revelationPlace: 'makkah'),
    Surah(number: 112, nameSimple: 'Al-Ikhlas', nameArabic: 'الإخلاص', nameTranslation: 'The Sincerity', ayahCount: 4, revelationPlace: 'makkah'),
    Surah(number: 113, nameSimple: 'Al-Falaq', nameArabic: 'الفلق', nameTranslation: 'The Daybreak', ayahCount: 5, revelationPlace: 'makkah'),
    Surah(number: 114, nameSimple: 'An-Nas', nameArabic: 'الناس', nameTranslation: 'Mankind', ayahCount: 6, revelationPlace: 'makkah'),
  ];

  static final Map<int, Surah> _byId = {
    for (final s in surahs) s.number: s,
  };

  static Surah getSurah(int number) {
    return _byId[number] ?? surahs.first;
  }

  static int getAyahCount(int surahNumber) {
    return getSurah(surahNumber).ayahCount;
  }

  static List<Surah> search(String query) {
    if (query.trim().isEmpty) return surahs;
    final q = query.trim().toLowerCase();
    final asNum = int.tryParse(q);
    return surahs.where((s) {
      if (asNum != null && s.number == asNum) return true;
      return s.nameSimple.toLowerCase().contains(q) ||
          s.nameArabic.contains(q) ||
          s.nameTranslation.toLowerCase().contains(q);
    }).toList();
  }
}

