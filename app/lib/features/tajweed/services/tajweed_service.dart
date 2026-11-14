import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/colors.dart';

enum TajweedRuleType {
  ghunnah,
  hamzaWasl,
  idghamGhunnah,
  idghamNoGhunnah,
  idghamShafawi,
  idghamMutaqaribayn,
  ikhfa,
  ikhfaShafawi,
  iqlab,
  lamShamsiyah,
  maddNecessary,
  maddObligatory,
  maddPermissible,
  maddNormal,
  qalqalah,
  silent,
  other,
}

class TajweedRuleDetails {
  final TajweedRuleType type;
  final String rawClass;
  final String name;
  final String nameArabic;
  final Color color;
  final String description;
  final int harakat;

  const TajweedRuleDetails({
    required this.type,
    required this.rawClass,
    required this.name,
    required this.nameArabic,
    required this.color,
    required this.description,
    this.harakat = 2,
  });
}

class QpcV4WordData {
  final int id;
  final String location;
  final String glyph;

  const QpcV4WordData({
    required this.id,
    required this.location,
    required this.glyph,
  });
}

class TajweedService {
  static final TajweedService _instance = TajweedService._internal();
  factory TajweedService() => _instance;
  TajweedService._internal();

  Map<String, dynamic>? _qpcV4Index;
  bool _isInitialized = false;

