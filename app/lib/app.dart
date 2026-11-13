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
  switch (settings.language) {
    case 'arabic':
      return const Locale('ar');
    case 'french':
      return const Locale('fr');
    case 'english':
    default:
      return const Locale('en'); // English is DEFAULT
  }
});

class ItqanApp extends ConsumerWidget {
  final bool showOnboarding;
  const ItqanApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'إتقان',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,

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

      // RTL for Arabic, LTR for others
      builder: (context, child) {
        final isArabic = locale.languageCode == 'ar';
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },

      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
