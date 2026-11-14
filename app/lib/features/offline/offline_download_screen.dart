import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../quran/data/quran_catalog.dart';
import '../quran/models/ayah.dart';
import 'services/audio_download_service.dart';
import 'services/offline_quran_service.dart';

class OfflineDownloadScreen extends ConsumerStatefulWidget {
  const OfflineDownloadScreen({super.key});

  @override
  ConsumerState<OfflineDownloadScreen> createState() => _OfflineDownloadScreenState();
}

class _OfflineDownloadScreenState extends ConsumerState<OfflineDownloadScreen> {
  final AudioDownloadService _audioService = AudioDownloadService();
  final OfflineQuranService _quranService = OfflineQuranService();

  int _storageBytes = 0;
  int _cachedSurahCount = 0;
  bool _isLoadingStats = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'downloaded', 'juz30'

  bool _isBatchAudioDownloading = false;
  double _batchAudioProgress = 0.0;
  String _batchAudioStatus = '';

  @override
  void initState() {
    super.initState();
    _initAndRefresh();
  }

  Future<void> _initAndRefresh() async {
    setState(() => _isLoadingStats = true);
    await _audioService.init();
    final bytes = await _audioService.getTotalAudioStorageBytes();
    final surahs = await _quranService.getOfflineSurahCount();

    if (mounted) {
      setState(() {
        _storageBytes = bytes;
        _cachedSurahCount = surahs;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _downloadSurahAudio(int surahNumber) async {
    setState(() {}); // trigger rebuild to show downloading spinner
    final surahName = QuranCatalog.getSurah(surahNumber).nameSimple;
    final success = await _audioService.downloadSurah(
      surahNumber,
      onProgress: (done, total, progress) {
        if (mounted) setState(() {});
      },
    );

    await _initAndRefresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Surah $surahName audio downloaded!'
                : 'Failed downloading Surah $surahName audio',
          ),
          backgroundColor: success ? ItqanColors.correct : ItqanColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteSurahAudio(int surahNumber) async {
    final surahName = QuranCatalog.getSurah(surahNumber).nameSimple;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: const Text('Delete Audio', style: ItqanTypography.heading2),
        content: Text(
          'Delete offline recitation audio for Surah $surahName? You can re-download anytime.',
          style: ItqanTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: ItqanColors.mist)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ItqanColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _audioService.deleteSurahAudio(surahNumber);
      await _initAndRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted audio for Surah $surahName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _downloadJuzAmmaAudio() async {
    if (_isBatchAudioDownloading) return;
    setState(() {
      _isBatchAudioDownloading = true;
      _batchAudioProgress = 0.0;
      _batchAudioStatus = 'Starting Juz \'Amma audio download...';
    });

    // Juz 30 is Surahs 78 to 114 (37 surahs total)
    const startSurah = 78;
    const endSurah = 114;
    const totalSurahs = endSurah - startSurah + 1;
    int completed = 0;

    for (int s = startSurah; s <= endSurah; s++) {
      if (!_isBatchAudioDownloading) break;
      final sName = QuranCatalog.getSurah(s).nameSimple;
      setState(() {
        _batchAudioStatus = 'Downloading ($completed/$totalSurahs): Surah $sName...';
        _batchAudioProgress = completed / totalSurahs;
      });

      await _audioService.downloadSurah(s);
      completed++;
    }

    setState(() {
      _isBatchAudioDownloading = false;
      _batchAudioProgress = 1.0;
      _batchAudioStatus = 'Juz \'Amma download complete!';
    });

    await _initAndRefresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Juz \'Amma audio recitations are now ready offline!'),
          backgroundColor: ItqanColors.correct,
        ),
      );
    }
  }

  Future<void> _downloadAllQuranText() async {
    if (_quranService.isDownloading) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting full Quran text download into local cache...')),
    );

    final success = await _quranService.downloadAllQuranText(
      onProgress: (completed, total, progress) {
        if (mounted) setState(() {});
      },
    );

    await _initAndRefresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'All 114 Surahs text cached offline!' : 'Quran text download interrupted.',
          ),
          backgroundColor: success ? ItqanColors.correct : ItqanColors.warning,
        ),
      );
    }
  }

  List<Surah> get _filteredSurahs {
    var list = QuranCatalog.surahs;

    if (_selectedFilter == 'downloaded') {
      list = list.where((s) => _audioService.isSurahAudioDownloaded(s.number)).toList();
    } else if (_selectedFilter == 'juz30') {
      list = list.where((s) => s.number >= 78).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((s) {
        return s.number.toString() == q ||
            s.nameSimple.toLowerCase().contains(q) ||
            s.nameTranslation.toLowerCase().contains(q) ||
            s.nameArabic.contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final primaryTextColor = isDark ? Colors.white : ItqanColors.charcoal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Quran & Audio'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _initAndRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Storage and Batch Actions Card
          Padding(
            padding: const EdgeInsets.all(ItqanSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(ItqanSpacing.lg),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(ItqanRadius.lg),
                border: Border.all(
                  color: isDark ? ItqanColors.charcoal : ItqanColors.lightBorder,
                ),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ItqanColors.gold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.offline_pin_rounded, color: ItqanColors.gold, size: 24),
                      ),
                      const SizedBox(width: ItqanSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offline Storage Used',
                              style: ItqanTypography.caption.copyWith(color: ItqanColors.mist),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isLoadingStats
                                  ? 'Calculating...'
                                  : AudioDownloadService.formatBytes(_storageBytes),
                              style: ItqanTypography.heading2.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: ItqanColors.correct.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(ItqanRadius.full),
                        ),
                        child: Text(
                          'Text: $_cachedSurahCount/114',
                          style: const TextStyle(
                            color: ItqanColors.correct,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ItqanSpacing.md),

                  // Batch Audio Download Progress if active
                  if (_isBatchAudioDownloading) ...[
                    Text(_batchAudioStatus, style: ItqanTypography.caption),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _batchAudioProgress,
                      backgroundColor: isDark ? ItqanColors.charcoal : ItqanColors.lightBorder,
                      color: ItqanColors.gold,
                    ),
                    const SizedBox(height: ItqanSpacing.sm),
                  ],

                  // Quran Text Download Progress if active
                  if (_quranService.isDownloading) ...[
                    Text(
                      'Downloading Quran Text: ${(_quranService.downloadProgress * 100).toInt()}%',
                      style: ItqanTypography.caption,
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _quranService.downloadProgress,
                      backgroundColor: isDark ? ItqanColors.charcoal : ItqanColors.lightBorder,
                      color: ItqanColors.correct,
                    ),
                    const SizedBox(height: ItqanSpacing.sm),
                  ],

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBatchAudioDownloading ? null : _downloadJuzAmmaAudio,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ItqanColors.gold,
                            side: const BorderSide(color: ItqanColors.gold),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ItqanRadius.md),
                            ),
                          ),
                          icon: const Icon(Icons.audiotrack_rounded, size: 16),
                          label: const Text('Juz \'Amma Audio (~35MB)', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: ItqanSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _quranService.isDownloading ? null : _downloadAllQuranText,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ItqanColors.correct,
                            side: const BorderSide(color: ItqanColors.correct),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ItqanRadius.md),
                            ),
                          ),
                          icon: const Icon(Icons.menu_book_rounded, size: 16),
                          label: const Text('All Quran Text (~2MB)', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search and Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ItqanSpacing.md),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Search Surah name or number...',
                    hintStyle: const TextStyle(color: ItqanColors.mist, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: ItqanColors.mist),
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ItqanRadius.lg),
                      borderSide: BorderSide(color: isDark ? ItqanColors.charcoal : ItqanColors.lightBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ItqanRadius.lg),
                      borderSide: BorderSide(color: isDark ? ItqanColors.charcoal : ItqanColors.lightBorder),
                    ),
                  ),
                ),
                const SizedBox(height: ItqanSpacing.sm),
                Row(
                  children: [
                    _filterChip('All (114)', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('Downloaded', 'downloaded'),
                    const SizedBox(width: 8),
                    _filterChip('Juz \'Amma (37)', 'juz30'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: ItqanSpacing.xs),

          // Surahs List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(ItqanSpacing.md),
              itemCount: _filteredSurahs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final surah = _filteredSurahs[index];
                final isDownloading = _audioService.isSurahDownloading(surah.number);
                final downloadedCount = _audioService.getSurahDownloadedCount(surah.number);
                final isFullyDownloaded = downloadedCount >= surah.ayahCount;
                final progress = _audioService.getSurahProgress(surah.number);

                return Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(ItqanRadius.md),
                    border: Border.all(
                      color: isFullyDownloaded
                          ? ItqanColors.correct.withOpacity(0.3)
                          : (isDark ? ItqanColors.charcoal : ItqanColors.lightBorder),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isFullyDownloaded
                          ? ItqanColors.correct.withOpacity(0.2)
                          : (isDark ? ItqanColors.charcoal : ItqanColors.lightBorder),
                      foregroundColor: isFullyDownloaded ? ItqanColors.correct : primaryTextColor,
                      child: Text(
                        '${surah.number}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          surah.nameSimple,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          surah.nameArabic,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            color: ItqanColors.gold,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${surah.ayahCount} Ayahs • ${surah.nameTranslation}',
                              style: ItqanTypography.caption.copyWith(color: ItqanColors.mist),
                            ),
                            if (isFullyDownloaded) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: ItqanColors.correct.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '✓ Offline',
                                  style: TextStyle(
                                    color: ItqanColors.correct,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else if (downloadedCount > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '$downloadedCount/${surah.ayahCount} audio',
                                style: const TextStyle(color: ItqanColors.warning, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                        if (isDownloading) ...[
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: progress > 0 ? progress : null,
                            color: ItqanColors.gold,
                            backgroundColor: isDark ? ItqanColors.charcoal : ItqanColors.lightBorder,
                          ),
                        ],
                      ],
                    ),
                    trailing: isDownloading
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: ItqanColors.error),
                            tooltip: 'Cancel',
                            onPressed: () {
                              _audioService.cancelDownload(surah.number);
                              setState(() {});
                            },
                          )
                        : isFullyDownloaded
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: ItqanColors.mist),
                                tooltip: 'Delete Offline Audio',
                                onPressed: () => _deleteSurahAudio(surah.number),
                              )
                            : IconButton(
                                icon: const Icon(Icons.download_rounded, color: ItqanColors.gold),
                                tooltip: 'Download Audio',
                                onPressed: () => _downloadSurahAudio(surah.number),
                              ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? ItqanColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(ItqanRadius.full),
          border: Border.all(
            color: isSelected ? ItqanColors.gold : ItqanColors.charcoal,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? ItqanColors.void_ : ItqanColors.mist,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