  /// Canonical Tajweed Rule Mappings according to QUL / Quran.com API standards
  static const Map<String, TajweedRuleDetails> ruleDefinitions = {
    'ghunnah': TajweedRuleDetails(
      type: TajweedRuleType.ghunnah,
      rawClass: 'ghunnah',
      name: 'Ghunnah',
      nameArabic: 'غُنَّة',
      color: Color(0xFFFB923C), // Orange
      description: 'Nasal sound held for 2 counts on Nun or Meem with Shaddah (نّ / مّ).',
      harakat: 2,
    ),
    'ham_wasl': TajweedRuleDetails(
      type: TajweedRuleType.hamzaWasl,
      rawClass: 'ham_wasl',
      name: 'Hamzatul Wasl',
      nameArabic: 'هَمْزَةُ الوَصْل',
      color: Color(0xFF94A3B8), // Muted Gray/Slate
      description: 'Connecting Hamzah (ٱ) dropped in continuous recitation.',
      harakat: 0,
    ),
    'idgham_ghunnah': TajweedRuleDetails(
      type: TajweedRuleType.idghamGhunnah,
      rawClass: 'idgham_ghunnah',
      name: 'Idgham with Ghunnah',
      nameArabic: 'إِدْغَام بِغُنَّة',
      color: Color(0xFF818CF8), // Indigo
      description: 'Merging Nun Sakinah or Tanween into (ي ن م و) with nasal sound.',
      harakat: 2,
    ),
    'idgham_wo_ghunnah': TajweedRuleDetails(
      type: TajweedRuleType.idghamNoGhunnah,
      rawClass: 'idgham_wo_ghunnah',
      name: 'Idgham without Ghunnah',
      nameArabic: 'إِدْغَام بِلا غُنَّة',
      color: Color(0xFF38BDF8), // Light Blue
      description: 'Complete merging into (ل / ر) without nasalization.',
      harakat: 0,
    ),
    'idgham_shafawi': TajweedRuleDetails(
      type: TajweedRuleType.idghamShafawi,
      rawClass: 'idgham_shafawi',
      name: 'Idgham Shafawi (Mimi)',
      nameArabic: 'إِدْغَام شَفَوِي',
      color: Color(0xFF7C3AED), // Violet
      description: 'Merging Meem Sakinah into another Meem (مْ + م) with Ghunnah.',
      harakat: 2,
    ),
    'idgham_mutaqaribayn': TajweedRuleDetails(
      type: TajweedRuleType.idghamMutaqaribayn,
      rawClass: 'idgham_mutaqaribayn',
      name: 'Idgham Mutaqaribayn',
      nameArabic: 'إِدْغَام مُتَقَارِبَيْن',
      color: Color(0xFF0EA5E9), // Sky Blue
      description: 'Merging of letters with close articulation points.',
      harakat: 0,
    ),
    'ikhafa': TajweedRuleDetails(
      type: TajweedRuleType.ikhfa,
      rawClass: 'ikhafa',
      name: 'Ikhfa Haqiqi',
      nameArabic: 'إِخْفَاء حَقِيقِي',
      color: Color(0xFFA78BFA), // Purple
      description: 'Concealing Nun Sakinah or Tanween before 15 specific letters with Ghunnah.',
      harakat: 2,
    ),
    'ikhafa_shafawi': TajweedRuleDetails(
      type: TajweedRuleType.ikhfaShafawi,
      rawClass: 'ikhafa_shafawi',
      name: 'Ikhfa Shafawi',
      nameArabic: 'إِخْفَاء شَفَوِي',
      color: Color(0xFF9333EA), // Deep Purple
      description: 'Concealing Meem Sakinah before Ba (مْ + ب) with Ghunnah.',
      harakat: 2,
    ),
    'iqlab': TajweedRuleDetails(
      type: TajweedRuleType.iqlab,
      rawClass: 'iqlab',
      name: 'Iqlab',
      nameArabic: 'إِقْلاب',
      color: Color(0xFFF472B6), // Pink
      description: 'Converting Nun Sakinah or Tanween into Meem before Ba (ب) with Ghunnah.',
      harakat: 2,
    ),
    'laam_shamsiyah': TajweedRuleDetails(
      type: TajweedRuleType.lamShamsiyah,
      rawClass: 'laam_shamsiyah',
      name: 'Lam Shamsiyah',
      nameArabic: 'لام شَمْسِيَّة',
      color: Color(0xFF64748B), // Slate
      description: 'Solar Lam assimilated into the following sun letter.',
      harakat: 0,
    ),
    'madda_necessary': TajweedRuleDetails(
      type: TajweedRuleType.maddNecessary,
      rawClass: 'madda_necessary',
      name: 'Madd Lazim (Compulsory)',
      nameArabic: 'مَدّ لازِم',
      color: Color(0xFF2563EB), // Deep Royal Blue
      description: 'Compulsory elongation for exactly 6 harakat.',
      harakat: 6,
    ),
    'madda_obligatory': TajweedRuleDetails(
      type: TajweedRuleType.maddObligatory,
      rawClass: 'madda_obligatory',
      name: 'Madd Wajib Muttasil',
      nameArabic: 'مَدّ وَاجِب مُتَّصِل',
      color: Color(0xFF0284C7), // Blue
      description: 'Obligatory elongation for 4–5 harakat when Hamzah is in the same word.',
      harakat: 5,
    ),
    'madda_permissible': TajweedRuleDetails(
      type: TajweedRuleType.maddPermissible,
      rawClass: 'madda_permissible',
      name: 'Madd Ja\'iz / \'Aridh',
      nameArabic: 'مَدّ جَائِز / عَارِض',
      color: Color(0xFF06B6D4), // Cyan
      description: 'Permissible elongation for 2, 4, or 6 harakat.',
      harakat: 4,
    ),
    'madda_normal': TajweedRuleDetails(
      type: TajweedRuleType.maddNormal,
      rawClass: 'madda_normal',
      name: 'Madd Thabi\'i (Normal)',
      nameArabic: 'مَدّ طَبِيعِي',
      color: Color(0xFF38BDF8), // Light Cyan
      description: 'Natural elongation for 2 harakat (Alif, Waw, Ya).',
      harakat: 2,
    ),
    'qalaqah': TajweedRuleDetails(
      type: TajweedRuleType.qalqalah,
      rawClass: 'qalaqah',
      name: 'Qalqalah',
      nameArabic: 'قَلْقَلَة',
      color: Color(0xFFFBBF24), // Amber / Gold
      description: 'Echoing or bouncing sound produced on (ق ط ب ج د) with Sukun or at stop.',
      harakat: 0,
    ),
    'slnt': TajweedRuleDetails(
      type: TajweedRuleType.silent,
      rawClass: 'slnt',
      name: 'Silent Letter',
      nameArabic: 'حَرْف سَاقِط',
      color: Color(0xFF475569), // Dark Gray
      description: 'Unpronounced orthographic letter.',
      harakat: 0,
    ),
  };

