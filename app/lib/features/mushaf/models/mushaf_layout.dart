import '../mushaf_screen.dart';

enum MushafEdition {
  madinah15Lines,
  indopak15Lines,
}

enum LineType {
  ayahText,
  surahHeader,
  basmallah,
}

class MushafWordItem {
  final int id;
  final int position;
  final String verseKey;
  final int surahNumber;
  final int ayahNumber;
  final String textUthmani;
  final String transliteration;
  final String translation;
  final String audioUrl;
  final bool isVerseEnd;

  const MushafWordItem({
    this.id = 0,
    this.position = 0,
    required this.verseKey,
    required this.surahNumber,
    required this.ayahNumber,
    required this.textUthmani,
    this.transliteration = '',
    this.translation = '',
    this.audioUrl = '',
    this.isVerseEnd = false,
  });

  String get fullAudioUrl {
    if (audioUrl.isEmpty) return '';
    if (audioUrl.startsWith('http://') || audioUrl.startsWith('https://')) {
      return audioUrl;
    }
    return 'https://audio.qurancdn.com/$audioUrl';
  }
}

class MushafLine {
  final int lineNumber; // 1 to 15
  final LineType lineType;
  final bool isCentered;
  final int? surahNumber;
  final String? surahNameArabic;
  final String? surahNameSimple;
  final String? revelationPlace;
  final int? ayahCount;
  final List<MushafWordItem> words;

  const MushafLine({
    required this.lineNumber,
    required this.lineType,
    this.isCentered = false,
    this.surahNumber,
    this.surahNameArabic,
    this.surahNameSimple,
    this.revelationPlace,
    this.ayahCount,
    this.words = const [],
  });

  bool get isHeader => lineType == LineType.surahHeader;
  bool get isBasmallah => lineType == LineType.basmallah;
  bool get isAyah => lineType == LineType.ayahText;

  Set<String> get verseKeys =>
      words.map((w) => w.verseKey).where((k) => k.isNotEmpty).toSet();
}

class MushafPageLayout {
  final int pageNumber; // 1 to 604
  final int juzNumber;
  final int hizbNumber;
  final MushafEdition edition;
  final List<MushafLine> lines; // Exactly 15 lines

  const MushafPageLayout({
    required this.pageNumber,
    required this.juzNumber,
    required this.hizbNumber,
    required this.edition,
    required this.lines,
  });

  int get lineCount => lines.length;
}
