import '../models/mushaf_layout.dart';
import '../../quran/services/quran_service.dart';
import '../../quran/models/ayah.dart';
import '../mushaf_screen.dart';

class MushafLayoutService {
  static const int kLinesPerPage = 15;

  /// Builds a guaranteed 15-line Mushaf layout from PageData.
  MushafPageLayout buildPageLayout(
    PageData pageData, {
    MushafEdition edition = MushafEdition.madinah15Lines,
    Map<int, Surah>? surahMap,
  }) {
    if (pageData.verses.isEmpty) {
      return MushafPageLayout(
        pageNumber: pageData.pageNumber,
        juzNumber: pageData.juzNumber,
        hizbNumber: pageData.hizbNumber,
        edition: edition,
        lines: List.generate(
          kLinesPerPage,
          (i) => MushafLine(lineNumber: i + 1, lineType: LineType.ayahText, words: []),
        ),
      );
    }

    // Collect all words across all verses on this page
    final allWords = <MushafWordItem>[];
    final surahsStartingOnPage = <int>[];

    for (final verse in pageData.verses) {
      if (verse.isFirstOfSurah || verse.ayahNumber == 1) {
        if (!surahsStartingOnPage.contains(verse.surahNumber)) {
          surahsStartingOnPage.add(verse.surahNumber);
        }
      }

      for (int i = 0; i < verse.words.length; i++) {
        final pw = verse.words[i];
        final isLastWordInVerse = i == verse.words.length - 1;

        allWords.add(MushafWordItem(
          id: pw.id,
          position: pw.position,
          verseKey: verse.verseKey,
          surahNumber: verse.surahNumber,
          ayahNumber: verse.ayahNumber,
          textUthmani: pw.textUthmani,
          transliteration: pw.transliteration,
          translation: pw.translation,
          audioUrl: pw.audioUrl,
          isVerseEnd: pw.isVerseEnd || isLastWordInVerse,
        ));
      }
    }

    // Check if words carry explicit line numbers from QUL / Quran.com (line_number >= 1)
    final explicitLines = <int, List<MushafWordItem>>{};
    bool hasValidLineNumbers = false;

    for (final w in allWords) {
      // Find original PageWord to get its parsed lineNumber
      final verse = pageData.verses.firstWhere(
        (v) => v.verseKey == w.verseKey,
        orElse: () => pageData.verses.first,
      );
      final origWord = verse.words.firstWhere(
        (ow) => ow.id == w.id && ow.position == w.position,
        orElse: () => verse.words.first,
      );

      final line = origWord.lineNumber;
      if (line > 1) {
        hasValidLineNumbers = true;
      }
      explicitLines.putIfAbsent(line, () => []).add(w);
    }

    if (hasValidLineNumbers && explicitLines.keys.any((k) => k > 1 && k <= kLinesPerPage)) {
      return _buildFromExplicitLines(
        pageData: pageData,
        edition: edition,
        explicitLines: explicitLines,
        surahsStartingOnPage: surahsStartingOnPage,
        surahMap: surahMap,
      );
    }

    // Otherwise use calibrated 15-line partitioning algorithm
    return _buildAlgorithmicLayout(
      pageData: pageData,
      edition: edition,
      allWords: allWords,
      surahsStartingOnPage: surahsStartingOnPage,
      surahMap: surahMap,
    );
  }

  MushafPageLayout _buildFromExplicitLines({
    required PageData pageData,
    required MushafEdition edition,
    required Map<int, List<MushafWordItem>> explicitLines,
    required List<int> surahsStartingOnPage,
    Map<int, Surah>? surahMap,
  }) {
    final resultLines = <MushafLine>[];

    // Determine occupied lines by words
    final occupiedLineNumbers = explicitLines.keys.toSet();

    int nextSurahIdx = 0;

    for (int lineNum = 1; lineNum <= kLinesPerPage; lineNum++) {
      if (occupiedLineNumbers.contains(lineNum) && explicitLines[lineNum]!.isNotEmpty) {
        resultLines.add(MushafLine(
          lineNumber: lineNum,
          lineType: LineType.ayahText,
          words: explicitLines[lineNum]!,
        ));
      } else {
        // Line is vacant: check if it should be Surah Header or Basmallah
        if (nextSurahIdx < surahsStartingOnPage.length) {
          final surahNum = surahsStartingOnPage[nextSurahIdx];
          final surah = surahMap?[surahNum];

          // Check if previous line was already a header for this surah
          final prevWasHeader = resultLines.isNotEmpty &&
              resultLines.last.isHeader &&
              resultLines.last.surahNumber == surahNum;

          if (!prevWasHeader) {
            // Create Surah Header line
            resultLines.add(MushafLine(
              lineNumber: lineNum,
              lineType: LineType.surahHeader,
              isCentered: true,
              surahNumber: surahNum,
              surahNameArabic: surah?.nameArabic ?? 'سورة $surahNum',
              surahNameSimple: surah?.nameSimple ?? 'Surah $surahNum',
              revelationPlace: surah?.revelationPlace ?? 'makkah',
              ayahCount: surah?.ayahCount ?? 0,
            ));
            if (surahNum == 9 || surahNum == 1) {
              nextSurahIdx++; // Surah 9 (no Basmallah) & Surah 1 (Basmallah is ayah 1)
            }
          } else {
            // Create Basmallah line
            resultLines.add(MushafLine(
              lineNumber: lineNum,
              lineType: LineType.basmallah,
              isCentered: true,
              surahNumber: surahNum,
            ));
            nextSurahIdx++;
          }
        } else {
          // Empty padding line
          resultLines.add(MushafLine(
            lineNumber: lineNum,
            lineType: LineType.ayahText,
            words: [],
          ));
        }
      }
    }

    return MushafPageLayout(
      pageNumber: pageData.pageNumber,
      juzNumber: pageData.juzNumber,
      hizbNumber: pageData.hizbNumber,
      edition: edition,
      lines: resultLines.take(kLinesPerPage).toList(),
    );
  }

