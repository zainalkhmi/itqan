import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/ijazah_models.dart';

final ijazahServiceProvider = Provider<IjazahService>((ref) {
  return IjazahService();
});

class IjazahService {
  static const String boxName = 'ijazah_box';
  Box? _box;
  final Map<String, IjazahCertificate> _memoryFallback = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      if (!Hive.isBoxOpen(boxName)) {
        _box = await Hive.openBox(boxName);
      } else {
        _box = Hive.box(boxName);
      }
    } catch (_) {}

    if (getCertificates().isEmpty) {
      await _seedStarterCertificate();
    }
  }

  List<SanadNode> getSanadChain() => const [
    SanadNode(
      id: 'gen_0',
      generation: 0,
      name: 'Prophet Muhammad ﷺ',
      arabicName: 'النبي محمد ﷺ',
      role: 'The Messenger of Allah',
      city: 'Makkah & Madinah',
      deathYearH: '11 H',
      notes: 'Received revelation through Jibril عليه السلام directly from Allah سبحانه وتعالى.',
    ),
    SanadNode(
      id: 'gen_1',
      generation: 1,
      name: 'Uthman bin \'Affan & Ali bin Abi Thalib',
      arabicName: 'عثمان بن عفان وعلي بن أبي طالب',
      role: 'Ashab an-Nabi (Sahabah)',
      city: 'Madinah al-Munawwarah',
      deathYearH: '35 H / 40 H',
      notes: 'Prominent companions and reciters of the Prophet ﷺ who oversaw Quranic compilation.',
    ),
    SanadNode(
      id: 'gen_2',
      generation: 2,
      name: 'Abu \'Abdurrahman As-Sulami',
      arabicName: 'أبو عبد الرحمن السلمي',
      role: 'Kibar at-Tabi\'in',
      city: 'Kufah',
      deathYearH: '74 H',
      notes: 'Taught the Quran in the Grand Mosque of Kufah for over 40 continuous years.',
    ),
    SanadNode(
      id: 'gen_3',
      generation: 3,
      name: 'Imam \'Asim bin Abi an-Najud',
      arabicName: 'عاصم بن أبي النَّجود الكوفي',
      role: 'Imam of the Ten Qira\'at',
      city: 'Kufah',
      deathYearH: '127 H',
      notes: 'One of the canonical seven reciters, known for meticulous tajweed and eloquent Arabic.',
    ),
    SanadNode(
      id: 'gen_4',
      generation: 4,
      name: 'Imam Hafs bin Sulayman',
      arabicName: 'حفص بن سليمان بن المغيرة',
      role: 'Rawi of Imam \'Asim',
      city: 'Kufah / Baghdad',
      deathYearH: '180 H',
      notes: 'Primary student of \'Asim whose riwayah became the standard worldwide recitation.',
    ),
    SanadNode(
      id: 'gen_27',
      generation: 27,
      name: 'Shaykh Ahmad bin Abdul Aziz Az-Zayyat',
      arabicName: 'الشيخ أحمد بن عبد العزيز الزيات',
      role: 'Grand Shaykh of Reciters (Egypt)',
      city: 'Cairo / Madinah',
      deathYearH: '1424 H (2003 CE)',
      notes: 'Highest sanad holder in the Muslim world of his era, teacher of foremost modern scholars.',
    ),
    SanadNode(
      id: 'gen_28',
      generation: 28,
      name: 'Dr. Shaykh Ayman Rushdi Suwayd',
      arabicName: 'أ.د. الشيخ أيمن رشدي سويد',
      role: 'Leading Contemporary Tajweed Authority',
      city: 'Damascus / Jeddah',
      deathYearH: 'Living (حفظه الله)',
      notes: 'Holds the 28th degree transmission chain and author of At-Tajwid al-Musawwar.',
    ),
    SanadNode(
      id: 'gen_29',
      generation: 29,
      name: 'Ahmad Santri (Student / App User)',
      arabicName: 'أحمد القارئ',
      role: 'Certified Graduate (Mujaz)',
      city: 'Jakarta, Indonesia',
      deathYearH: 'Active Reciter',
      notes: 'Completed complete recitation verification with Itqan Tajweed Mastery validation.',
    ),
  ];

  List<IjazahCertificate> getCertificates() {
    if (_box != null && _box!.isOpen) {
      return _box!.values
          .map((v) => IjazahCertificate.fromMap(Map<String, dynamic>.from(v as Map)))
          .toList();
    }
    return _memoryFallback.values.toList();
  }

  Future<void> issueCertificate(IjazahCertificate cert) async {
    if (_box != null && _box!.isOpen) {
      await _box!.put(cert.id, cert.toMap());
    } else {
      _memoryFallback[cert.id] = cert;
    }
  }

  bool verifyCertificate(String hash) {
    final all = getCertificates();
    return all.any((c) => c.verificationHash.toLowerCase() == hash.toLowerCase() || c.id == hash);
  }

  Future<void> _seedStarterCertificate() async {
    final starter = IjazahCertificate(
      id: 'IJZ-2026-0849',
      studentName: 'Ahmad Santri',
      riwayah: 'Hafs \'an \'Asim (via Shatibiyyah)',
      title: 'Sanad Tilawah & Tahfizh Juz 30',
      presidingShaykh: 'Dr. Shaykh Ayman Rushdi Suwayd',
      generationDegree: 29,
      grade: 'Mumtaz Ma\'a Martabatil Syaraf',
      issueDate: DateTime.now().subtract(const Duration(days: 12)),
      verificationHash: 'sha256-itqan-7f8e9a2b4c1d6e',
      isVerified: true,
    );
    await issueCertificate(starter);
  }
}

