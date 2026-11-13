import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/localization/services/translation_service.dart';

void main() {
  group('TranslationService 20+ Languages Tests', () {
    final service = TranslationService();

    test('supports at least 20 international languages', () {
      final languages = TranslationService.supportedLanguages;
      expect(languages.length, greaterThanOrEqualTo(20));

      final codes = languages.map((l) => l.code).toSet();
      expect(codes, contains('en'));
      expect(codes, contains('ar'));
      expect(codes, contains('id'));
      expect(codes, contains('ms'));
      expect(codes, contains('ur'));
      expect(codes, contains('tr'));
      expect(codes, contains('fr'));
      expect(codes, contains('bn'));
      expect(codes, contains('fa'));
      expect(codes, contains('ru'));
    });

    test('getLanguage returns correct item with RTL flag', () {
      final arabic = service.getLanguage('ar');
      expect(arabic.isRtl, isTrue);
      expect(arabic.nativeName, equals('العربية'));

      final indonesian = service.getLanguage('id');
      expect(indonesian.isRtl, isFalse);
      expect(indonesian.name, equals('Indonesian'));
    });

    test('translate provides localized values for Indonesian and Urdu', () {
      final idGreeting = service.translate('homeGreeting', 'id');
      expect(idGreeting, equals('Assalamu\'alaikum'));

      final urQuran = service.translate('navQuran', 'ur');
      expect(urQuran, equals('قرآن مجید'));

      // Fallback
      final fallback = service.translate('navHome', 'xyz');
      expect(fallback, equals('Home'));
    });
  });
}