  /// Initializes QPC V4 script mapping from local asset
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/qpc-v4.json');
      _qpcV4Index = jsonDecode(jsonString) as Map<String, dynamic>;
      _isInitialized = true;
    } catch (_) {
      // In tests or if asset not yet bundled, fallback gracefully
      _qpcV4Index = {};
      _isInitialized = true;
    }
  }

  @visibleForTesting
  void setIndexForTesting(Map<String, dynamic> index) {
    _qpcV4Index = index;
    _isInitialized = true;
  }

  /// Looks up QPC V4 word metadata by location key (e.g. '1:1:1')
  QpcV4WordData? getQpcV4Word(String location) {
    if (_qpcV4Index == null || !_qpcV4Index!.containsKey(location)) {
      return null;
    }
    final entry = _qpcV4Index![location] as Map<String, dynamic>;
    return QpcV4WordData(
      id: entry['id'] as int? ?? 0,
      location: location,
      glyph: entry['glyph'] as String? ?? '',
    );
  }

  /// Parses text with embedded `<tajweed class=...>` tags into styled TextSpans
  List<InlineSpan> parseTajweedSpans(
    String tajweedHtml, {
    TextStyle? defaultStyle,
    Function(TajweedRuleDetails rule, String text)? onTajweedTap,
  }) {
    final style = defaultStyle ??
        const TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 22,
          color: ItqanColors.snow,
          height: 2.0,
        );

    if (tajweedHtml.isEmpty) {
      return [TextSpan(text: '', style: style)];
    }

    // Strip <span class=end>...</span> for verse numbers if present
    final cleaned = tajweedHtml.replaceAll(RegExp(r'<span class=end>.*?</span>'), '');

    final spans = <InlineSpan>[];
    final tagRegex = RegExp(r'<tajweed class=([a-zA-Z0-9_]+)>(.*?)</tajweed>');

    int lastIndex = 0;
    for (final match in tagRegex.allMatches(cleaned)) {
      if (match.start > lastIndex) {
        final untaggedText = cleaned.substring(lastIndex, match.start);
        spans.add(TextSpan(text: untaggedText, style: style));
      }

      final className = match.group(1) ?? '';
      final taggedText = match.group(2) ?? '';
      final rule = getRuleDetails(className);

      spans.add(TextSpan(
        text: taggedText,
        style: style.copyWith(
          color: rule.color,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < cleaned.length) {
      spans.add(TextSpan(text: cleaned.substring(lastIndex), style: style));
    }

    return spans;
  }

  /// Fallback offline tajweed detector on raw Arabic text
  List<TajweedToken> detectOfflineTajweed(String text) {
    final tokens = <TajweedToken>[];
    if (text.isEmpty) return tokens;

    // Detect Ghunnah: Nun or Meem followed by Shaddah
    final ghunnahRegex = RegExp(r'([نم]ّ)');
    for (final m in ghunnahRegex.allMatches(text)) {
      tokens.add(TajweedToken(
        start: m.start,
        end: m.end,
        text: m.group(1)!,
        rule: ruleDefinitions['ghunnah']!,
      ));
    }

    // Detect Qalqalah: قطبجد with sukun
    final qalqalahRegex = RegExp(r'([قطبجد]ْ)');
    for (final m in qalqalahRegex.allMatches(text)) {
      tokens.add(TajweedToken(
        start: m.start,
        end: m.end,
        text: m.group(1)!,
        rule: ruleDefinitions['qalaqah']!,
      ));
    }

    // Detect Madd with Madda symbol (ـٓ, ٓ)
    final maddRegex = RegExp(r'([اوي]ٓ|ـٰٓ|آ)');
    for (final m in maddRegex.allMatches(text)) {
      tokens.add(TajweedToken(
        start: m.start,
        end: m.end,
        text: m.group(1)!,
        rule: ruleDefinitions['madda_obligatory']!,
      ));
    }

    return tokens;
  }

  /// Retrieves details for a given tajweed class string
  TajweedRuleDetails getRuleDetails(String className) {
    if (ruleDefinitions.containsKey(className)) {
      return ruleDefinitions[className]!;
    }
    return TajweedRuleDetails(
      type: TajweedRuleType.other,
      rawClass: className,
      name: className,
      nameArabic: 'تجويد',
      color: ItqanColors.gold,
      description: 'Tajweed pronunciation rule.',
    );
  }
}

class TajweedToken {
  final int start;
  final int end;
  final String text;
  final TajweedRuleDetails rule;

  const TajweedToken({
    required this.start,
    required this.end,
    required this.text,
    required this.rule,
  });
}
