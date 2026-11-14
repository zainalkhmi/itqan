import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/tajweed/services/tajweed_service.dart';

void main() {
  late TajweedService service;

  setUp(() {
    service = TajweedService();
  });

  group('TajweedService Canonical Rules', () {
    test('contains all 16 canonical QUL / Quran.com rules', () {
      final expectedRules = [
        'ghunnah',
        'ham_wasl',
        'idgham_ghunnah',
        'idgham_wo_ghunnah',
        'idgham_shafawi',
        'idgham_mutaqaribayn',
        'ikhafa',
        'ikhafa_shafawi',
        'iqlab',
        'laam_shamsiyah',
        'madda_necessary',
        'madda_obligatory',
        'madda_permissible',
        'madda_normal',
        'qalaqah',
        'slnt',
      ];

      for (final rule in expectedRules) {
        expect(
          TajweedService.ruleDefinitions.containsKey(rule),
          isTrue,
          reason: 'Rule $rule should be defined in ruleDefinitions',
        );
        final details = TajweedService.ruleDefinitions[rule]!;
        expect(details.name.isNotEmpty, isTrue);
        expect(details.nameArabic.isNotEmpty, isTrue);
        expect(details.description.isNotEmpty, isTrue);
        expect(details.harakat, greaterThanOrEqualTo(0));
        expect(details.color, isNotNull);
      }
    });

    test('getRuleDetails returns correct details for known rule', () {
      final ghunnah = service.getRuleDetails('ghunnah');
      expect(ghunnah.type, equals(TajweedRuleType.ghunnah));
      expect(ghunnah.name, equals('Ghunnah'));
      expect(ghunnah.harakat, equals(2));

      final qalqalah = service.getRuleDetails('qalaqah');
      expect(qalqalah.type, equals(TajweedRuleType.qalqalah));
      expect(qalqalah.name, equals('Qalqalah'));

      final madd6 = service.getRuleDetails('madda_necessary');
      expect(madd6.type, equals(TajweedRuleType.maddNecessary));
      expect(madd6.harakat, equals(6));
    });

    test('getRuleDetails falls back gracefully for unknown rule', () {
      final custom = service.getRuleDetails('custom_unknown_rule');
      expect(custom.type, equals(TajweedRuleType.other));
      expect(custom.rawClass, equals('custom_unknown_rule'));
      expect(custom.name, equals('custom_unknown_rule'));
      expect(custom.nameArabic, equals('تجويد'));
    });
  });

  group('TajweedService.parseTajweedSpans', () {
    test('returns single empty span when html is empty', () {
      final spans = service.parseTajweedSpans('');
      expect(spans.length, equals(1));
      expect((spans.first as TextSpan).text, equals(''));
    });

    test('returns single span when text has no tags', () {
      final spans = service.parseTajweedSpans('بِسْمِ اللَّهِ');
      expect(spans.length, equals(1));
      expect((spans.first as TextSpan).text, equals('بِسْمِ اللَّهِ'));
    });

    test('correctly parses and colors tajweed tags', () {
      const html = 'قُلْ <tajweed class=ghunnah>إِنَّ</tajweed> رَبِّي';
      final spans = service.parseTajweedSpans(html);

      expect(spans.length, equals(3));
      final span0 = spans[0] as TextSpan;
      final span1 = spans[1] as TextSpan;
      final span2 = spans[2] as TextSpan;

      expect(span0.text, equals('قُلْ '));
      expect(span1.text, equals('إِنَّ'));
      expect(span1.style?.color, equals(TajweedService.ruleDefinitions['ghunnah']!.color));
      expect(span1.style?.fontWeight, equals(FontWeight.bold));
      expect(span2.text, equals(' رَبِّي'));
    });

    test('strips <span class=end> verse indicators', () {
      const html = 'الْحَمْدُ لِلَّهِ <tajweed class=madda_normal>رَبِّ</tajweed> <span class=end>١</span>';
      final spans = service.parseTajweedSpans(html);

      final combinedText = spans.map((s) => (s as TextSpan).text).join();
      expect(combinedText.contains('١'), isFalse);
      expect(combinedText.contains('span class=end'), isFalse);
    });

    test('parses adjacent tajweed tags properly', () {
      const html = '<tajweed class=ham_wasl>ٱ</tajweed><tajweed class=laam_shamsiyah>ل</tajweed>رَّحْمَٰنِ';
      final spans = service.parseTajweedSpans(html);

      expect(spans.length, equals(3));
      expect((spans[0] as TextSpan).text, equals('ٱ'));
      expect((spans[0] as TextSpan).style?.color,
          equals(TajweedService.ruleDefinitions['ham_wasl']!.color));

      expect((spans[1] as TextSpan).text, equals('ل'));
      expect((spans[1] as TextSpan).style?.color,
          equals(TajweedService.ruleDefinitions['laam_shamsiyah']!.color));

      expect((spans[2] as TextSpan).text, equals('رَّحْمَٰنِ'));
    });
  });

  group('TajweedService.detectOfflineTajweed', () {
    test('returns empty list for empty string', () {
      final tokens = service.detectOfflineTajweed('');
      expect(tokens, isEmpty);
    });

    test('detects Ghunnah (نّ and مّ)', () {
      final tokens = service.detectOfflineTajweed('إِنَّ النَّاسَ ثُمَّ');
      final ghunnahTokens = tokens.where((t) => t.rule.type == TajweedRuleType.ghunnah).toList();
      expect(ghunnahTokens.length, equals(3));
      expect(ghunnahTokens[0].text, equals('نّ'));
      expect(ghunnahTokens[1].text, equals('نّ'));
      expect(ghunnahTokens[2].text, equals('مّ'));
    });

    test('detects Qalqalah (letters with sukun)', () {
      final tokens = service.detectOfflineTajweed('فَلَقْ قَدْ حَبْلُ مَسَدْ');
      // In this string, 'دْ' and 'بْ' have sukun
      final qalqalahTokens = tokens.where((t) => t.rule.type == TajweedRuleType.qalqalah).toList();
      expect(qalqalahTokens.isNotEmpty, isTrue);
    });

    test('detects Madd with Madda symbol', () {
      final tokens = service.detectOfflineTajweed('جَآءَ الصَّآخَّةُ');
      final maddTokens = tokens.where((t) => t.rule.type == TajweedRuleType.maddObligatory).toList();
      expect(maddTokens.length, greaterThanOrEqualTo(1));
    });
  });

  group('TajweedService QPC V4 Index Lookup', () {
    test('returns null when index not initialized or location not found', () {
      expect(service.getQpcV4Word('999:999:999'), isNull);
    });

    test('returns QpcV4WordData when location exists', () {
      service.setIndexForTesting({
        '1:1:1': {
          'id': 1,
          'glyph': 'ﭑ',
        },
        '1:1:2': {
          'id': 2,
          'glyph': 'ﭒ',
        },
      });

      final word1 = service.getQpcV4Word('1:1:1');
      expect(word1, isNotNull);
      expect(word1!.id, equals(1));
      expect(word1.location, equals('1:1:1'));
      expect(word1.glyph, equals('ﭑ'));

      final word2 = service.getQpcV4Word('1:1:2');
      expect(word2, isNotNull);
      expect(word2!.id, equals(2));
      expect(word2.location, equals('1:1:2'));
      expect(word2.glyph, equals('ﭒ'));

      final missing = service.getQpcV4Word('1:1:99');
      expect(missing, isNull);
    });
  });
}

