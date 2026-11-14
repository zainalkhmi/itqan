import 'package:flutter/material.dart';
import 'package:itqan/core/theme/colors.dart';
import 'package:itqan/core/theme/typography.dart';
import '../models/mushaf_layout.dart';
import '../mushaf_screen.dart';
import '../services/mushaf_layout_service.dart';
import '../../recitation/recitation_screen.dart';
import '../../quran/services/quran_service.dart';
import '../../quran/models/ayah.dart';
import '../../tajweed/services/tajweed_service.dart';

class Mushaf15LineView extends StatefulWidget {
  final MushafPageLayout layout;
  final Map<int, Surah> surahMap;
  final bool isHifzMode;
  final bool showTajweed;
  final Set<String>? mistakeWordKeys;
  final Function(MushafWordItem word)? onWordTap;
  final Function(String verseKey)? onAyahSelected;

  const Mushaf15LineView({
    super.key,
    required this.layout,
    required this.surahMap,
    this.isHifzMode = false,
    this.showTajweed = true,
    this.mistakeWordKeys,
    this.onWordTap,
    this.onAyahSelected,
  });

  @override
  State<Mushaf15LineView> createState() => _Mushaf15LineViewState();
}

class _Mushaf15LineViewState extends State<Mushaf15LineView> {
  final Set<String> _revealedWordKeys = {};

