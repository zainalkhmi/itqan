import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/tashih_submission.dart';

final tashihServiceProvider = Provider<TashihService>((ref) {
  return TashihService();
});

class TashihService {
  static const String boxName = 'tashih_submissions';
  Box? _box;
  final Map<String, TashihSubmission> _memoryFallback = {};
  bool _initialized = false;
  String _currentRole = 'student'; // 'student' or 'teacher'
  String _currentUserName = 'Ahmad Santri';

  String get currentRole => _currentRole;
  String get currentUserName => _currentUserName;

  void setRole(String role) {
    _currentRole = role;
  }

  void setUserName(String name) {
    _currentUserName = name;
  }

  Future<void> init() async {
    if (_initialized && ((_box != null && _box!.isOpen) || _memoryFallback.isNotEmpty)) return;
    _initialized = true;
    try {
      if (!Hive.isBoxOpen(boxName)) {
        _box = await Hive.openBox(boxName);
      } else {
        _box = Hive.box(boxName);
      }
    } catch (_) {
      // Memory fallback for test runs
    }

    if (getAllSubmissions().isEmpty) {
      await seedSampleSubmissions();
    }
  }

  List<TashihSubmission> getAllSubmissions() {
    if (_box != null && _box!.isOpen) {
      final list = _box!.values
          .map((v) => TashihSubmission.fromMap(Map<String, dynamic>.from(v as Map)))
          .toList();
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    }
    final list = _memoryFallback.values.toList();
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  List<TashihSubmission> getStudentSubmissions(String studentName) {
    return getAllSubmissions()
        .where((s) => s.studentName.toLowerCase() == studentName.toLowerCase() || studentName.isEmpty)
        .toList();
  }

  List<TashihSubmission> getPendingSubmissions() {
    return getAllSubmissions().where((s) => s.status == TashihStatus.pending).toList();
  }

  Future<TashihSubmission> submitRecitation({
    required String studentName,
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
    required String textUthmani,
    required double aiScore,
    required String aiGrade,
    String? audioPath,
  }) async {
    await init();
    final id = 'sub_${DateTime.now().millisecondsSinceEpoch}';
    final submission = TashihSubmission(
      id: id,
      studentId: 'std_${studentName.hashCode.abs()}',
      studentName: studentName,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      textUthmani: textUthmani,
      aiScore: aiScore,
      aiGrade: aiGrade,
      audioPath: audioPath,
      submittedAt: DateTime.now(),
      status: TashihStatus.pending,
    );

    if (_box != null && _box!.isOpen) {
      await _box!.put(id, submission.toMap());
    } else {
      _memoryFallback[id] = submission;
    }

    return submission;
  }

  Future<TashihSubmission?> reviewSubmission(
    String id, {
    required String teacherName,
    required double teacherScore,
    required TashihStatus status,
    String? tajweedNotes,
    String? makhrajNotes,
    String? generalNotes,
  }) async {
    await init();
    TashihSubmission? sub;
    if (_box != null && _box!.isOpen && _box!.containsKey(id)) {
      sub = TashihSubmission.fromMap(Map<String, dynamic>.from(_box!.get(id) as Map));
    } else if (_memoryFallback.containsKey(id)) {
      sub = _memoryFallback[id];
    }

    if (sub == null) return null;

    final updated = sub.copyWith(
      teacherId: 'tch_${teacherName.hashCode.abs()}',
      teacherName: teacherName,
      teacherScore: teacherScore,
      status: status,
      tajweedNotes: tajweedNotes,
      makhrajNotes: makhrajNotes,
      generalNotes: generalNotes,
      reviewedAt: DateTime.now(),
    );

    if (_box != null && _box!.isOpen) {
      await _box!.put(id, updated.toMap());
    } else {
      _memoryFallback[id] = updated;
    }

    return updated;
  }

  Future<void> seedSampleSubmissions() async {
    final now = DateTime.now();
    final samples = [
      TashihSubmission(
        id: 'sub_sample_1',
        studentId: 'std_1',
        studentName: 'Ahmad Santri',
        surahNumber: 1,
        ayahNumber: 2,
        surahName: 'Al-Fatiha',
        textUthmani: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
        aiScore: 84.0,
        aiGrade: 'Very Good',
        submittedAt: now.subtract(const Duration(hours: 3)),
        status: TashihStatus.pending,
      ),
      TashihSubmission(
        id: 'sub_sample_2',
        studentId: 'std_1',
        studentName: 'Ahmad Santri',
        surahNumber: 1,
        ayahNumber: 1,
        surahName: 'Al-Fatiha',
        textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        aiScore: 92.0,
        aiGrade: 'Excellent',
        submittedAt: now.subtract(const Duration(days: 1)),
        status: TashihStatus.approved,
        teacherId: 'tch_1',
        teacherName: 'Ustadz Abdullah, Lc.',
        teacherScore: 95.0,
        tajweedNotes: 'Ghunnah pada basmalah dan Madd Arid Lissukun sudah sangat tepat 4 harakat.',
        makhrajNotes: 'Huruf Haa (ح) pada ar-Rahman bersih dari pangkal tenggorokan.',
        generalNotes: 'Mumtaz! Lanjutkan hafalan ke ayat berikutnya.',
        reviewedAt: now.subtract(const Duration(hours: 20)),
      ),
      TashihSubmission(
        id: 'sub_sample_3',
        studentId: 'std_2',
        studentName: 'Fathima Azzahra',
        surahNumber: 112,
        ayahNumber: 1,
        surahName: 'Al-Ikhlas',
        textUthmani: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
        aiScore: 78.0,
        aiGrade: 'Good',
        submittedAt: now.subtract(const Duration(hours: 5)),
        status: TashihStatus.needsRevision,
        teacherId: 'tch_1',
        teacherName: 'Ustadz Abdullah, Lc.',
        teacherScore: 72.0,
        tajweedNotes: 'Qalqalah Kubra pada huruf Dal (د) saat waqaf kurang mantap pantulannya.',
        makhrajNotes: 'Pastikan pangkal lidah terangkat saat melafalkan huruf Qaf (ق).',
        generalNotes: 'Ulangi rekaman dengan memperhatikan pantulan Qalqalah.',
        reviewedAt: now.subtract(const Duration(hours: 2)),
      ),
    ];

    for (final s in samples) {
      if (_box != null && _box!.isOpen) {
        await _box!.put(s.id, s.toMap());
      } else {
        _memoryFallback[s.id] = s;
      }
    }
  }
}
