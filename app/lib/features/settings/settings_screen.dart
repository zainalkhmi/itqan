import 'package:flutter/material.dart';
import 'package:itqan/l10n/app_localizations.dart';
import '../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import 'settings_service.dart';
import '../mushaf/bookmarks_screen.dart';
import '../adaptive/placement_test_screen.dart';
import '../sync/sync_management_screen.dart';
import '../tashih/tashih_screen.dart';
import '../memorization/murajaah_screen.dart';
import '../qiraat/qiraat_screen.dart';
import '../community/community_screen.dart';
import '../ijazah/ijazah_screen.dart';
import '../localization/language_selector_dialog.dart';
import '../localization/services/translation_service.dart';
import '../voice_search/voice_search_screen.dart';
import '../heatmap/heatmap_screen.dart';
import '../scoring/services/inference_config_service.dart';
import '../offline/offline_download_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _nameController = TextEditingController(text: s.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(AppSettings s) => ref.read(settingsProvider.notifier).update(s);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(AppLocalizations.of(context)!.settingsTitle, style: ItqanTypography.heading2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ItqanSpacing.lg),
        children: [
          _sectionTitle(s, context.l10n.settingsProfile),
          _card([
            TextField(
              controller: _nameController,
              style: ItqanTypography.body,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.settingsName,
                labelStyle: TextStyle(color: ItqanColors.mist),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: ItqanColors.charcoal)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ItqanColors.gold)),
              ),
              onChanged: (v) => _update(s.copyWith(userName: v)),
            ),
            const SizedBox(height: ItqanSpacing.md),
            Text(AppLocalizations.of(context)!.settingsLevel, style: ItqanTypography.caption),
            const SizedBox(height: ItqanSpacing.sm),
            _SegmentedPicker(
              options: const ['Beginner', 'Intermediate', 'Advanced'],
              selected: _capitalize(s.level),
              onSelect: (v) => _update(s.copyWith(level: v.toLowerCase())),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const PlacementTestScreen(),
                  ));
                },
                icon: const Icon(Icons.speed_rounded, size: 16, color: ItqanColors.gold),
                label: const Text(
                  'Take Diagnostic Placement Test',
                  style: TextStyle(color: ItqanColors.gold, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: ItqanSpacing.md),
            Text(AppLocalizations.of(context)!.settingsDailyGoal, style: ItqanTypography.caption),
            const SizedBox(height: ItqanSpacing.sm),
            _ChipPicker(
              options: const ['10 min', '20 min', '30 min'],
              selected: '${s.dailyGoalMinutes} min',
              onSelect: (v) => _update(s.copyWith(dailyGoalMinutes: int.parse(v.split(' ')[0]))),
            ),
          ]),
          _sectionTitle(s, context.l10n.settingsQuranDisplay),
          _card([
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.settingsScript, style: ItqanTypography.body),
                _SegmentedPicker(
                  options: const ['Uthmani', 'Indo-Pak'],
                  selected: s.quranicScript == 'uthmani' ? 'Uthmani' : 'Indo-Pak',
                  onSelect: (v) => _update(s.copyWith(quranicScript: v == 'Uthmani' ? 'uthmani' : 'indopak')),
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: ItqanSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.settingsFontSize, style: ItqanTypography.caption),
                Text('${s.fontSize.round()}px', style: ItqanTypography.caption.copyWith(color: ItqanColors.gold)),
              ],
            ),
            Slider(
              value: s.fontSize,
              min: 20, max: 48,
              activeColor: ItqanColors.gold,
              inactiveColor: ItqanColors.charcoal,
              onChanged: (v) => _update(s.copyWith(fontSize: v)),
            ),
            Center(
              child: Text(
                'بِسْمِ اللَّهِ',
                style: TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: s.fontSize, color: ItqanColors.snow, height: 2),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: ItqanSpacing.md),
            _TileRow(
              label: AppLocalizations.of(context)!.settingsBookmarks,
              icon: Icons.bookmark_rounded,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksScreen())),
            ),
            const SizedBox(height: ItqanSpacing.sm),
            _SwitchRow(
              label: AppLocalizations.of(context)!.settingsTajweedColors,
              value: s.tajweedOverlay,
              onChanged: (v) => _update(s.copyWith(tajweedOverlay: v)),
            ),
            const SizedBox(height: ItqanSpacing.sm),
            _DropdownRow(
              label: AppLocalizations.of(context)!.settingsTranslationLanguage,
              value: s.translationLanguage,
              options: const {'english': 'English', 'french': 'French', 'arabic': 'Arabic Tafsir'},
              onChanged: (v) => _update(s.copyWith(translationLanguage: v)),
            ),
          ]),
          _sectionTitle(s, context.l10n.settingsAudio),
          _card([
            _DropdownRow(
              label: AppLocalizations.of(context)!.settingsQari,
              value: s.defaultQari,
              options: const {'alafasy': 'Alafasy', 'abdulbasit': 'Abdul Basit', 'alhusary': 'Al-Husary'},
              onChanged: (v) => _update(s.copyWith(defaultQari: v)),
            ),
            const SizedBox(height: ItqanSpacing.md),
            Text(AppLocalizations.of(context)!.settingsPlaybackSpeed, style: ItqanTypography.caption),
            const SizedBox(height: ItqanSpacing.sm),
            _ChipPicker(
              options: const ['0.75×', '1.0×', '1.25×'],
              selected: '${s.playbackSpeed}×',
              onSelect: (v) => _update(s.copyWith(playbackSpeed: double.parse(v.replaceAll('×', '')))),
            ),
          ]),
          _sectionTitle(s, context.l10n.settingsScoring),
          _card([
            Text(AppLocalizations.of(context)!.settingsDifficulty, style: ItqanTypography.caption),
            const SizedBox(height: ItqanSpacing.sm),
            _SegmentedPicker(
              options: const ['Beginner', 'Intermediate', 'Advanced'],
              selected: _capitalize(s.scoringDifficulty),
              onSelect: (v) => _update(s.copyWith(scoringDifficulty: v.toLowerCase())),
            ),
            const SizedBox(height: ItqanSpacing.md),
            _ScoringWeightsTable(level: s.scoringDifficulty),
          ]),
          _sectionTitle(s, context.l10n.settingsApp),
          _card([
            _DropdownRow(
              label: AppLocalizations.of(context)!.settingsTheme,
              value: s.theme,
              options: const {'dark': 'Dark', 'light': 'Light (Tarteel)', 'system': 'System'},
              onChanged: (v) => _update(s.copyWith(theme: v)),
            ),
            const SizedBox(height: ItqanSpacing.sm),
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => LanguageSelectorDialog(
                    currentCode: s.language,
                    onSelected: (lang) => _update(s.copyWith(language: lang.code)),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.settingsLanguage, style: ItqanTypography.body),
                    Row(
                      children: [
                        Text(
                          '${TranslationService().getLanguage(s.language).flagEmoji} ${TranslationService().getLanguage(s.language).name}',
                          style: ItqanTypography.body.copyWith(color: ItqanColors.gold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: ItqanColors.gold),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ItqanSpacing.sm),
            _SwitchRow(
              label: AppLocalizations.of(context)!.settingsNotifications,
              value: s.notifications,
              onChanged: (v) => _update(s.copyWith(notifications: v)),
            ),
          ]),
          _sectionTitle(s, 'Cloud Sync & Community (Phase 3)'),
          _card([
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_sync_rounded, color: ItqanColors.gold),
              title: const Text('Cloud Sync & Backup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Supabase / Firebase multi-device sync', style: ItqanTypography.caption),
              trailing: const Icon(Icons.chevron_right_rounded, color: ItqanColors.mist),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const SyncManagementScreen(),
                ));
              },
            ),
            const Divider(color: ItqanColors.charcoal),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school_rounded, color: ItqanColors.gold),
              title: const Text('Teacher / Student Tashih', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Submit recitations for ustadz review', style: ItqanTypography.caption),
              trailing: const Icon(Icons.chevron_right_rounded, color: ItqanColors.mist),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const TashihScreen(),
                ));
              },
            ),
            const Divider(color: ItqanColors.charcoal),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.psychology_rounded, color: ItqanColors.gold),
              title: const Text('Muraja\'ah (SRS Spaced Repetition)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Daily memorization scheduling & retention', style: ItqanTypography.caption),
              trailing: const Icon(Icons.chevron_right_rounded, color: ItqanColors.mist),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const MurajaahScreen(),
                ));
              },
            ),
          ]),
          _sectionTitle(s, 'Scale & Community (Phase 4)'),
          _card([
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.record_voice_over_rounded, color: ItqanColors.gold),
              title: const Text('Canonical Qira\'at', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Hafs, Warsh, Qalun, Ad-Duri riwayat', style: ItqanTypography.caption),
              trailing: const Icon(Icons.chevron_right_rounded, color: ItqanColors.mist),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const QiraatScreen(),
                ));
              },
            ),
            const Divider(color: ItqanColors.charcoal),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.groups_rounded, color: ItqanColors.gold),
              title: const Text('Community & Halaqah Circles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Global leaderboards & daily challenges', style: ItqanTypography.caption),
              trailing: const Icon(Icons.chevron_right_rounded, color: ItqanColors.mist),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CommunityScreen(),
                ));
              },
            ),
            const Divider(color: ItqanColors.charcoal),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.workspace_premium_rounded, color: ItqanColors.gold),
              title: const Text('Ijazah & Sanad Chain', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('29-generation transmission tree & verified certificate', style: ItqanTypography.caption),
              trailing: const Icon(Icons.chevron_right_rounded, color: ItqanColors.mist),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const IjazahScreen(),
                ));
              },
            ),
          ]),
          _sectionTitle(s, 'AI Recitation & Voice Engine'),
          _card([
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.graphic_eq_rounded, color: ItqanColors.gold),
              title: const Text('Quran Voice Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Shazam for Quran: Recite to find Ayah', style: ItqanTypography.caption),
              trailing: const Icon(Icons.chevron_right_rounded, color: ItqanColors.mist),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const VoiceSearchScreen(),
                ));
              },
            ),
            const Divider(color: ItqanColors.charcoal),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.grid_view_rounded, color: ItqanColors.gold),
              title: const Text('Quran Memorization Heatmap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Visual 30 Juz & 114 Surah Retention Grid', style: ItqanTypography.caption),
              trailing: const Icon(Icons.chevron_right_rounded, color: ItqanColors.mist),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const HeatmapScreen(),
                ));
              },
            ),
            const Divider(color: ItqanColors.charcoal),
            Text('Speech Recognition & Tajweed Engine', style: ItqanTypography.caption),
            const SizedBox(height: ItqanSpacing.sm),
            _SegmentedPicker(
              options: const ['Auto', 'TajweedFormer', 'Whisper', 'On-Device', 'Acoustic'],
              selected: switch (ref.watch(inferenceConfigProvider)) {
                InferenceMode.tajweedFormer => 'TajweedFormer',
                InferenceMode.mlServer => 'Whisper',
                InferenceMode.onDevice => 'On-Device',
                InferenceMode.acoustic => 'Acoustic',
                _ => 'Auto',
              },
              onSelect: (v) {
                final mode = switch (v) {
                  'TajweedFormer' => InferenceMode.tajweedFormer,
                  'Whisper' => InferenceMode.mlServer,
                  'On-Device' => InferenceMode.onDevice,
                  'Acoustic' => InferenceMode.acoustic,
                  _ => InferenceMode.auto,
                };
                ref.read(inferenceConfigProvider.notifier).setMode(mode);
              },
              compact: true,
              scrollable: true,
            ),
            const SizedBox(height: ItqanSpacing.xs),
            Text(
              switch (ref.watch(inferenceConfigProvider)) {
                InferenceMode.tajweedFormer => 'Quran Lab TajweedFormer V4 — Specialized Neural Engine for Madd (count duration), Ghunnah, Qalqalah, and Shaddah (quranlab.ai).',
                InferenceMode.mlServer => 'Tarteel AI / OpenAI Whisper ASR — Speech-to-Text alignment and phonetic word comparison.',
                InferenceMode.onDevice => 'On-Device INT8 ONNX Model — Ultra-low latency and offline on-device processing.',
                InferenceMode.acoustic => 'Deterministic Acoustic Engine — Offline fallback evaluating duration, pitch, and energy without heavy ML.',
                _ => 'Auto — Automatically selects TajweedFormer V4 / Whisper when available, falling back to on-device engine.',
              },
              style: ItqanTypography.caption.copyWith(fontSize: 11, color: ItqanColors.mist),
            ),
            const SizedBox(height: ItqanSpacing.sm),
            FutureBuilder<InferenceEngineStatus>(
              future: ref.read(inferenceConfigProvider.notifier).checkStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Verifying engine availability...', style: TextStyle(color: ItqanColors.mist, fontSize: 11)),
                  );
                }
                final status = snapshot.data;
                if (status == null) return const SizedBox.shrink();
                final isOnline = status.isServerOnline;
                final hasOnDevice = status.isOnDeviceModelPresent;
                final isTajweed = status.mode == InferenceMode.tajweedFormer;
                final isReady = (status.mode == InferenceMode.acoustic || (status.mode == InferenceMode.onDevice && hasOnDevice) || isOnline || isTajweed);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isReady ? ItqanColors.correct : ItqanColors.warning).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(ItqanRadius.sm),
                        border: Border.all(
                          color: (isReady ? ItqanColors.correct : ItqanColors.warning).withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isReady ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            size: 14,
                            color: isReady ? ItqanColors.correct : ItqanColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              status.mode == InferenceMode.acoustic
                                  ? 'Deterministic Acoustic Engine Ready (Full Offline)'
                                  : (status.mode == InferenceMode.onDevice
                                      ? (hasOnDevice ? 'Bundled INT8 ONNX Model Ready (On-Device)' : 'Local Acoustic Fallback Ready')
                                      : (isOnline
                                          ? 'ML Server Online (${status.latencyMs}ms • ${status.modelName})'
                                          : (isTajweed
                                              ? 'Quran Lab TajweedFormer V4 Ready (Native On-Device & Offline)'
                                              : 'ML Server Offline — Local On-Device Fallback Active'))),
                              style: TextStyle(
                                color: isReady ? ItqanColors.correct : ItqanColors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ItqanSpacing.xs),
                    InkWell(
                      onTap: () => _showServerConfigDialog(context, ref),
                      borderRadius: BorderRadius.circular(ItqanRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.dns_rounded, size: 14, color: ItqanColors.mist),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Server Endpoint: ${ref.read(inferenceConfigProvider.notifier).serverUrl}',
                                style: const TextStyle(color: ItqanColors.mist, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.edit_rounded, size: 14, color: ItqanColors.gold),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ]),
          _sectionTitle(s, 'Offline Storage & Downloads'),
          _card([
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.download_for_offline_rounded, color: ItqanColors.gold),
              title: const Text('Offline Audio & Quran Downloads', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Download Alafasy audio recitation & full Quran text', style: ItqanTypography.caption),
              trailing: const Icon(Icons.chevron_right_rounded, color: ItqanColors.mist),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const OfflineDownloadScreen(),
                ));
              },
            ),
          ]),
          _sectionTitle(s, context.l10n.settingsAbout),
          _card([
            _AboutRow(label: AppLocalizations.of(context)!.settingsVersion, value: '1.0.0'),
            const SizedBox(height: ItqanSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.code, color: ItqanColors.gold, size: 16),
              label: const Text('View source on GitHub', style: TextStyle(color: ItqanColors.gold)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: ItqanColors.goldGlow)),
            ),
            const SizedBox(height: ItqanSpacing.sm),
            Text(AppLocalizations.of(context)!.settingsOpenSource, style: ItqanTypography.caption),
            const SizedBox(height: ItqanSpacing.xs),
            Text(
              AppLocalizations.of(context)!.settingsCredits,
              style: ItqanTypography.caption,
            ),
          ]),
          const SizedBox(height: ItqanSpacing.xl),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Widget _sectionTitle(AppSettings s, String title) => Padding(
    padding: const EdgeInsets.only(top: ItqanSpacing.lg, bottom: ItqanSpacing.sm),
    child: Text(title.toUpperCase(), style: ItqanTypography.label.copyWith(color: ItqanColors.mist, fontSize: 11)),
  );

  Widget _card(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(ItqanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? ItqanColors.onyx : ItqanColors.lightCard,
        borderRadius: BorderRadius.circular(ItqanRadius.lg),
        border: Border.all(
          color: isDark ? Colors.transparent : ItqanColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  void _showServerConfigDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(inferenceConfigProvider.notifier);
    final controller = TextEditingController(text: notifier.serverUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ItqanColors.onyx,
        title: const Text(
          'ML Inference Server Endpoint',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the URL of your local or remote ML server running server.py:',
              style: TextStyle(color: ItqanColors.silver, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: ItqanColors.charcoal,
                hintText: 'http://127.0.0.1:8000',
                hintStyle: const TextStyle(color: ItqanColors.mist, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text('Desktop (127.0.0.1)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://127.0.0.1:8000',
                ),
                ActionChip(
                  label: const Text('Android (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://10.0.2.2:8000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: ItqanColors.mist)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ItqanColors.gold),
            onPressed: () async {
              await notifier.setServerUrl(controller.text);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SegmentedPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool compact;
  final bool scrollable;

  const _SegmentedPicker({
    required this.options,
    required this.selected,
    required this.onSelect,
    this.compact = false,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isScroll = scrollable || options.length > 3;

    final items = options.map((o) {
      final active = o == selected;
      final item = GestureDetector(
        onTap: () => onSelect(o),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: active ? ItqanColors.goldShimmer : ItqanColors.charcoal,
            borderRadius: BorderRadius.circular(ItqanRadius.sm),
            border: Border.all(color: active ? ItqanColors.gold : Colors.transparent),
          ),
          child: Text(
            o,
            style: TextStyle(
              color: active ? ItqanColors.gold : ItqanColors.mist,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

      if (isScroll || compact) {
        return item;
      }
      return Expanded(child: item);
    }).toList();

    if (isScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: items,
        ),
      );
    }

    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: items,
    );
  }
}

class _ChipPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _ChipPicker({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: options.map((o) {
        final active = o == selected;
        return ChoiceChip(
          label: Text(o),
          selected: active,
          selectedColor: ItqanColors.goldShimmer,
          backgroundColor: ItqanColors.charcoal,
          labelStyle: TextStyle(color: active ? ItqanColors.gold : ItqanColors.mist, fontSize: 12),
          side: BorderSide(color: active ? ItqanColors.gold : Colors.transparent),
          onSelected: (_) => onSelect(o),
        );
      }).toList(),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: ItqanTypography.body),
      Switch(value: value, onChanged: onChanged, activeColor: ItqanColors.gold),
    ],
  );
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  const _DropdownRow({required this.label, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: ItqanTypography.body),
      DropdownButton<String>(
        value: value,
        dropdownColor: ItqanColors.onyx,
        style: ItqanTypography.body.copyWith(color: ItqanColors.gold),
        underline: const SizedBox(),
        items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    ],
  );
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: ItqanTypography.body),
      Text(value, style: ItqanTypography.body.copyWith(color: ItqanColors.mist)),
    ],
  );
}

class _ScoringWeightsTable extends StatelessWidget {
  final String level;
  const _ScoringWeightsTable({required this.level});

  @override
  Widget build(BuildContext context) {
    final weights = switch (level) {
      'intermediate' => {'Word Accuracy': '30%', 'Letter Accuracy': '30%', 'Tajweed': '30%', 'Fluency': '10%'},
      'advanced'     => {'Word Accuracy': '20%', 'Letter Accuracy': '30%', 'Tajweed': '40%', 'Fluency': '10%'},
      _              => {'Word Accuracy': '40%', 'Letter Accuracy': '30%', 'Tajweed': '20%', 'Fluency': '10%'},
    };
    return Column(
      children: weights.entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(e.key, style: ItqanTypography.caption),
            Text(e.value, style: ItqanTypography.caption.copyWith(color: ItqanColors.gold)),
          ],
        ),
      )).toList(),
    );
  }
}

class _TileRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _TileRow({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: ItqanColors.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: ItqanTypography.body)),
          const Icon(Icons.arrow_forward_ios_rounded, color: ItqanColors.mist, size: 14),
        ],
      ),
    ),
  );
}
