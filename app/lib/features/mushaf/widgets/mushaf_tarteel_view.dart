import 'package:flutter/material.dart';
import 'package:itqan/core/theme/colors.dart';
import '../models/mushaf_layout.dart';
import '../services/mushaf_layout_service.dart';
import '../../quran/models/ayah.dart';
import '../../quran/services/quran_service.dart';
import '../../recitation/recitation_screen.dart';
import '../../tajweed/services/tajweed_service.dart';

/// Modern, highly readable Tarteel-style Mushaf View
/// Inspired by Tarteel AI Quran: Large legible Arabic typography (26sp+),
/// natural word-wrapping, high-contrast page card, real-time red mistake highlights,
/// green correct highlights, and ornamental ayah end badges.
class TarteelMushafView extends StatefulWidget {
  final MushafPageLayout layout;
  final Map<int, Surah> surahMap;
  final bool isHifzMode;
  final bool showTajweed;
  final Set<String>? mistakeWordKeys;
  final Set<String>? correctWordKeys;
  final String? activeVerseKey;
  final String? activeWordKey;
  final double fontSize;
  final Function(MushafWordItem word)? onWordTap;
  final Function(String verseKey)? onAyahSelected;

  const TarteelMushafView({
    super.key,
    required this.layout,
    required this.surahMap,
    this.isHifzMode = false,
    this.showTajweed = true,
    this.mistakeWordKeys,
    this.correctWordKeys,
    this.activeVerseKey,
    this.activeWordKey,
    this.fontSize = 26.0,
    this.onWordTap,
    this.onAyahSelected,
  });

  @override
  State<TarteelMushafView> createState() => _TarteelMushafViewState();
}

class _TarteelMushafViewState extends State<TarteelMushafView> {
  final Set<String> _revealedWordKeys = {};

