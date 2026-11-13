import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/language_item.dart';

final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});

class TranslationService {
  static const List<LanguageItem> supportedLanguages = [
    LanguageItem(code: 'en', name: 'English', nativeName: 'English', flagEmoji: '🇬🇧'),
    LanguageItem(code: 'ar', name: 'Arabic', nativeName: 'العربية', flagEmoji: '🇸🇦', isRtl: true),
    LanguageItem(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia', flagEmoji: '🇮🇩'),
    LanguageItem(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu', flagEmoji: '🇲🇾'),
    LanguageItem(code: 'ur', name: 'Urdu', nativeName: 'اردو', flagEmoji: '🇵🇰', isRtl: true),
    LanguageItem(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flagEmoji: '🇹🇷'),
    LanguageItem(code: 'fr', name: 'French', nativeName: 'Français', flagEmoji: '🇫🇷'),
    LanguageItem(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flagEmoji: '🇧🇩'),
    LanguageItem(code: 'fa', name: 'Persian', nativeName: 'فارسی', flagEmoji: '🇮🇷', isRtl: true),
    LanguageItem(code: 'ru', name: 'Russian', nativeName: 'Русский', flagEmoji: '🇷🇺'),
    LanguageItem(code: 'de', name: 'German', nativeName: 'Deutsch', flagEmoji: '🇩🇪'),
    LanguageItem(code: 'es', name: 'Spanish', nativeName: 'Español', flagEmoji: '🇪🇸'),
    LanguageItem(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flagEmoji: '🇮🇳'),
    LanguageItem(code: 'zh', name: 'Chinese', nativeName: '中文', flagEmoji: '🇨🇳'),
    LanguageItem(code: 'sw', name: 'Swahili', nativeName: 'Kiswahili', flagEmoji: '🇹🇿'),
    LanguageItem(code: 'ha', name: 'Hausa', nativeName: 'Harshen Hausa', flagEmoji: '🇳🇬'),
    LanguageItem(code: 'ps', name: 'Pashto', nativeName: 'پښتو', flagEmoji: '🇦🇫', isRtl: true),
    LanguageItem(code: 'uz', name: 'Uzbek', nativeName: 'Oʻzbekcha', flagEmoji: '🇺🇿'),
    LanguageItem(code: 'so', name: 'Somali', nativeName: 'Soomaaliga', flagEmoji: '🇸🇴'),
    LanguageItem(code: 'bs', name: 'Bosnian', nativeName: 'Bosanski', flagEmoji: '🇧🇦'),
    LanguageItem(code: 'az', name: 'Azerbaijani', nativeName: 'Azərbaycanca', flagEmoji: '🇦🇿'),
  ];

  static final Map<String, Map<String, String>> _dictionaries = {
    'en': {
      'navHome': 'Home',
      'navQuran': 'Quran',
      'navProgress': 'Progress',
      'navSettings': 'Settings',
      'homeGreeting': 'Assalamu Alaikum',
      'homeSubtitle': 'Master Quran Recitation with AI',
      'homeContinueReading': 'Continue Reading',
      'homePracticeMode': 'Practice & Hifz',
      'qiraatTitle': 'Multiple Qira\'at',
      'communityTitle': 'Community & Halaqah',
      'ijazahTitle': 'Ijazah & Sanad',
      'cloudSyncTitle': 'Cloud Sync',
    },
    'id': {
      'navHome': 'Beranda',
      'navQuran': 'Al-Qur\'an',
      'navProgress': 'Progres',
      'navSettings': 'Pengaturan',
      'homeGreeting': 'Assalamu\'alaikum',
      'homeSubtitle': 'Kuasai Tilawah Al-Qur\'an Bersama AI',
      'homeContinueReading': 'Lanjutkan Membaca',
      'homePracticeMode': 'Latihan & Hafalan',
      'qiraatTitle': 'Qira\'at Bersanad',
      'communityTitle': 'Komunitas & Halaqah',
      'ijazahTitle': 'Ijazah & Sanad',
      'cloudSyncTitle': 'Sinkronisasi Awan',
    },
    'ms': {
      'navHome': 'Utama',
      'navQuran': 'Al-Quran',
      'navProgress': 'Kemajuan',
      'navSettings': 'Tetapan',
      'homeGreeting': 'Assalamu\'alaikum',
      'homeSubtitle': 'Kuasai Bacaan Quran dengan AI',
      'homeContinueReading': 'Sambung Membaca',
      'homePracticeMode': 'Latihan & Hifz',
      'qiraatTitle': 'Pelbagai Qiraat',
      'communityTitle': 'Komuniti & Halaqah',
      'ijazahTitle': 'Ijazah & Sanad',
      'cloudSyncTitle': 'Penyegerakan Awan',
    },
    'tr': {
      'navHome': 'Ana Sayfa',
      'navQuran': 'Kur\'an-ı Kerim',
      'navProgress': 'İlerleme',
      'navSettings': 'Ayarlar',
      'homeGreeting': 'Selamün Aleyküm',
      'homeSubtitle': 'Yapay Zeka ile Kur\'an Tilavetini Geliştirin',
      'homeContinueReading': 'Okumaya Devam Et',
      'homePracticeMode': 'Ezber ve Pratik',
      'qiraatTitle': 'Kıraat Çeşitleri',
      'communityTitle': 'Topluluk & Halka',
      'ijazahTitle': 'İcazet ve İsnad',
      'cloudSyncTitle': 'Bulut Senkronizasyonu',
    },
    'ur': {
      'navHome': 'ہوم',
      'navQuran': 'قرآن مجید',
      'navProgress': 'پیش رفت',
      'navSettings': 'ترتیبات',
      'homeGreeting': 'السلام علیکم',
      'homeSubtitle': 'مصنوعی ذہانت کے ساتھ تلاوتِ قرآن سیکھیں',
      'homeContinueReading': 'پڑھنا جاری رکھیں',
      'homePracticeMode': 'حفظ و مشق',
      'qiraatTitle': 'متعدد قراءات',
      'communityTitle': 'کمیونٹی اور حلقہ',
      'ijazahTitle': 'اجازت اور سند',
      'cloudSyncTitle': 'کلاؤڈ سنک',
    },
    'fr': {
      'navHome': 'Accueil',
      'navQuran': 'Coran',
      'navProgress': 'Progrès',
      'navSettings': 'Paramètres',
      'homeGreeting': 'Assalamou Alaykoum',
      'homeSubtitle': 'Perfectionnez votre récitation avec l\'IA',
      'homeContinueReading': 'Continuer la lecture',
      'homePracticeMode': 'Pratique & Hifz',
      'qiraatTitle': 'Multiples Qira\'at',
      'communityTitle': 'Communauté & Halaqah',
      'ijazahTitle': 'Ijazah & Sanad',
      'cloudSyncTitle': 'Synchronisation Cloud',
    },
    'ar': {
      'navHome': 'الرئيسية',
      'navQuran': 'القرآن الكريم',
      'navProgress': 'التقدم',
      'navSettings': 'الإعدادات',
      'homeGreeting': 'السلام عليكم',
      'homeSubtitle': 'أتقن تلاوة القرآن بالذكاء الاصطناعي',
      'homeContinueReading': 'متابعة القراءة',
      'homePracticeMode': 'التدريب والحفظ',
      'qiraatTitle': 'القراءات المتواترة',
      'communityTitle': 'المجتمع والحلقات',
      'ijazahTitle': 'الإجازة والسند',
      'cloudSyncTitle': 'المزامنة السحابية',
    },
  };

  LanguageItem getLanguage(String code) {
    return supportedLanguages.firstWhere(
      (l) => l.code == code || l.name.toLowerCase() == code.toLowerCase(),
      orElse: () => supportedLanguages.first,
    );
  }

  String translate(String key, String localeCode) {
    final dict = _dictionaries[localeCode] ?? _dictionaries['en']!;
    return dict[key] ?? _dictionaries['en']![key] ?? key;
  }
}
