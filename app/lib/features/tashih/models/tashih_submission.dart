enum TashihStatus {
  pending,
  approved,
  needsRevision,
}

class TashihSubmission {
  final String id;
  final String studentId;
  final String studentName;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String textUthmani;
  final double aiScore;
  final String aiGrade;
  final String? audioPath;
  final DateTime submittedAt;
  final TashihStatus status;
  final String? teacherId;
  final String? teacherName;
  final double? teacherScore;
  final String? tajweedNotes;
  final String? makhrajNotes;
  final String? generalNotes;
  final DateTime? reviewedAt;

  const TashihSubmission({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.textUthmani,
    required this.aiScore,
    required this.aiGrade,
    this.audioPath,
    required this.submittedAt,
    this.status = TashihStatus.pending,
    this.teacherId,
    this.teacherName,
    this.teacherScore,
    this.tajweedNotes,
    this.makhrajNotes,
    this.generalNotes,
    this.reviewedAt,
  });

  String get statusLabel {
    switch (status) {
      case TashihStatus.pending:
        return 'Pending Review';
      case TashihStatus.approved:
        return 'Approved (Mumtaz)';
      case TashihStatus.needsRevision:
        return 'Needs Revision';
    }
  }

  TashihSubmission copyWith({
    String? id,
    String? studentId,
    String? studentName,
    int? surahNumber,
    int? ayahNumber,
    String? surahName,
    String? textUthmani,
    double? aiScore,
    String? aiGrade,
    String? audioPath,
    DateTime? submittedAt,
    TashihStatus? status,
    String? teacherId,
    String? teacherName,
    double? teacherScore,
    String? tajweedNotes,
    String? makhrajNotes,
    String? generalNotes,
    DateTime? reviewedAt,
  }) {
    return TashihSubmission(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      surahName: surahName ?? this.surahName,
      textUthmani: textUthmani ?? this.textUthmani,
      aiScore: aiScore ?? this.aiScore,
      aiGrade: aiGrade ?? this.aiGrade,
      audioPath: audioPath ?? this.audioPath,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      teacherScore: teacherScore ?? this.teacherScore,
      tajweedNotes: tajweedNotes ?? this.tajweedNotes,
      makhrajNotes: makhrajNotes ?? this.makhrajNotes,
      generalNotes: generalNotes ?? this.generalNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'surahName': surahName,
    'textUthmani': textUthmani,
    'aiScore': aiScore,
    'aiGrade': aiGrade,
    'audioPath': audioPath,
    'submittedAt': submittedAt.toIso8601String(),
    'status': status.name,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'teacherScore': teacherScore,
    'tajweedNotes': tajweedNotes,
    'makhrajNotes': makhrajNotes,
    'generalNotes': generalNotes,
    'reviewedAt': reviewedAt?.toIso8601String(),
  };

  factory TashihSubmission.fromMap(Map map) => TashihSubmission(
    id: map['id']?.toString() ?? '',
    studentId: map['studentId']?.toString() ?? 'student_1',
    studentName: map['studentName']?.toString() ?? 'Student',
    surahNumber: (map['surahNumber'] as num?)?.toInt() ?? 1,
    ayahNumber: (map['ayahNumber'] as num?)?.toInt() ?? 1,
    surahName: map['surahName']?.toString() ?? '',
    textUthmani: map['textUthmani']?.toString() ?? '',
    aiScore: (map['aiScore'] as num?)?.toDouble() ?? 0.0,
    aiGrade: map['aiGrade']?.toString() ?? 'Good',
    audioPath: map['audioPath']?.toString(),
    submittedAt: map['submittedAt'] != null
        ? DateTime.parse(map['submittedAt'])
        : DateTime.now(),
    status: TashihStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => TashihStatus.pending,
    ),
    teacherId: map['teacherId']?.toString(),
    teacherName: map['teacherName']?.toString(),
    teacherScore: (map['teacherScore'] as num?)?.toDouble(),
    tajweedNotes: map['tajweedNotes']?.toString(),
    makhrajNotes: map['makhrajNotes']?.toString(),
    generalNotes: map['generalNotes']?.toString(),
    reviewedAt: map['reviewedAt'] != null
        ? DateTime.parse(map['reviewedAt'])
        : null,
  );
}