  @override
  void didUpdateWidget(TarteelMushafView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isHifzMode && oldWidget.isHifzMode) {
      _revealedWordKeys.clear();
    }
  }

  void _toggleWordReveal(MushafWordItem word) {
    final key = '${word.verseKey}:${word.position}';
    setState(() {
      if (_revealedWordKeys.contains(key)) {
        _revealedWordKeys.remove(key);
      } else {
        _revealedWordKeys.add(key);
      }
    });
  }

  void _openRecitationForAyah(String verseKey) async {
    final parts = verseKey.split(':');
    if (parts.length != 2) return;
    final surahNum = int.tryParse(parts[0]) ?? 1;
    final ayahNum = int.tryParse(parts[1]) ?? 1;

    final service = QuranService();
    await service.init();
    final ayahs = await service.getAyahs(surahNum);
    if (!mounted) return;

    final ayah = ayahs.firstWhere(
      (a) => a.ayahNumber == ayahNum,
      orElse: () => Ayah(
        surahNumber: surahNum,
        ayahNumber: ayahNum,
        textUthmani: '',
        translation: '',
        words: [],
      ),
    );

    final surahName = widget.surahMap[surahNum]?.nameSimple ?? 'Surah $surahNum';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecitationScreen(ayah: ayah, surahName: surahName),
      ),
    );
  }

  void _showWordSheet(MushafWordItem word) {
    final tajweedTokens = TajweedService().detectOfflineTajweed(word.textUthmani);
    TajweedRuleDetails? directRule;
    if (word.tajweedRule.isNotEmpty) {
      directRule = TajweedService().getRuleDetails(word.tajweedRule);
    }
    final hasTajweed = tajweedTokens.isNotEmpty || directRule != null;
    final primaryColor = directRule?.color ??
        (tajweedTokens.isNotEmpty ? tajweedTokens.first.rule.color : ItqanColors.goldLight);

    final ruleList = <TajweedRuleDetails>[];
    if (directRule != null) {
      ruleList.add(directRule);
    }
    for (final token in tajweedTokens) {
      if (!ruleList.any((r) => r.type == token.rule.type)) {
        ruleList.add(token.rule);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? ItqanColors.onyx
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ayah ${word.verseKey} · Word ${word.position}',
                      style: TextStyle(
                        color: isDark ? ItqanColors.gold : const Color(0xFFB45309),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? ItqanColors.mist : Colors.black54, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Center(
                  child: Text(
                    word.textUthmani,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 38,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      height: 1.6,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                if (hasTajweed) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: ruleList.map((r) {
                      return Chip(
                        backgroundColor: r.color.withValues(alpha: 0.15),
                        side: BorderSide(color: r.color, width: 1),
                        avatar: CircleAvatar(backgroundColor: r.color, radius: 5),
                        label: Text(
                          '${r.name} (${r.nameArabic})',
                          style: TextStyle(color: r.color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                if (word.transliteration.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? ItqanColors.charcoal : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transliteration', style: TextStyle(color: isDark ? ItqanColors.mist : Colors.black54, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          word.transliteration,
                          style: TextStyle(
                            color: isDark ? ItqanColors.snow : Colors.black87,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (word.translation.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? ItqanColors.charcoal : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Translation', style: TextStyle(color: isDark ? ItqanColors.mist : Colors.black54, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          word.translation,
                          style: TextStyle(
                            color: isDark ? ItqanColors.snow : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageNum = widget.layout.pageNumber;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build items: headers, basmalahs, and flowing words
    final elements = <Widget>[];

    for (final line in widget.layout.lines) {
      if (line.lineType == LineType.surahHeader) {
        elements.add(_buildTarteelSurahHeader(line, isDark));
      } else if (line.lineType == LineType.basmallah) {
        elements.add(_buildTarteelBasmallah(isDark));
      }
    }

    // Extract all words on the page in reading order
    final allWords = <MushafWordItem>[];
    for (final line in widget.layout.lines) {
      if (line.words.isNotEmpty) {
        allWords.addAll(line.words);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Surah Headers / Basmallah if present on this page
              if (elements.isNotEmpty) ...[
                ...elements,
                const SizedBox(height: 12),
              ],

              // Flowing Arabic Quran text (Tarteel style: Large font, natural wrap)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4.5,
                  runSpacing: 10.0,
                  children: allWords.map((word) => _buildTarteelWordToken(word, isDark)).toList(),
                ),
              ),

              const SizedBox(height: 24),
              Divider(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB), height: 1),
              const SizedBox(height: 8),

              // Page Number Footer (Arabic numerals)
              Center(
                child: Text(
                  '— ${MushafLayoutService.toArabicNumerals(pageNum)} —',
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 13,
                    color: isDark ? ItqanColors.mist : const Color(0xFF9CA3AF),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTarteelSurahHeader(MushafLine line, bool isDark) {
    final surahNum = line.surahNumber ?? 1;
    final arabicName = line.surahNameArabic ?? 'سورة $surahNum';
    final place = line.revelationPlace == 'makkah' ? 'مكية' : 'مدنية';
    final count = line.ayahCount ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFFEF3C7).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD97706).withOpacity(0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'اياتها $count',
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 12,
              color: Color(0xFFD97706),
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
          Text(
            '۞ سُورَةُ $arabicName ۞',
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB45309),
            ),
            textDirection: TextDirection.rtl,
          ),
          Text(
            place,
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 12,
              color: Color(0xFFD97706),
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildTarteelBasmallah(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 20,
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
            fontWeight: FontWeight.bold,
            height: 1.8,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildTarteelWordToken(MushafWordItem word, bool isDark) {
    final key = '${word.verseKey}:${word.position}';
    final locationKey = word.location;
    final isRevealed = !widget.isHifzMode || _revealedWordKeys.contains(key);

    // Mistake detection: vibrant red highlight matching Tarteel screenshot (Image 1)
    final isMistake = widget.mistakeWordKeys != null &&
        (widget.mistakeWordKeys!.contains(key) ||
         widget.mistakeWordKeys!.contains(locationKey));

    // Correct recitation: vibrant emerald green highlight
    final isCorrect = !isMistake && widget.correctWordKeys != null &&
        (widget.correctWordKeys!.contains(key) ||
         widget.correctWordKeys!.contains(locationKey));

    final isActiveAyah = widget.activeVerseKey == word.verseKey;
    final isActiveWord = widget.activeWordKey == key || widget.activeWordKey == locationKey;

    final tajweedTokens = widget.showTajweed && isRevealed
        ? TajweedService().detectOfflineTajweed(word.textUthmani)
        : <TajweedToken>[];
    final hasTajweed = tajweedTokens.isNotEmpty;

    // High contrast colors (Black in light mode, crisp white in dark mode)
    final defaultWordColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);

    final Color primaryColor;
    final Color? tokenBg;
    final Border? tokenBorder;

    if (isMistake) {
      // Coral red highlight matching Image 1
      primaryColor = const Color(0xFFEF4444);
      tokenBg = const Color(0xFFEF4444).withOpacity(0.14);
      tokenBorder = Border.all(color: const Color(0xFFEF4444).withOpacity(0.55), width: 1.0);
    } else if (isCorrect) {
      // Emerald green highlight
      primaryColor = const Color(0xFF10B981);
      tokenBg = const Color(0xFF10B981).withOpacity(0.14);
      tokenBorder = Border.all(color: const Color(0xFF10B981).withOpacity(0.45), width: 1.0);
    } else if (isActiveWord) {
      primaryColor = const Color(0xFFD97706);
      tokenBg = const Color(0xFFD97706).withOpacity(0.18);
      tokenBorder = Border.all(color: const Color(0xFFD97706), width: 1.2);
    } else if (isActiveAyah) {
      primaryColor = defaultWordColor;
      tokenBg = isDark ? const Color(0x333B82F6) : const Color(0x1A3B82F6);
      tokenBorder = null;
    } else if (widget.isHifzMode && !isRevealed) {
      primaryColor = isDark ? ItqanColors.mist : const Color(0xFF9CA3AF);
      tokenBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
      tokenBorder = null;
    } else {
      primaryColor = hasTajweed ? tajweedTokens.first.rule.color : defaultWordColor;
      tokenBg = null;
      tokenBorder = null;
    }

    return GestureDetector(
      onTap: () {
        if (widget.isHifzMode) {
          _toggleWordReveal(word);
        } else if (widget.onWordTap != null) {
          widget.onWordTap!(word);
        } else {
          _showWordSheet(word);
        }
      },
      onLongPress: () {
        if (widget.onAyahSelected != null) {
          widget.onAyahSelected!(word.verseKey);
        } else {
          _openRecitationForAyah(word.verseKey);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 2.0),
        decoration: BoxDecoration(
          color: tokenBg,
          borderRadius: BorderRadius.circular(6),
          border: tokenBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.isHifzMode && !isRevealed)
              Text(
                '····',
                style: TextStyle(
                  fontSize: widget.fontSize * 0.7,
                  fontWeight: FontWeight.bold,
                  color: isDark ? ItqanColors.mist : const Color(0xFF9CA3AF),
                  letterSpacing: 2,
                ),
              )
            else
              Text(
                word.textUthmani,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: widget.fontSize,
                  height: 2.15,
                  color: primaryColor,
                  fontWeight: (hasTajweed || isMistake || isCorrect || isActiveAyah || isActiveWord)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                textDirection: TextDirection.rtl,
              ),

            // Ornamental Ayah End circle badge (Image 1 style: ⑥, ⑦, ⑧)
            if (word.isVerseEnd && (!widget.isHifzMode || isRevealed)) ...[
              const SizedBox(width: 4),
              Container(
                margin: const EdgeInsets.only(left: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? const Color(0xFFD97706) : const Color(0xFFB45309)).withOpacity(0.12),
                  border: Border.all(
                    color: isDark ? const Color(0xFFD97706) : const Color(0xFFB45309),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  MushafLayoutService.toArabicNumerals(word.ayahNumber),
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: widget.fontSize * 0.52,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
