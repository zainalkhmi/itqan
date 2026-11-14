import 'package:flutter/material.dart';
import 'package:itqan/l10n/app_localizations.dart';
import '../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../settings/settings_service.dart';
import '../home/home_screen.dart';
import '../quran/models/ayah.dart';
import '../quran/services/quran_service.dart';
import '../recitation/recitation_screen.dart';
import '../quran/data/quran_catalog.dart';
import '../offline/services/audio_download_service.dart';
import '../offline/services/offline_quran_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  String _selectedLevel = 'beginner';
  int _selectedGoal = 20;

  void _next() {
    if (_page < 3) {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Future<void> _finish() async {
    // Save settings
    final settings = ref.read(settingsProvider);
    await ref.read(settingsProvider.notifier).update(
      settings.copyWith(level: _selectedLevel, dailyGoalMinutes: _selectedGoal),
    );
    // Mark onboarding done
    await Hive.box('settings').put('onboarding_done', true);
    if (!mounted) return;
    // Navigate to recitation for Surah 1 Ayah 1
    final service = QuranService();
    await service.init();
    final ayahs = await service.getAyahs(1);
    if (!mounted) return;
    if (ayahs.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => RecitationScreenWrapper(ayah: ayahs.first, surahName: 'Al-Fatiha'),
      ));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ItqanColors.void_,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _WelcomePage(onNext: _next),
              _LevelPage(
                selected: _selectedLevel,
                onSelect: (l) => setState(() => _selectedLevel = l),
                onNext: _next,
              ),
              _GoalPage(
                selected: _selectedGoal,
                onSelect: (g) => setState(() => _selectedGoal = g),
                onNext: _next,
              ),
              _OfflinePackPage(
                onFinish: _finish,
              ),
            ],
          ),
          // Dot indicators
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? ItqanColors.gold : ItqanColors.charcoal,
                    borderRadius: BorderRadius.circular(ItqanRadius.full),
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ItqanSpacing.lg, vertical: ItqanSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Islamic pattern placeholder
            CustomPaint(size: const Size(160, 160), painter: _IslamicPatternPainter()),
            const SizedBox(height: ItqanSpacing.xl),
            const Text(
              'إتقان',
              style: TextStyle(fontFamily: 'Amiri', fontSize: 64, color: ItqanColors.gold, height: 1.4),
              textDirection: TextDirection.rtl,
            ),
            const Text('Itqan', style: TextStyle(fontFamily: 'Inter', fontSize: 24, color: ItqanColors.mist)),
            const SizedBox(height: ItqanSpacing.sm),
            Builder(builder: (ctx) => Text(
              AppLocalizations.of(ctx)?.onboardingWelcomeSubtitle ?? 'Master Quran recitation with AI-powered feedback',
              style: const TextStyle(fontSize: 16, color: ItqanColors.silver),
              textAlign: TextAlign.center,
            )),
            const SizedBox(height: ItqanSpacing.xxl),
            GestureDetector(
              onTap: onNext,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: ItqanColors.goldShimmer,
                  shape: BoxShape.circle,
                  border: Border.all(color: ItqanColors.gold),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: ItqanColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPage extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;
  const _LevelPage({required this.selected, required this.onSelect, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final levels = [
      {'key': 'beginner', 'emoji': '🌱', 'title': l10n?.settingsLevelBeginner ?? 'Beginner', 'sub': l10n?.onboardingLevelBeginner ?? 'Starting out'},
      {'key': 'intermediate', 'emoji': '📖', 'title': l10n?.settingsLevelIntermediate ?? 'Intermediate', 'sub': l10n?.onboardingLevelIntermediate ?? 'Some tajweed basics'},
      {'key': 'advanced', 'emoji': '🎓', 'title': l10n?.settingsLevelAdvanced ?? 'Advanced', 'sub': l10n?.onboardingLevelAdvanced ?? 'Fluent reader'},
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ItqanSpacing.lg, vertical: ItqanSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Builder(builder: (ctx) => Text(AppLocalizations.of(ctx)?.onboardingLevelTitle ?? 'Select Your Level', style: ItqanTypography.heading2, textAlign: TextAlign.center)),
            const SizedBox(height: ItqanSpacing.xl),
            ...levels.map((l) {
              final active = selected == l['key'];
              return GestureDetector(
                onTap: () => onSelect(l['key']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
                  padding: const EdgeInsets.all(ItqanSpacing.md),
                  decoration: BoxDecoration(
                    color: active ? ItqanColors.goldShimmer : ItqanColors.onyx,
                    borderRadius: BorderRadius.circular(ItqanRadius.lg),
                    border: Border.all(color: active ? ItqanColors.gold : ItqanColors.charcoal),
                    boxShadow: active ? [BoxShadow(color: ItqanColors.goldGlow, blurRadius: 12)] : null,
                  ),
                  child: Row(
                    children: [
                      Text(l['emoji']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: ItqanSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l['title']!, style: ItqanTypography.label.copyWith(color: active ? ItqanColors.gold : ItqanColors.snow)),
                            Text(l['sub']!, style: ItqanTypography.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: ItqanSpacing.xl),
            Builder(builder: (ctx) => _GoldButton(label: AppLocalizations.of(ctx)?.onboardingContinue ?? 'Continue', onPressed: onNext)),
          ],
        ),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onNext;
  const _GoalPage({required this.selected, required this.onSelect, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ItqanSpacing.lg, vertical: ItqanSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Builder(builder: (ctx) => Text(AppLocalizations.of(ctx)?.onboardingGoalTitle ?? 'Daily Goal', style: ItqanTypography.heading2, textAlign: TextAlign.center)),
            const SizedBox(height: ItqanSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [10, 20, 30].map((min) {
                final active = selected == min;
                return GestureDetector(
                  onTap: () => onSelect(min),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: active ? ItqanColors.goldShimmer : ItqanColors.onyx,
                      borderRadius: BorderRadius.circular(ItqanRadius.full),
                      border: Border.all(color: active ? ItqanColors.gold : ItqanColors.charcoal),
                    ),
                    child: Text(
                      '$min min',
                      style: TextStyle(color: active ? ItqanColors.gold : ItqanColors.mist, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: ItqanSpacing.xxl),
            _GoldButton(label: 'Next', onPressed: onNext),
          ],
        ),
      ),
    );
  }
}

class _OfflinePackPage extends StatefulWidget {
  final VoidCallback onFinish;
  const _OfflinePackPage({required this.onFinish});

  @override
  State<_OfflinePackPage> createState() => _OfflinePackPageState();
}

class _OfflinePackPageState extends State<_OfflinePackPage> {
  final AudioDownloadService _audioService = AudioDownloadService();
  final OfflineQuranService _quranService = OfflineQuranService();

  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';
  bool _isCompleted = false;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'Menyiapkan database teks Al-Qur\'an...';
      _progress = 0.05;
    });

    try {
      // 1. Download/seed essential Quran text
      await _quranService.downloadAllQuranText(onProgress: (done, total, p) {
        if (mounted) {
          setState(() {
            _progress = (p * 0.3).clamp(0.0, 0.3);
            _statusText = 'Mengunduh teks Al-Qur\'an ($done/114)...';
          });
        }
      });

      // 2. Download Surah Al-Fatihah audio
      if (mounted) {
        setState(() {
          _statusText = 'Mengunduh audio Surah Al-Fatihah...';
          _progress = 0.35;
        });
      }
      await _audioService.downloadSurah(1);

      // 3. Download Juz 'Amma audio (Surah 78-114)
      const startSurah = 78;
      const endSurah = 114;
      const totalSurahs = endSurah - startSurah + 1;
      int count = 0;

      for (int s = startSurah; s <= endSurah; s++) {
        if (!mounted || !_isDownloading) break;
        final name = QuranCatalog.getSurah(s).nameSimple;
        setState(() {
          _statusText = 'Mengunduh audio ($count/$totalSurahs): Surah $name...';
          _progress = 0.35 + ((count / totalSurahs) * 0.65);
        });
        await _audioService.downloadSurah(s);
        count++;
      }

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isCompleted = true;
          _progress = 1.0;
          _statusText = '✓ Al-Qur\'an & Audio Siap Digunakan Offline!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Unduhan dapat dilanjutkan nanti di Pengaturan.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ItqanSpacing.lg, vertical: ItqanSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: ItqanColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: ItqanColors.gold.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.cloud_download_rounded, color: ItqanColors.gold, size: 38),
              ),
            ),
            const SizedBox(height: ItqanSpacing.lg),
            const Text(
              'Unduh Paket Offline',
              style: ItqanTypography.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ItqanSpacing.xs),
            const Text(
              'Unduh teks Al-Qur\'an & audio murattal agar dapat mengaji kapan saja tanpa koneksi internet.',
              style: TextStyle(color: ItqanColors.silver, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ItqanSpacing.lg),

            // Feature Card
            Container(
              padding: const EdgeInsets.all(ItqanSpacing.md),
              decoration: BoxDecoration(
                color: ItqanColors.onyx,
                borderRadius: BorderRadius.circular(ItqanRadius.lg),
                border: Border.all(color: ItqanColors.charcoal),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: ItqanColors.correct, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Teks 114 Surah + Audio Juz \'Amma (~35MB)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: ItqanColors.correct, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Qari: Syaikh Mishary Rashid Alafasy',
                          style: TextStyle(color: ItqanColors.mist, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: ItqanSpacing.lg),

            // Progress or Status
            if (_isDownloading || _isCompleted || _statusText.isNotEmpty) ...[
              Text(
                _statusText,
                style: TextStyle(
                  color: _isCompleted ? ItqanColors.correct : ItqanColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                color: _isCompleted ? ItqanColors.correct : ItqanColors.gold,
                backgroundColor: ItqanColors.charcoal,
              ),
              const SizedBox(height: ItqanSpacing.md),
            ],

            // Action Buttons
            if (_isCompleted)
              _GoldButton(
                label: 'Mulai Mengaji',
                onPressed: widget.onFinish,
              )
            else if (_isDownloading)
              OutlinedButton(
                onPressed: widget.onFinish,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ItqanColors.mist,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Lanjutkan di Latar Belakang'),
              )
            else ...[
              _GoldButton(
                label: 'Unduh Sekarang (~35MB)',
                onPressed: _startDownload,
              ),
              const SizedBox(height: ItqanSpacing.sm),
              TextButton(
                onPressed: widget.onFinish,
                child: const Text(
                  'Unduh Nanti di Pengaturan',
                  style: TextStyle(color: ItqanColors.mist, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GoldButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: ItqanColors.gold,
      foregroundColor: ItqanColors.void_,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ItqanRadius.lg)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
  );
}

// Simple 8-pointed Islamic star pattern
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ItqanColors.gold.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Outer circle
    canvas.drawCircle(center, r - 4, paint);

    // 8-pointed star
    final starPaint = Paint()
      ..color = ItqanColors.gold.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle1 = (i * 45) * 3.14159 / 180;
      final angle2 = ((i * 45) + 22.5) * 3.14159 / 180;
      final outer = Offset(center.dx + (r - 10) * _cos(angle1), center.dy + (r - 10) * _sin(angle1));
      final inner = Offset(center.dx + (r * 0.4) * _cos(angle2), center.dy + (r * 0.4) * _sin(angle2));
      if (i == 0) path.moveTo(outer.dx, outer.dy);
      else path.lineTo(outer.dx, outer.dy);
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, starPaint);

    // Inner decorative circle
    final innerCircle = Paint()
      ..color = ItqanColors.gold.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r * 0.25, innerCircle);
  }

  double _cos(double rad) => _approxCos(rad);
  double _sin(double rad) => _approxSin(rad);

  // Use dart:math equivalent approximations
  double _approxCos(double x) {
    // Simple Taylor/identity: use platform's math
    return _mathCos(x);
  }
  double _approxSin(double x) => _mathSin(x);

  static double _mathCos(double x) {
    // cos via series
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  static double _mathSin(double x) {
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(_) => false;
}

// Wrapper to use when navigating to recitation from onboarding
class RecitationScreenWrapper extends ConsumerWidget {
  final Ayah ayah;
  final String surahName;
  const RecitationScreenWrapper({super.key, required this.ayah, required this.surahName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RecitationScreen(ayah: ayah, surahName: surahName);
  }
}
