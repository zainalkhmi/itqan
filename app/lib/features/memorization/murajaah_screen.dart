import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../quran/models/ayah.dart';
import '../quran/services/quran_service.dart';
import '../recitation/recitation_screen.dart';
import 'models/srs_card.dart';
import 'services/srs_service.dart';

class MurajaahScreen extends ConsumerStatefulWidget {
  const MurajaahScreen({super.key});

  @override
  ConsumerState<MurajaahScreen> createState() => _MurajaahScreenState();
}

class _MurajaahScreenState extends ConsumerState<MurajaahScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SrsService _srsService = SrsService();
  bool _isLoading = true;
  List<SrsCard> _allCards = [];
  List<SrsCard> _dueCards = [];
  List<SrsCard> _focusCards = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _srsService.init();
    final all = _srsService.getAllCards();
    final due = _srsService.getDueCards();
    final focus = _srsService.getNeedsFocusCards();
    final stats = _srsService.getStats();

    if (mounted) {
      setState(() {
        _allCards = all;
        _dueCards = due;
        _focusCards = focus;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _startRecitation(SrsCard card) async {
    final quranService = QuranService();
    await quranService.init();
    final ayahs = await quranService.getAyahs(card.surahNumber);
    final ayah = ayahs.firstWhere(
      (a) => a.ayahNumber == card.ayahNumber,
      orElse: () => Ayah(
        surahNumber: card.surahNumber,
        ayahNumber: card.ayahNumber,
        textUthmani: card.textUthmani,
        words: [],
        translation: '',
      ),
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecitationScreen(
          ayah: ayah,
          surahName: card.surahName,
          initialHifzMode: HifzMode.blank,
        ),
      ),
    );

    _loadData();
  }

  void _showAddAyahDialog() {
    int selectedSurah = 1;
    int selectedAyah = 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: ItqanColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ItqanRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(ItqanSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add to Muraja\'ah', style: ItqanTypography.heading2),
                  IconButton(
                    icon: const Icon(Icons.close, color: ItqanColors.mist),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: ItqanSpacing.md),
              const Text('Surah Number (1-114):', style: ItqanTypography.caption),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: selectedSurah,
                dropdownColor: ItqanColors.onyx,
                items: [
                  const DropdownMenuItem(value: 1, child: Text('1. Al-Fatiha', style: TextStyle(color: Colors.white))),
                  const DropdownMenuItem(value: 112, child: Text('112. Al-Ikhlas', style: TextStyle(color: Colors.white))),
                  const DropdownMenuItem(value: 113, child: Text('113. Al-Falaq', style: TextStyle(color: Colors.white))),
                  const DropdownMenuItem(value: 114, child: Text('114. An-Nas', style: TextStyle(color: Colors.white))),
                  const DropdownMenuItem(value: 108, child: Text('108. Al-Kawthar', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setModalState(() => selectedSurah = v ?? 1),
                decoration: InputDecoration(
                  fillColor: ItqanColors.charcoal,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(ItqanRadius.md)),
                ),
              ),
              const SizedBox(height: ItqanSpacing.md),
              Text('Ayah Number: $selectedAyah', style: ItqanTypography.caption),
              Slider(
                value: selectedAyah.toDouble(),
                min: 1,
                max: selectedSurah == 1 ? 7 : (selectedSurah == 112 ? 4 : 6),
                divisions: selectedSurah == 1 ? 6 : (selectedSurah == 112 ? 3 : 5),
                activeColor: ItqanColors.gold,
                inactiveColor: ItqanColors.charcoal,
                onChanged: (v) => setModalState(() => selectedAyah = v.round()),
              ),
              const SizedBox(height: ItqanSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final quranService = QuranService();
                    await quranService.init();
                    final ayahs = await quranService.getAyahs(selectedSurah);
                    final ayah = ayahs.firstWhere(
                      (a) => a.ayahNumber == selectedAyah,
                      orElse: () => ayahs.first,
                    );
                    final newCard = SrsCard(
                      id: '${selectedSurah}_$selectedAyah',
                      surahNumber: selectedSurah,
                      ayahNumber: selectedAyah,
                      surahName: 'Surah $selectedSurah',
                      textUthmani: ayah.textUthmani,
                      nextReviewDate: DateTime.now(),
                    );
                    await _srsService.saveCard(newCard);
                    _loadData();
                  },
                  icon: const Icon(Icons.add_task_rounded, color: ItqanColors.void_),
                  label: const Text('Add to Memorization Schedule', style: TextStyle(color: ItqanColors.void_, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ItqanColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ItqanRadius.full)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        backgroundColor: ItqanColors.void_,
        title: const Text('Muraja\'ah (SRS)', style: ItqanTypography.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ItqanColors.gold),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ItqanColors.gold,
        foregroundColor: ItqanColors.void_,
        icon: const Icon(Icons.add),
        label: const Text('Add Ayah', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showAddAyahDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ItqanColors.gold))
          : Column(
              children: [
                // Top Statistics Dashboard Card
                _DashboardStatsCard(stats: _stats),

                // Spaced Repetition Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: ItqanColors.gold,
                  labelColor: ItqanColors.gold,
                  unselectedLabelColor: ItqanColors.mist,
                  tabs: [
                    Tab(text: 'Due Today (${_dueCards.length})'),
                    Tab(text: 'All Cards (${_allCards.length})'),
                    Tab(text: 'Needs Focus (${_focusCards.length})'),
                  ],
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _CardListView(
                        cards: _dueCards,
                        emptyMessage: '🎉 All reviews completed for today!\nKeep up your consistency tomorrow.',
                        onRecite: _startRecitation,
                      ),
                      _CardListView(
                        cards: _allCards,
                        emptyMessage: 'No memorization cards added yet.',
                        onRecite: _startRecitation,
                      ),
                      _CardListView(
                        cards: _focusCards,
                        emptyMessage: 'No ayahs with frequent mistakes.\nGreat Tajweed mastery!',
                        onRecite: _startRecitation,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DashboardStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _DashboardStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final due = stats['dueToday'] ?? 0;
    final mastered = stats['mastered'] ?? 0;
    final retention = stats['averageRetention'] ?? 100.0;
    final streak = stats['currentStreakDays'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(ItqanSpacing.md),
      padding: const EdgeInsets.all(ItqanSpacing.md),
      decoration: BoxDecoration(
        color: ItqanColors.onyx,
        borderRadius: BorderRadius.circular(ItqanRadius.lg),
        border: Border.all(color: ItqanColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Due Today',
                value: '$due',
                icon: Icons.alarm_rounded,
                color: due > 0 ? ItqanColors.error : ItqanColors.correct,
              ),
              _StatItem(
                label: 'Mastered',
                value: '$mastered',
                icon: Icons.verified_rounded,
                color: ItqanColors.gold,
              ),
              _StatItem(
                label: 'Retention',
                value: '$retention%',
                icon: Icons.insights_rounded,
                color: ItqanColors.info,
              ),
              _StatItem(
                label: 'Streak',
                value: '$streak d',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFF97316),
              ),
            ],
          ),
          const SizedBox(height: ItqanSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ItqanColors.charcoal,
              borderRadius: BorderRadius.circular(ItqanRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.psychology_rounded, size: 14, color: ItqanColors.gold),
                const SizedBox(width: 6),
                Text(
                  'SuperMemo SM-2 Spaced Repetition Active',
                  style: ItqanTypography.caption.copyWith(color: ItqanColors.gold, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: ItqanTypography.caption.copyWith(fontSize: 10, color: ItqanColors.mist)),
      ],
    );
  }
}

class _CardListView extends StatelessWidget {
  final List<SrsCard> cards;
  final String emptyMessage;
  final ValueChanged<SrsCard> onRecite;

  const _CardListView({
    required this.cards,
    required this.emptyMessage,
    required this.onRecite,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ItqanSpacing.xl),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: ItqanTypography.body.copyWith(color: ItqanColors.mist),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(ItqanSpacing.md),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final isDue = card.isDue;

        return Container(
          margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
          padding: const EdgeInsets.all(ItqanSpacing.md),
          decoration: BoxDecoration(
            color: ItqanColors.onyx,
            borderRadius: BorderRadius.circular(ItqanRadius.lg),
            border: Border.all(
              color: isDue ? ItqanColors.gold.withOpacity(0.5) : ItqanColors.charcoal,
              width: isDue ? 1.5 : 1,
            ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ItqanColors.charcoal,
                          borderRadius: BorderRadius.circular(ItqanRadius.sm),
                        ),
                        child: Text(
                          '${card.surahName} : ${card.ayahNumber}',
                          style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: card.stage == SrsStage.mastered
                              ? ItqanColors.correct.withOpacity(0.15)
                              : ItqanColors.info.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(ItqanRadius.sm),
                        ),
                        child: Text(
                          card.stageName,
                          style: TextStyle(
                            color: card.stage == SrsStage.mastered ? ItqanColors.correct : ItqanColors.info,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (card.mistakeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ItqanColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(ItqanRadius.sm),
                      ),
                      child: Text(
                        '${card.mistakeCount} error(s)',
                        style: const TextStyle(color: ItqanColors.error, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ItqanSpacing.sm),
              if (card.textUthmani.isNotEmpty)
                Text(
                  card.textUthmani,
                  style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 20,
                    color: Colors.white,
                    height: 1.8,
                  ),
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: ItqanSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isDue ? 'Due today!' : 'Next review in ${card.daysUntilDue} day(s)',
                    style: TextStyle(
                      color: isDue ? ItqanColors.gold : ItqanColors.mist,
                      fontSize: 12,
                      fontWeight: isDue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => onRecite(card),
                    icon: const Icon(Icons.mic_rounded, size: 16, color: ItqanColors.void_),
                    label: const Text('Recite (Hifz)', style: TextStyle(color: ItqanColors.void_, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ItqanColors.gold,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ItqanRadius.full)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