  @override
  void didUpdateWidget(Mushaf15LineView oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final pageNum = widget.layout.pageNumber;
    final juzNum = widget.layout.juzNumber;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? ItqanColors.gold.withValues(alpha: 0.7) : ItqanColors.gold.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? ItqanColors.gold.withValues(alpha: 0.3) : ItqanColors.gold.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            // ── Top Page Header ──────────────────────────────────────────
            _buildPageHeader(juzNum, pageNum),
            const SizedBox(height: 6),
            Divider(color: isDark ? ItqanColors.charcoal : ItqanColors.lightBorder, height: 1),
            const SizedBox(height: 6),

            // ── 15 Fixed Lines ───────────────────────────────────────────
            Expanded(
              child: Column(
                children: widget.layout.lines.map((line) {
                  return Expanded(
                    child: _buildLineWidget(line),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 6),
            Divider(color: isDark ? ItqanColors.charcoal : ItqanColors.lightBorder, height: 1),
            const SizedBox(height: 4),

            // ── Bottom Page Footer ───────────────────────────────────────
            _buildPageFooter(pageNum),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(int juzNum, int pageNum) {
    final firstAyahLine = widget.layout.lines.firstWhere(
      (l) => l.isAyah && l.words.isNotEmpty,
      orElse: () => widget.layout.lines.first,
    );
    final surahNum = firstAyahLine.words.isNotEmpty
        ? firstAyahLine.words.first.surahNumber
        : 1;
    final surah = widget.surahMap[surahNum];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'الجزء ${MushafLayoutService.toArabicNumerals(juzNum)}',
          style: const TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 12,
            color: ItqanColors.gold,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
        Text(
          surah?.nameArabic ?? 'سورة $surahNum',
          style: const TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 13,
            color: ItqanColors.goldLight,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
        Text(
          'ص ${MushafLayoutService.toArabicNumerals(pageNum)}',
          style: const TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 12,
            color: ItqanColors.gold,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildPageFooter(int pageNum) {
    return Center(
      child: Text(
        '— ${MushafLayoutService.toArabicNumerals(pageNum)} —',
        style: const TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 11,
          color: ItqanColors.mist,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildLineWidget(MushafLine line) {
    switch (line.lineType) {
      case LineType.surahHeader:
        return _buildSurahHeader(line);
      case LineType.basmallah:
        return _buildBasmallah(line);
      case LineType.ayahText:
        return _buildAyahLine(line);
    }
  }

  Widget _buildSurahHeader(MushafLine line) {
    final surahNum = line.surahNumber ?? 1;
    final arabicName = line.surahNameArabic ?? 'سورة $surahNum';
    final place = line.revelationPlace == 'makkah' ? 'مكية' : 'مدنية';
    final count = line.ayahCount ?? 0;

    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        decoration: BoxDecoration(
          color: ItqanColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ItqanColors.gold.withValues(alpha: 0.5), width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'اياتها $count',
              style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 10, color: ItqanColors.goldLight),
              textDirection: TextDirection.rtl,
            ),
            Text(
              '۞ $arabicName ۞',
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: ItqanColors.gold,
              ),
              textDirection: TextDirection.rtl,
            ),
            Text(
              place,
              style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 10, color: ItqanColors.goldLight),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasmallah(MushafLine line) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 15,
            color: ItqanColors.gold.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildAyahLine(MushafLine line) {
    if (line.words.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSingleWordOrEnding = line.words.length <= 3;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: isSingleWordOrEnding
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: line.words.map((word) {
            return _buildWordWidget(word);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWordWidget(MushafWordItem word) {
    final key = '${word.verseKey}:${word.position}';
    final isRevealed = !widget.isHifzMode || _revealedWordKeys.contains(key);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultWordColor = isDark ? ItqanColors.snow : ItqanColors.lightTextPrimary;

    final isMistake = widget.mistakeWordKeys != null &&
        (widget.mistakeWordKeys!.contains(word.verseKey) ||
         widget.mistakeWordKeys!.contains(word.location) ||
         widget.mistakeWordKeys!.contains(key));

    final tajweedTokens = widget.showTajweed && isRevealed
        ? TajweedService().detectOfflineTajweed(word.textUthmani)
        : <TajweedToken>[];
    final hasTajweed = tajweedTokens.isNotEmpty;
    final primaryColor = isMistake
        ? ItqanColors.mistakeIncorrect
        : (hasTajweed ? tajweedTokens.first.rule.color : defaultWordColor);

    return GestureDetector(
      onTap: () {
        if (widget.isHifzMode) {
          _toggleWordReveal(word);
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
        padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isMistake
              ? ItqanColors.mistakeIncorrect.withOpacity(0.15)
              : (widget.isHifzMode && !isRevealed
                  ? (isDark ? ItqanColors.charcoal.withValues(alpha: 0.5) : const Color(0xFFF1F5F9))
                  : Colors.transparent),
          border: isMistake ? Border.all(color: ItqanColors.mistakeIncorrect.withOpacity(0.5), width: 1) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isHifzMode && !isRevealed)
                  Text(
                    '····',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ItqanColors.gold.withValues(alpha: 0.4),
                      letterSpacing: 2,
                    ),
                  )
                else
                  Text(
                    word.textUthmani,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 18,
                      height: 1.4,
                      color: primaryColor,
                      fontWeight: (hasTajweed || isMistake) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                if (word.isVerseEnd && (!widget.isHifzMode || isRevealed)) ...[
                  const SizedBox(width: 2),
                  Text(
                    ' \u06DD${MushafLayoutService.toArabicNumerals(word.ayahNumber)} ',
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: ItqanColors.gold,
                    ),
                  ),
                ],
              ],
            ),
            if (hasTajweed || isMistake)
              Container(
                margin: const EdgeInsets.only(top: 1),
                height: 2,
                width: 14,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showWordSheet(MushafWordItem word) {
    final tajweedTokens = TajweedService().detectOfflineTajweed(word.textUthmani);
    TajweedRuleDetails? directRule;
    if (word.tajweedRule != null && word.tajweedRule!.isNotEmpty) {
      directRule = TajweedService().getRuleDetails(word.tajweedRule!);
    }
    final hasTajweed = tajweedTokens.isNotEmpty || directRule != null;
    final primaryColor = directRule?.color ?? (tajweedTokens.isNotEmpty ? tajweedTokens.first.rule.color : ItqanColors.goldLight);

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
      backgroundColor: ItqanColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ayah ${word.verseKey} · Word ${word.position}',
                      style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: ItqanColors.mist, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // QPC V4 & QUL Script Info Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ItqanColors.charcoal,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ItqanColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_stories_rounded, color: ItqanColors.gold, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'QPC V4 Script: ${word.location}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (word.qpcV4Glyph.isNotEmpty)
                        Text(
                          'Glyph: ${word.qpcV4Glyph}',
                          style: const TextStyle(color: ItqanColors.goldLight, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    word.textUthmani,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 34,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                if (hasTajweed) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: ruleList.map((r) {
                      return Chip(
                        backgroundColor: r.color.withValues(alpha: 0.2),
                        side: BorderSide(color: r.color, width: 1),
                        avatar: CircleAvatar(
                          backgroundColor: r.color,
                          radius: 5,
                        ),
                        label: Text(
                          '${r.name} (${r.nameArabic})',
                          style: TextStyle(color: r.color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      ruleList.first.description,
                      style: const TextStyle(color: ItqanColors.mist, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (word.transliteration.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      word.transliteration,
                      style: const TextStyle(color: ItqanColors.slate, fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                if (word.translation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      word.translation,
                      style: const TextStyle(color: ItqanColors.silver, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ItqanColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.mic_rounded, color: ItqanColors.void_, size: 20),
                        label: const Text(
                          'Practice Ayah with AI',
                          style: TextStyle(color: ItqanColors.void_, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openRecitationForAyah(word.verseKey);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
}
