import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'services/tajweed_service.dart';

// Pre-annotated tajweed rules per word
// Key format: 'surah:ayah:wordIndex' (0-indexed words)
const Map<String, String> tajweedAnnotations = {
  // Al-Fatiha (Surah 1)
  '1:1:0': 'bismillah',    // بِسْمِ
  '1:1:2': 'madd',         // الرَّحْمَٰنِ (madd in rahman)
  '1:1:3': 'ghunnah',      // الرَّحِيمِ
  '1:2:0': 'madd',         // الْحَمْدُ
  '1:3:0': 'madd',         // الرَّحْمَٰنِ
  '1:3:1': 'ghunnah',      // الرَّحِيمِ
  '1:4:0': 'madd',         // مَٰلِكِ
  '1:5:0': 'idgham',       // إِيَّاكَ
  '1:6:0': 'madd',         // اهْدِنَا
  '1:7:2': 'qalqalah',     // الضَّالِّينَ
  // Al-Ikhlas (Surah 112)
  '112:1:0': 'madd',       // قُلْ
  '112:2:0': 'idgham',     // اللَّهُ
  '112:2:1': 'madd',       // الصَّمَدُ
  '112:4:0': 'ghunnah',    // وَلَمْ
};

// Color mapping for each tajweed rule (supporting both legacy names and QUL / API classes)
Color tajweedColor(String rule) {
  if (TajweedService.ruleDefinitions.containsKey(rule)) {
    return TajweedService.ruleDefinitions[rule]!.color;
  }
  return switch (rule) {
    'idgham'              => ItqanColors.tajweedIdgham,
    'idgham_ghunnah'      => Color(0xFF818CF8),
    'idgham_wo_ghunnah'   => Color(0xFF38BDF8),
    'idgham_shafawi'      => Color(0xFF7C3AED),
    'idgham_mutaqaribayn' => Color(0xFF0EA5E9),
    'ikhfa'               => ItqanColors.tajweedIkhfa,
    'ikhafa'              => Color(0xFFA78BFA),
    'ikhafa_shafawi'      => Color(0xFF9333EA),
    'iqlab'               => ItqanColors.tajweedIqlab,
    'madd'                => ItqanColors.tajweedMadd,
    'madda_necessary'     => Color(0xFF2563EB),
    'madda_obligatory'    => Color(0xFF0284C7),
    'madda_permissible'   => Color(0xFF06B6D4),
    'madda_normal'        => Color(0xFF38BDF8),
    'qalqalah'            => ItqanColors.tajweedQalqalah,
    'qalaqah'             => Color(0xFFFBBF24),
    'ghunnah'             => ItqanColors.tajweedGhunnah,
    'ham_wasl'            => Color(0xFF94A3B8),
    'laam_shamsiyah'      => Color(0xFF64748B),
    'slnt'                => Color(0xFF475569),
    'bismillah'           => ItqanColors.gold,
    _                     => ItqanColors.mist,
  };
}

// Human-readable names
String tajweedRuleName(String rule) {
  if (TajweedService.ruleDefinitions.containsKey(rule)) {
    return TajweedService.ruleDefinitions[rule]!.name;
  }
  return switch (rule) {
    'idgham'    => 'Idgham — Merging',
    'ikhfa'     => 'Ikhfa — Concealment',
    'iqlab'     => 'Iqlab — Conversion',
    'madd'      => 'Madd — Elongation',
    'qalqalah'  => 'Qalqalah — Echo',
    'ghunnah'   => 'Ghunnah — Nasalization',
    'bismillah' => 'Basmalah',
    _           => rule,
  };
}

// Brief explanations for word detail sheet
String tajweedExplanation(String rule) {
  if (TajweedService.ruleDefinitions.containsKey(rule)) {
    return TajweedService.ruleDefinitions[rule]!.description;
  }
  return switch (rule) {
    'idgham'    => 'The nun saakin or tanween merges into the following letter.',
    'ikhfa'     => 'The nun saakin or tanween is concealed before certain letters.',
    'iqlab'     => 'The nun saakin or tanween is converted to a meem sound.',
    'madd'      => 'The vowel is elongated for 2, 4, or 6 counts.',
    'qalqalah'  => 'A slight echoing vibration is produced on the letter.',
    'ghunnah'   => 'A nasal sound produced through the nose for 2 counts.',
    'bismillah' => 'The opening invocation of God\'s name.',
    _           => '',
  };
}
