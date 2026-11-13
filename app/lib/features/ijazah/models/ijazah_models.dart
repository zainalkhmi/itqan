class SanadNode {
  final String id;
  final String name;
  final String arabicName;
  final int generation; // 0 = Prophet, 1 = Sahabah, etc.
  final String role;
  final String city;
  final String deathYearH;
  final String notes;

  const SanadNode({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.generation,
    required this.role,
    required this.city,
    required this.deathYearH,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'arabicName': arabicName,
    'generation': generation,
    'role': role,
    'city': city,
    'deathYearH': deathYearH,
    'notes': notes,
  };

  factory SanadNode.fromMap(Map map) => SanadNode(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    arabicName: map['arabicName']?.toString() ?? '',
    generation: (map['generation'] as num?)?.toInt() ?? 0,
    role: map['role']?.toString() ?? '',
    city: map['city']?.toString() ?? '',
    deathYearH: map['deathYearH']?.toString() ?? '',
    notes: map['notes']?.toString() ?? '',
  );
}

class IjazahCertificate {
  final String id;
  final String studentName;
  final String riwayah;
  final String title;
  final String presidingShaykh;
  final int generationDegree;
  final String grade;
  final DateTime issueDate;
  final String verificationHash;
  final bool isVerified;

  const IjazahCertificate({
    required this.id,
    required this.studentName,
    required this.riwayah,
    required this.title,
    required this.presidingShaykh,
    required this.generationDegree,
    required this.grade,
    required this.issueDate,
    required this.verificationHash,
    this.isVerified = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentName': studentName,
    'riwayah': riwayah,
    'title': title,
    'presidingShaykh': presidingShaykh,
    'generationDegree': generationDegree,
    'grade': grade,
    'issueDate': issueDate.toIso8601String(),
    'verificationHash': verificationHash,
    'isVerified': isVerified,
  };

  factory IjazahCertificate.fromMap(Map map) => IjazahCertificate(
    id: map['id']?.toString() ?? '',
    studentName: map['studentName']?.toString() ?? '',
    riwayah: map['riwayah']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    presidingShaykh: map['presidingShaykh']?.toString() ?? '',
    generationDegree: (map['generationDegree'] as num?)?.toInt() ?? 28,
    grade: map['grade']?.toString() ?? 'Mumtaz',
    issueDate: map['issueDate'] != null
        ? DateTime.parse(map['issueDate'])
        : DateTime.now(),
    verificationHash: map['verificationHash']?.toString() ?? '',
    isVerified: map['isVerified'] as bool? ?? true,
  );
}
