import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/qiraat/models/qiraat_type.dart';
import 'package:itqan/features/qiraat/services/qiraat_service.dart';

void main() {
  group('QiraatService Canonical Tests', () {
    late QiraatService service;

    setUp(() {
      service = QiraatService();
    });

    test('getAllQiraat contains all 4 canonical riwayat', () {
      final list = service.getAllQiraat();
      expect(list.length, equals(4));

      final riwayat = list.map((q) => q.riwayah).toList();
      expect(riwayat, contains(QiraatRiwayah.hafs));
      expect(riwayat, contains(QiraatRiwayah.warsh));
      expect(riwayat, contains(QiraatRiwayah.qalun));
      expect(riwayat, contains(QiraatRiwayah.duri));
    });

    test('each riwayah has certified reciters and phonetic rules', () {
      final list = service.getAllQiraat();
      for (final q in list) {
        expect(q.name, isNotEmpty);
        expect(q.arabicName, isNotEmpty);
        expect(q.phoneticRules, isNotEmpty);
        expect(q.reciters, isNotEmpty);
        expect(q.reciters.first.audioBaseUrl, startsWith('https://'));
      }
    });

    test('getAyahTextVariant returns correct text for Hafs vs Warsh', () {
      service.setActiveRiwayah(QiraatRiwayah.hafs);
      final hafsText = service.getAyahTextVariant(1, 4, 'مَٰلِكِ يَوْمِ ٱلدِّينِ');
      expect(hafsText, contains('مَٰلِكِ'));

      service.setActiveRiwayah(QiraatRiwayah.warsh);
      final warshText = service.getAyahTextVariant(1, 4, 'مَٰلِكِ يَوْمِ ٱلدِّينِ');
      expect(warshText, equals('مَلِكِ يَوْمِ الدِّينِ'));
    });
  });
}
