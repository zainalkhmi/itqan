import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/tashih/models/tashih_submission.dart';
import 'package:itqan/features/tashih/services/tashih_service.dart';

void main() {
  group('TashihSubmission Model Tests', () {
    test('serialization toMap and fromMap preserves all fields', () {
      final now = DateTime.now();
      final sub = TashihSubmission(
        id: 'sub_123',
        studentId: 'std_456',
        studentName: 'Ahmad Santri',
        surahNumber: 1,
        ayahNumber: 1,
        surahName: 'Al-Fatiha',
        textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        aiScore: 92.5,
        aiGrade: 'Excellent',
        submittedAt: now,
        status: TashihStatus.pending,
      );

      final map = sub.toMap();
      final revived = TashihSubmission.fromMap(map);

      expect(revived.id, equals('sub_123'));
      expect(revived.studentName, equals('Ahmad Santri'));
      expect(revived.aiScore, equals(92.5));
      expect(revived.status, equals(TashihStatus.pending));
    });

    test('copyWith updates status and review notes accurately', () {
      final sub = TashihSubmission(
        id: 'sub_1',
        studentId: 'std_1',
        studentName: 'Ahmad',
        surahNumber: 1,
        ayahNumber: 2,
        surahName: 'Al-Fatiha',
        textUthmani: 'ٱلْحَمْدُ لِلَّهِ',
        aiScore: 80.0,
        aiGrade: 'Good',
        submittedAt: DateTime.now(),
      );

      final reviewed = sub.copyWith(
        status: TashihStatus.approved,
        teacherName: 'Ustadz Abdullah',
        teacherScore: 88.0,
        tajweedNotes: 'Madd 2 harakat is clean',
      );

      expect(reviewed.status, equals(TashihStatus.approved));
      expect(reviewed.teacherName, equals('Ustadz Abdullah'));
      expect(reviewed.teacherScore, equals(88.0));
      expect(reviewed.tajweedNotes, contains('Madd 2 harakat'));
    });
  });

  group('TashihService Workflow Tests', () {
    late Directory tempDir;
    late TashihService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tashih_test_');
      Hive.init(tempDir.path);
      await Hive.openBox(TashihService.boxName);
      service = TashihService();
    });

    tearDown(() async {
      await Hive.deleteBoxFromDisk(TashihService.boxName);
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    test('submitRecitation adds submission to list', () async {
      await service.init();
      final initialCount = service.getAllSubmissions().length;

      final newSub = await service.submitRecitation(
        studentName: 'Test Student',
        surahNumber: 112,
        ayahNumber: 1,
        surahName: 'Al-Ikhlas',
        textUthmani: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
        aiScore: 90.0,
        aiGrade: 'Excellent',
      );

      expect(newSub.studentName, equals('Test Student'));
      expect(newSub.status, equals(TashihStatus.pending));

      final all = service.getAllSubmissions();
      expect(all.length, equals(initialCount + 1));
    });

    test('reviewSubmission updates existing submission with teacher notes', () async {
      await service.init();
      final sub = await service.submitRecitation(
        studentName: 'Zaid',
        surahNumber: 1,
        ayahNumber: 3,
        surahName: 'Al-Fatiha',
        textUthmani: 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        aiScore: 75.0,
        aiGrade: 'Good',
      );

      final reviewed = await service.reviewSubmission(
        sub.id,
        teacherName: 'Ustadz Ali',
        teacherScore: 85.0,
        status: TashihStatus.approved,
        tajweedNotes: 'Good tajweed',
        makhrajNotes: 'Clear Haa',
        generalNotes: 'Barakallah',
      );

      expect(reviewed, isNotNull);
      expect(reviewed!.teacherScore, equals(85.0));
      expect(reviewed.status, equals(TashihStatus.approved));
      expect(reviewed.tajweedNotes, equals('Good tajweed'));
    });
  });
}
