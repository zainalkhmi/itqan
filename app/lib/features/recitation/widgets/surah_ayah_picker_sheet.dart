import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../quran/data/quran_catalog.dart';
import '../../quran/models/ayah.dart';

/// Interactive Surah & Ayah Quick Selector (All 114 Surahs & 6,236 Ayahs)
class SurahAyahPickerSheet extends StatefulWidget {
  final int initialSurahNumber;
  final int initialAyahNumber;
  final Function(int surahNumber, int ayahNumber) onSelected;

  const SurahAyahPickerSheet({
    super.key,
    required this.initialSurahNumber,
    required this.initialAyahNumber,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required int currentSurahNumber,
    required int currentAyahNumber,
    required Function(int surahNumber, int ayahNumber) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? ItqanColors.onyx
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SurahAyahPickerSheet(
        initialSurahNumber: currentSurahNumber,
        initialAyahNumber: currentAyahNumber,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<SurahAyahPickerSheet> createState() => _SurahAyahPickerSheetState();
}

class _SurahAyahPickerSheetState extends State<SurahAyahPickerSheet> {
  late int _selectedSurahNumber;
  late int _selectedAyahNumber;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSurahNumber = widget.initialSurahNumber;
    _selectedAyahNumber = widget.initialAyahNumber;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : ItqanColors.lightTextPrimary;
    final secondaryTextColor = isDark ? ItqanColors.mist : ItqanColors.lightTextSecondary;
    final cardBg = isDark ? ItqanColors.charcoal : ItqanColors.lightBackground;
    final borderColor = isDark ? Colors.white12 : ItqanColors.lightBorder;

    final filteredSurahs = QuranCatalog.search(_searchQuery);
    final selectedSurah = QuranCatalog.getSurah(_selectedSurahNumber);

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: ItqanSpacing.lg, vertical: ItqanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? ItqanColors.slate : ItqanColors.lightDivider,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jump to Any Surah & Ayah',
                      style: ItqanTypography.heading2.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'All 114 Surahs available for recitation practice',
                      style: TextStyle(color: secondaryTextColor, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: ItqanSpacing.md),

            // Search Bar
            TextField(
              controller: _searchCtrl,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search surah by name or number (1-114)...',
                hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: isDark ? ItqanColors.gold : ItqanColors.goldDeep, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: secondaryTextColor, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: cardBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
            const SizedBox(height: ItqanSpacing.md),

            // Selected Surah Ayah Selector Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? ItqanColors.gold : ItqanColors.goldDeep).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? ItqanColors.gold : ItqanColors.goldDeep, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? ItqanColors.gold : ItqanColors.goldDeep,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${selectedSurah.number}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedSurah.nameSimple,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      Text(
                        selectedSurah.nameArabic,
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          color: isDark ? ItqanColors.gold : ItqanColors.goldDeep,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose Ayah (1 - ${selectedSurah.ayahCount}):',
                    style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedSurah.ayahCount,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (ctx, idx) {
                        final ayahNum = idx + 1;
                        final isChosen = _selectedAyahNumber == ayahNum;
                        return ChoiceChip(
                          label: Text('$ayahNum'),
                          selected: isChosen,
                          selectedColor: isDark ? ItqanColors.gold : ItqanColors.goldDeep,
                          labelStyle: TextStyle(
                            color: isChosen ? Colors.white : textColor,
                            fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedAyahNumber = ayahNum);
                            widget.onSelected(_selectedSurahNumber, ayahNum);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ItqanSpacing.md),

            // Surahs List (All 114)
            Text(
              'Select Surah (${filteredSurahs.length} of 114):',
              style: TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                itemCount: filteredSurahs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final s = filteredSurahs[idx];
                  final isSelected = s.number == _selectedSurahNumber;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    tileColor: isSelected ? (isDark ? ItqanColors.charcoal : ItqanColors.lightBackground) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? (isDark ? ItqanColors.gold : ItqanColors.goldDeep) : cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        '${s.number}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : secondaryTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      s.nameSimple,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      '${s.nameTranslation} • ${s.ayahCount} Ayahs',
                      style: TextStyle(color: secondaryTextColor, fontSize: 12),
                    ),
                    trailing: Text(
                      s.nameArabic,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        color: isSelected ? (isDark ? ItqanColors.gold : ItqanColors.goldDeep) : textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedSurahNumber = s.number;
                        _selectedAyahNumber = 1;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: ItqanSpacing.sm),

            // Start Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? ItqanColors.gold : ItqanColors.goldDeep,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.onSelected(_selectedSurahNumber, _selectedAyahNumber);
                Navigator.pop(context);
              },
              child: Text(
                'Start Recitation • ${selectedSurah.nameSimple} : Ayah $_selectedAyahNumber',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

