import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import 'models/qiraat_type.dart';
import 'services/qiraat_service.dart';

class QiraatScreen extends StatefulWidget {
  const QiraatScreen({super.key});

  @override
  State<QiraatScreen> createState() => _QiraatScreenState();
}

class _QiraatScreenState extends State<QiraatScreen> {
  final QiraatService _service = QiraatService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    await _service.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectRiwayah(QiraatRiwayah riwayah) async {
    await _service.setActiveRiwayah(riwayah);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Active Qira\'ah set to ${_service.activeQiraatInfo.name}'),
          backgroundColor: ItqanColors.correct,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allQiraat = _service.getAllQiraat();
    final active = _service.activeRiwayah;

    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        backgroundColor: ItqanColors.void_,
        title: const Text('Canonical Qira\'at (القراءات)', style: ItqanTypography.heading2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ItqanColors.gold))
          : ListView(
              padding: const EdgeInsets.all(ItqanSpacing.lg),
              children: [
                // Active Banner
                Container(
                  padding: const EdgeInsets.all(ItqanSpacing.md),
                  decoration: BoxDecoration(
                    color: ItqanColors.onyx,
                    borderRadius: BorderRadius.circular(ItqanRadius.lg),
                    border: Border.all(color: ItqanColors.gold.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ItqanColors.gold.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.record_voice_over_rounded, color: ItqanColors.gold, size: 24),
                      ),
                      const SizedBox(width: ItqanSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Active Recitation Riwayah:', style: ItqanTypography.caption),
                            Text(
                              _service.activeQiraatInfo.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              _service.activeQiraatInfo.arabicName,
                              style: const TextStyle(fontFamily: 'NotoNaskhArabic', color: ItqanColors.gold, fontSize: 14),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: ItqanSpacing.lg),
                const Text('FOUR CANONICAL RIWAYAT', style: ItqanTypography.label),
                const SizedBox(height: ItqanSpacing.sm),

                ...allQiraat.map((q) {
                  final isCurrent = q.riwayah == active;
                  return _QiraatCard(
                    info: q,
                    isActive: isCurrent,
                    onSelect: () => _selectRiwayah(q.riwayah),
                  );
                }),

                const SizedBox(height: ItqanSpacing.lg),
                const Text('COMPARATIVE AL-FATIHAH (1:4)', style: ItqanTypography.label),
                const SizedBox(height: ItqanSpacing.sm),

                Container(
                  padding: const EdgeInsets.all(ItqanSpacing.md),
                  decoration: BoxDecoration(
                    color: ItqanColors.onyx,
                    borderRadius: BorderRadius.circular(ItqanRadius.lg),
                  ),
                  child: Column(
                    children: [
                      _ComparisonRow(
                        riwayah: 'Hafs \'an \'Asim',
                        arabicText: 'مَٰلِكِ يَوْمِ ٱلدِّينِ',
                        explanation: 'With Alif prolongation (Mālik = Owner / Sovereign)',
                      ),
                      const Divider(color: ItqanColors.charcoal),
                      _ComparisonRow(
                        riwayah: 'Warsh \'an Nafi\'',
                        arabicText: 'مَلِكِ يَوْمِ الدِّينِ',
                        explanation: 'Without Alif (Malik = King)',
                      ),
                      const Divider(color: ItqanColors.charcoal),
                      _ComparisonRow(
                        riwayah: 'Qalun \'an Nafi\'',
                        arabicText: 'مَلِكِ يَوْمِ الدِّينِ',
                        explanation: 'Without Alif (Malik = King)',
                      ),
                      const Divider(color: ItqanColors.charcoal),
                      _ComparisonRow(
                        riwayah: 'Ad-Duri \'an Abi \'Amr',
                        arabicText: 'مَلِكِ يَوْمِ الدِّينِ',
                        explanation: 'Without Alif (Malik = King)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ItqanSpacing.xl),
              ],
            ),
    );
  }
}

class _QiraatCard extends StatelessWidget {
  final QiraatInfo info;
  final bool isActive;
  final VoidCallback onSelect;

  const _QiraatCard({
    required this.info,
    required this.isActive,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
      padding: const EdgeInsets.all(ItqanSpacing.md),
      decoration: BoxDecoration(
        color: ItqanColors.onyx,
        borderRadius: BorderRadius.circular(ItqanRadius.lg),
        border: Border.all(
          color: isActive ? ItqanColors.gold : ItqanColors.charcoal,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      info.arabicName,
                      style: const TextStyle(fontFamily: 'NotoNaskhArabic', color: ItqanColors.gold, fontSize: 16),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ItqanColors.gold,
                    borderRadius: BorderRadius.circular(ItqanRadius.full),
                  ),
                  child: const Text('Active', style: TextStyle(color: ItqanColors.void_, fontWeight: FontWeight.bold, fontSize: 11)),
                )
              else
                OutlinedButton(
                  onPressed: onSelect,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ItqanColors.goldGlow),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ItqanRadius.full)),
                  ),
                  child: const Text('Select', style: TextStyle(color: ItqanColors.gold, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: ItqanSpacing.sm),
          Text(info.description, style: ItqanTypography.caption),
          const SizedBox(height: ItqanSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ItqanColors.charcoal,
              borderRadius: BorderRadius.circular(ItqanRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public_rounded, size: 14, color: ItqanColors.mist),
                const SizedBox(width: 6),
                Text(info.primaryRegion, style: ItqanTypography.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: ItqanSpacing.md),
          const Text('Distinctive Recitation Features:', style: TextStyle(color: ItqanColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...info.phoneticRules.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('• $r', style: ItqanTypography.caption.copyWith(fontSize: 11)),
            ),
          ),
          const SizedBox(height: ItqanSpacing.sm),
          const Text('Featured Reciters:', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: info.reciters.map((rec) {
              return Chip(
                backgroundColor: ItqanColors.charcoal,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                avatar: const Icon(Icons.mic, size: 12, color: ItqanColors.gold),
                label: Text(rec.name, style: const TextStyle(fontSize: 10, color: Colors.white)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String riwayah;
  final String arabicText;
  final String explanation;

  const _ComparisonRow({
    required this.riwayah,
    required this.arabicText,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(riwayah, style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(explanation, style: ItqanTypography.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              arabicText,
              style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 18, color: Colors.white),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