  MushafPageLayout _buildAlgorithmicLayout({
    required PageData pageData,
    required MushafEdition edition,
    required List<MushafWordItem> allWords,
    required List<int> surahsStartingOnPage,
    Map<int, Surah>? surahMap,
  }) {
    final resultLines = <MushafLine>[];

    // Calculate how many lines will be consumed by headers & basmallahs
    int headerLinesCount = 0;
    for (final sNum in surahsStartingOnPage) {
      if (sNum == 9 || sNum == 1) {
        headerLinesCount += 1; // Only header
      } else {
        headerLinesCount += 2; // Header + Basmallah
      }
    }

    final availableAyahLines = (kLinesPerPage - headerLinesCount).clamp(1, kLinesPerPage);

    // Partition allWords across availableAyahLines
    final partitionedWordLines = _partitionWordsEvenly(allWords, availableAyahLines);

    int currentLine = 1;
    int wordLineIdx = 0;

    for (final sNum in surahsStartingOnPage) {
      final surah = surahMap?[sNum];

      // Surah Header
      if (currentLine <= kLinesPerPage) {
        resultLines.add(MushafLine(
          lineNumber: currentLine++,
          lineType: LineType.surahHeader,
          isCentered: true,
          surahNumber: sNum,
          surahNameArabic: surah?.nameArabic ?? 'سورة $sNum',
          surahNameSimple: surah?.nameSimple ?? 'Surah $sNum',
          revelationPlace: surah?.revelationPlace ?? 'makkah',
          ayahCount: surah?.ayahCount ?? 0,
        ));
      }

      // Basmallah
      if (sNum != 9 && sNum != 1 && currentLine <= kLinesPerPage) {
        resultLines.add(MushafLine(
          lineNumber: currentLine++,
          lineType: LineType.basmallah,
          isCentered: true,
          surahNumber: sNum,
        ));
      }
    }

    // Add remaining ayah lines
    while (currentLine <= kLinesPerPage) {
      final wordsForLine = (wordLineIdx < partitionedWordLines.length)
          ? partitionedWordLines[wordLineIdx++]
          : <MushafWordItem>[];

      resultLines.add(MushafLine(
        lineNumber: currentLine++,
        lineType: LineType.ayahText,
        words: wordsForLine,
      ));
    }

    return MushafPageLayout(
      pageNumber: pageData.pageNumber,
      juzNumber: pageData.juzNumber,
      hizbNumber: pageData.hizbNumber,
      edition: edition,
      lines: resultLines,
    );
  }

  List<List<MushafWordItem>> _partitionWordsEvenly(
    List<MushafWordItem> words,
    int targetLineCount,
  ) {
    if (words.isEmpty) {
      return List.generate(targetLineCount, (_) => []);
    }
    if (targetLineCount <= 1) {
      return [words];
    }

    final result = <List<MushafWordItem>>[];
    final wordsPerLine = (words.length / targetLineCount).ceil();

    int start = 0;
    for (int i = 0; i < targetLineCount; i++) {
      if (start >= words.length) {
        result.add([]);
        continue;
      }

      int end = (start + wordsPerLine).clamp(0, words.length);

      // If this is the last line, include all remaining words
      if (i == targetLineCount - 1) {
        end = words.length;
      } else {
        // Try not to cut mid-verse if close to verse end
        for (int lookAhead = end; lookAhead <= (end + 2).clamp(0, words.length); lookAhead++) {
          if (lookAhead > start && lookAhead <= words.length && words[lookAhead - 1].isVerseEnd) {
            end = lookAhead;
            break;
          }
        }
      }

      result.add(words.sublist(start, end));
      start = end;
    }

    return result;
  }

  static String toArabicNumerals(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? digits[d] : c;
    }).join();
  }
}
