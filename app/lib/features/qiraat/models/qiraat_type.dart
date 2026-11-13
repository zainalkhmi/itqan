enum QiraatRiwayah {
  hafs, // Hafs 'an 'Asim (Standard / Majority)
  warsh, // Warsh 'an Nafi' (North & West Africa)
  qalun, // Qalun 'an Nafi' (Libya, Tunisia)
  duri, // Ad-Duri 'an Abi 'Amr (Sudan, Somalia, Yemen)
}

class QiraatReciter {
  final String id;
  final String name;
  final String arabicName;
  final String audioBaseUrl;

  const QiraatReciter({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.audioBaseUrl,
  });
}

class QiraatInfo {
  final QiraatRiwayah riwayah;
  final String name;
  final String arabicName;
  final String imam;
  final String rawi;
  final String primaryRegion;
  final String description;
  final List<String> phoneticRules;
  final Map<String, String> sampleDifferences;
  final List<QiraatReciter> reciters;

  const QiraatInfo({
    required this.riwayah,
    required this.name,
    required this.arabicName,
    required this.imam,
    required this.rawi,
    required this.primaryRegion,
    required this.description,
    required this.phoneticRules,
    required this.sampleDifferences,
    required this.reciters,
  });

  String get id => riwayah.name;
}

