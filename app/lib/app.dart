import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itqan/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_service.dart';

// Locale provider — driven by user settings (defaults to English)
final localeProvider = Provider<Locale>((ref) {
  final settings = ref.watch(settingsProvider);
  final lang = settings.language.toLowerCase();
  if (lang == 'arabic' || lang == 'ar') return const Locale('ar');
  if (lang == 'french' || lang == 'fr') return const Locale('fr');
  if (lang == 'indonesian' || lang == 'id') return const Locale('id');
  if (lang == 'malay' || lang == 'ms') return const Locale('ms');
  if (lang == 'urdu' || lang == 'ur') return const Locale('ur');
  if (lang == 'turkish' || lang == 'tr') return const Locale('tr');
  return const Locale('en'); // English is DEFAULT
});

// Theme mode provider — driven by user settings (defaults to Dark, supports Light & System)
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  switch (settings.theme.toLowerCase()) {
    case 'light':
      return ThemeMode.light;
    case 'system':
      return ThemeMode.system;
    case 'dark':
    default:
      return ThemeMode.dark;
  }
});

class ItqanApp extends ConsumerWidget {
  final bool showOnboarding;
  const ItqanApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'إتقان',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // Localization
      locale: locale,
      supportedLocales: const [
        Locale('en'), // English — DEFAULT
        Locale('ar'), // Arabic
        Locale('fr'), // French
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // RTL for Arabic, Urdu, Persian, LTR for others
      builder: (context, child) {
        final isRtl = locale.languageCode == 'ar' ||
            locale.languageCode == 'ur' ||
            locale.languageCode == 'fa' ||
            locale.languageCode == 'ps';
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },

      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
