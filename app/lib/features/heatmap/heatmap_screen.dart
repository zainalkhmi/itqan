import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../quran/models/ayah.dart';
import '../recitation/recitation_screen.dart';
import '../memorization/murajaah_screen.dart';
import 'models/surah_heatmap_item.dart';
import 'services/heatmap_service.dart';

enum HeatmapFilter { all, juzAmma, needsReview, juzRest }

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  HeatmapFilter _filter = HeatmapFilter.all;
  List<SurahHeatmapItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHeatmap();
  }

  Future<void> _loadHeatmap() async {
    final service = ref.read(heatmapServiceProvider);
    final items = await service.getHeatmapItems();
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(MemorizationStatus status) {
    switch (status) {
      case MemorizationStatus.mutqin:
        return const Color(0xFF10B981); // Emerald
      case MemorizationStatus.strong:
        return const Color(0xFF34D399); // Mint
      case MemorizationStatus.review:
        return const Color(0xFFFBBF24); // Amber
      case MemorizationStatus.weak:
        return const Color(0xFFF43F5E); // Rose
      case MemorizationStatus.untested:
        return ItqanColors.charcoal;
    }
  }

  String _getStatusLabel(MemorizationStatus status) {
    switch (status) {
      case MemorizationStatus.mutqin:
        return 'Mutqin (≥90%)';
      case MemorizationStatus.strong:
        return 'Strong (80–89%)';
      case MemorizationStatus.review:
        return 'Review (70–79%)';
      case MemorizationStatus.weak:
        return 'Weak (<70%)';
      case MemorizationStatus.untested:
        return 'Untested';
    }
  }

  List<SurahHeatmapItem> _getFilteredItems() {
    switch (_filter) {
      case HeatmapFilter.all:
        return _items;
      case HeatmapFilter.juzAmma:
        return _items.where((s) => s.juzNumber == 30).toList();
      case HeatmapFilter.needsReview:
        return _items.where((s) => s.status == MemorizationStatus.review || s.status == MemorizationStatus.weak).toList();
      case HeatmapFilter.juzRest:
        return _items.where((s) => s.juzNumber < 30).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(heatmapServiceProvider);
    final stats = service.computeStats(_items);
    final filtered = _getFilteredItems();

    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        backgroundColor: ItqanColors.void_,
        title: const Text('Quran Memorization Heatmap', style: ItqanTypography.heading2),
        actions: [
          IconButton(
            tooltip: 'Muraja\'ah Scheduler',
            icon: const Icon(Icons.psychology_rounded, color: ItqanColors.gold),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const MurajaahScreen(),
              ));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ItqanColors.gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: ItqanSpacing.md, vertical: ItqanSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Stats Summary
                  _buildSummaryHeader(stats),
                  const SizedBox(height: ItqanSpacing.md),

                  // Legend
                  _buildLegend(),
                  const SizedBox(height: ItqanSpacing.md),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All 114 Surahs', HeatmapFilter.all),
                        const SizedBox(width: 8),
                        _filterChip('Juz \'Amma (30)', HeatmapFilter.juzAmma),
                        const SizedBox(width: 8),
                        _filterChip('Needs Review (${stats["reviewSurahsCount"] + stats["weakSurahsCount"]})', HeatmapFilter.needsReview),
                        const SizedBox(width: 8),
                        _filterChip('Juz 1–29', HeatmapFilter.juzRest),
                      ],
                    ),
                  ),
                  const SizedBox(height: ItqanSpacing.md),

                  // Heatmap Matrix Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final surah = filtered[index];
                      return _buildSurahCell(surah);
                    },
                  ),
                  const SizedBox(height: ItqanSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryHeader(Map<String, dynamic> stats) {
    final progress = stats['progressPct'] as double? ?? 0.0;
    final mastered = stats['totalMastered'] as int? ?? 0;
    final total = stats['totalQuranAyahs'] as int? ?? 6236;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      decoration: BoxDecoration(
        color: ItqanColors.onyx,
        borderRadius: BorderRadius.circular(ItqanRadius.lg),
        border: Border.all(color: ItqanColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Quran Hifz Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('$mastered of $total Ayahs Mutqin', style: ItqanTypography.caption),
                ],
              ),
              Text(
                '${progress.toStringAsFixed(1)}%',
                style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (progress / 100.0).clamp(0.0, 1.0),
              backgroundColor: ItqanColors.charcoal,
              valueColor: const AlwaysStoppedAnimation<Color>(ItqanColors.gold),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ItqanColors.onyx,
        borderRadius: BorderRadius.circular(ItqanRadius.md),
        border: Border.all(color: ItqanColors.charcoal),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: MemorizationStatus.values.map((st) {
          final color = _getStatusColor(st);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 4),
              Text(_getStatusLabel(st), style: const TextStyle(color: ItqanColors.mist, fontSize: 11)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _filterChip(String label, HeatmapFilter filter) {
    final isSelected = _filter == filter;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(color: isSelected ? ItqanColors.void_ : Colors.white70, fontSize: 12)),
      selectedColor: ItqanColors.gold,
      backgroundColor: ItqanColors.onyx,
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  Widget _buildSurahCell(SurahHeatmapItem surah) {
    final color = _getStatusColor(surah.status);
    final isTested = surah.status != MemorizationStatus.untested;

    return InkWell(
      onTap: () => _showSurahDetails(surah),
      borderRadius: BorderRadius.circular(ItqanRadius.md),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ItqanColors.onyx,
          borderRadius: BorderRadius.circular(ItqanRadius.md),
          border: Border.all(
            color: color.withValues(alpha: isTested ? 0.8 : 0.25),
            width: isTested ? 1.5 : 1.0,
          ),
          boxShadow: isTested
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Text('${surah.surahNumber}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Text(
                  isTested ? '${surah.retentionScore.round()}%' : 'J${surah.juzNumber}',
                  style: TextStyle(
                    color: isTested ? color : ItqanColors.mist,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              surah.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${surah.totalAyahs}v', style: const TextStyle(color: ItqanColors.mist, fontSize: 10)),
                Text(
                  surah.arabicName,
                  style: const TextStyle(fontFamily: 'NotoNaskhArabic', color: ItqanColors.gold, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSurahDetails(SurahHeatmapItem surah) {
    final color = _getStatusColor(surah.status);

    showModalBottomSheet(
      context: context,
      backgroundColor: ItqanColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ItqanRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(ItqanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${surah.name} (${surah.arabicName})',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text('Surah ${surah.surahNumber} • Juz ${surah.juzNumber} • ${surah.totalAyahs} Verses', style: ItqanTypography.caption),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    _getStatusLabel(surah.status),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ItqanSpacing.md),
            const Divider(color: ItqanColors.charcoal),
            const SizedBox(height: ItqanSpacing.sm),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricTile('Retention', '${surah.retentionScore.toStringAsFixed(1)}%', color),
                _metricTile('Tested', '${surah.testedAyahs}/${surah.totalAyahs}', Colors.white),
                _metricTile('Mastered', '${surah.masteredAyahs}', const Color(0xFF10B981)),
                _metricTile('Weak', '${surah.weakAyahs}', const Color(0xFFF43F5E)),
              ],
            ),
            const SizedBox(height: ItqanSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ItqanColors.gold,
                      foregroundColor: ItqanColors.void_,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.psychology_rounded, size: 18),
                    label: const Text('Muraja\'ah Session', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const MurajaahScreen(),
                      ));
                    },
                  ),
                ),
                const SizedBox(width: ItqanSpacing.sm),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ItqanColors.gold),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  icon: const Icon(Icons.mic_rounded, color: ItqanColors.gold, size: 18),
                  label: const Text('Practice Surah', style: TextStyle(color: ItqanColors.gold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    final ayah = Ayah(
                      surahNumber: surah.surahNumber,
                      ayahNumber: 1,
                      textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                      words: [],
                      translation: 'In the name of Allah, the Entirely Merciful, the Especially Merciful',
                    );
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => RecitationScreen(ayah: ayah, surahName: surah.name),
                    ));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: ItqanColors.mist, fontSize: 11)),
      ],
    );
  }
}

