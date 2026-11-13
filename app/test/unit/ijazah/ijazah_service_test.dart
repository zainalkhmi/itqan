import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/ijazah/models/ijazah_models.dart';
import 'package:itqan/features/ijazah/services/ijazah_service.dart';

void main() {
  group('Ijazah & Sanad Service Tests', () {
    late Directory tempDir;
    late IjazahService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ijazah_test_');
      Hive.init(tempDir.path);
      await Hive.openBox(IjazahService.boxName);
      service = IjazahService();
    });

    tearDown(() async {
      await Hive.deleteBoxFromDisk(IjazahService.boxName);
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    test('getSanadChain begins at Prophet Muhammad and ends at current generation', () {
      final chain = service.getSanadChain();
      expect(chain, isNotEmpty);
      expect(chain.first.generation, equals(0));
      expect(chain.first.name, contains('Prophet Muhammad'));

      expect(chain.last.generation, equals(29));
      expect(chain.last.role, contains('Certified'));
    });

    test('issueCertificate adds certificate and verifyCertificate confirms hash', () async {
      await service.init();
      final initialCount = service.getCertificates().length;

      final cert = IjazahCertificate(
        id: 'IJZ-TEST-001',
        studentName: 'Zaid',
        riwayah: 'Warsh \'an Nafi\'',
        title: 'Khatm Sanad 30 Juz',
        presidingShaykh: 'Shaykh Luqman',
        generationDegree: 29,
        grade: 'Mumtaz',
        issueDate: DateTime.now(),
        verificationHash: 'hash123456',
        isVerified: true,
      );

      await service.issueCertificate(cert);
      expect(service.getCertificates().length, equals(initialCount + 1));
      expect(service.verifyCertificate('hash123456'), isTrue);
      expect(service.verifyCertificate('fake_hash'), isFalse);
    });
  });
}
