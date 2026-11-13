import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class TajweedRuleItem {
  final String title;
  final String titleArabic;
  final String description;
  final String category;
  final Color color;
  final List<String> examples;
  final String countsOrDetail;

  const TajweedRuleItem({
    required this.title,
    required this.titleArabic,
    required this.description,
    required this.category,
    required this.color,
    required this.examples,
    required this.countsOrDetail,
  });
}

class MakhrajLetterItem {
  final String letter;
  final String name;
  final String articulationArea;
  final String description;
  final String exampleWord;
  final String transliteration;

  const MakhrajLetterItem({
    required this.letter,
    required this.name,
    required this.articulationArea,
    required this.description,
    required this.exampleWord,
    required this.transliteration,
  });
}

class MinimalPairItem {
  final String letterA;
  final String nameA;
  final String wordA;
  final String letterB;
  final String nameB;
  final String wordB;
  final String contrastDescription;

  const MinimalPairItem({
    required this.letterA,
    required this.nameA,
    required this.wordA,
    required this.letterB,
    required this.nameB,
    required this.wordB,
    required this.contrastDescription,
  });
}

class QuizQuestion {
  final String question;
  final String sampleWord;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.sampleWord,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class LearningData {
  static const List<TajweedRuleItem> tajweedRules = [
    TajweedRuleItem(
      title: 'Idgham (Merging)',
      titleArabic: 'الإدغام',
      description: 'Merging of Nun Sakinah or Tanween into one of the letters of يَرْمَلُون (Ya, Ra, Meem, Lam, Waw, Nun).',
      category: 'Nun Sakinah & Tanween',
      color: ItqanColors.tajweedIdgham,
      examples: ['مَن يَقُولُ', 'مِن رَّبِّهِمْ', 'مِّن مَّالٍ'],
      countsOrDetail: 'With Ghunnah (ي، ن، م، و) for 2 counts; Without Ghunnah (ل، ر)',
    ),
    TajweedRuleItem(
      title: 'Ikhfa (Concealment)',
      titleArabic: 'الإخفاء الحقيقي',
      description: 'Pronouncing Nun Sakinah or Tanween between Izhar and Idgham with Ghunnah sustained for 2 counts before 15 specific letters.',
      category: 'Nun Sakinah & Tanween',
      color: ItqanColors.tajweedIkhfa,
      examples: ['مِن قَبْلُ', 'أَنفُسَهُمْ', 'كِتَـٰبٌ كَرِيمٌ'],
      countsOrDetail: 'Hold nasalization for 2 full counts (~400-500ms)',
    ),
    TajweedRuleItem(
      title: 'Iqlab (Conversion)',
      titleArabic: 'الإقلاب',
      description: 'Converting Nun Sakinah or Tanween into a concealed Meem with Ghunnah when followed by the letter Ba (ب).',
      category: 'Nun Sakinah & Tanween',
      color: ItqanColors.tajweedIqlab,
      examples: ['مِنۢ بَعْدِ', 'عَلِيمٌۢ بِذَاتِ'],
      countsOrDetail: 'Conceal lips lightly with 2 counts Ghunnah',
    ),
    TajweedRuleItem(
      title: 'Madd (Elongation)',
      titleArabic: 'المدود',
      description: 'Prolonging the sound of the madd letters (Alif, Waw, Ya) based on succeeding hamzah, sukun, or shaddah.',
      category: 'Elongation',
      color: ItqanColors.tajweedMadd,
      examples: ['ٱلسَّمَآءِ', 'جَآءَ', 'ٱلضَّآلِّينَ'],
      countsOrDetail: 'Tabee’i: 2 counts • Muttasil/Munfasil: 4-5 counts • Lazim: 6 counts',
    ),
    TajweedRuleItem(
      title: 'Qalqalah (Echo / Bouncing)',
      titleArabic: 'القلقلة',
      description: 'An acoustic echoing vibration produced when pronouncing the 5 letters of قُطْبُ جَدٍّ when they carry a sukun or when stopping (waqf).',
      category: 'Articulation',
      color: ItqanColors.tajweedQalqalah,
      examples: ['قُلْ هُوَ ٱللَّهُ أَحَدٌ', 'ٱلْفَلَقِ', 'مُّحِيطٌ'],
      countsOrDetail: 'Sughra (in word) or Kubra (strong echo at stop/waqf)',
    ),
    TajweedRuleItem(
      title: 'Ghunnah (Nasalization)',
      titleArabic: 'الغنة',
      description: 'A melodious nasal resonance emitted from the cavity of the nose (Al-Khaisyum) on Nun and Meem with Shaddah.',
      category: 'Nasalization',
      color: ItqanColors.tajweedGhunnah,
      examples: ['إِنَّ ٱللَّهَ', 'ثُمَّ', 'ٱلنَّاسِ'],
      countsOrDetail: 'Held consistently for 2 full harakat counts (~450ms)',
    ),
  ];

  static const List<MakhrajLetterItem> makhrajLetters = [
    MakhrajLetterItem(
      letter: 'ء / ه',
      name: 'Hamzah & Hā’',
      articulationArea: 'Deep Throat (Aqsa al-Halq)',
      description: 'Originates from the deepest part of the throat near the vocal cords.',
      exampleWord: 'أَهْلِ',
      transliteration: 'Ahli',
    ),
    MakhrajLetterItem(
      letter: 'ع / ح',
      name: '‘Ayn & Ḥā’',
      articulationArea: 'Middle Throat (Wasat al-Halq)',
      description: 'Produced by contracting the middle throat muscles without raspiness.',
      exampleWord: 'ٱلْعَـٰلَمِينَ',
      transliteration: 'Al-‘Alameen',
    ),
    MakhrajLetterItem(
      letter: 'غ / خ',
      name: 'Ghayn & Khā’',
      articulationArea: 'Upper Throat (Adna al-Halq)',
      description: 'Nearest to the mouth; produced with elevation of posterior tongue.',
      exampleWord: 'خَبِيرٌ',
      transliteration: 'Khabeer',
    ),
    MakhrajLetterItem(
      letter: 'ق',
      name: 'Qāf',
      articulationArea: 'Deep Tongue (Aqsa al-Lisan)',
      description: 'Deepest part of tongue touching the uvula and soft palate with elevation.',
      exampleWord: 'قُلْ',
      transliteration: 'Qul',
    ),
    MakhrajLetterItem(
      letter: 'ك',
      name: 'Kāf',
      articulationArea: 'Back Tongue (Aqsa al-Lisan)',
      description: 'Slightly forward from Qaf, touching the hard palate with slight breath (Hams).',
      exampleWord: 'كِتَـٰبٌ',
      transliteration: 'Kitaab',
    ),
    MakhrajLetterItem(
      letter: 'ض',
      name: 'Ḍād',
      articulationArea: 'Tongue Edge (Hafat al-Lisan)',
      description: 'Side/flank of tongue pressed against upper molars with elongation (Istitalah).',
      exampleWord: 'ٱلضَّآلِّينَ',
      transliteration: 'Ad-Daaalleen',
    ),
    MakhrajLetterItem(
      letter: 'ص / س / ز',
      name: 'Ṣād, Seen, Zāy',
      articulationArea: 'Tip of Tongue (Raraf al-Lisan)',
      description: 'Tip of tongue rested behind lower incisors creating a whistle resonance (Safeer).',
      exampleWord: 'صِرَاطَ',
      transliteration: 'Siraata',
    ),
  ];

  static const List<MinimalPairItem> minimalPairs = [
    MinimalPairItem(
      letterA: 'ص',
      nameA: 'Ṣād (Emphatic)',
      wordA: 'صِرَاطَ',
      letterB: 'س',
      nameB: 'Seen (Soft)',
      wordB: 'سِرَاطَ',
      contrastDescription: 'Ṣād elevates the back tongue (Isti‘la) creating full resonance, whereas Seen is soft and flat.',
    ),
    MinimalPairItem(
      letterA: 'ح',
      nameA: 'Ḥā’ (Middle Throat)',
      wordA: 'ٱلرَّحْمَـٰنِ',
      letterB: 'ه',
      nameB: 'Hā’ (Deep Chest)',
      wordB: 'ٱلرَّهْمَـٰنِ',
      contrastDescription: 'Ḥā’ is constricted from middle throat; Hā’ emerges lightly from bottom of throat without tension.',
    ),
    MinimalPairItem(
      letterA: 'ط',
      nameA: 'Ṭā’ (Heavy / Elevated)',
      wordA: 'طَيِّبَاتِ',
      letterB: 'ت',
      nameB: 'Tā’ (Light / Breath)',
      wordB: 'تَيِّبَاتِ',
      contrastDescription: 'Ṭā’ is the heaviest Arabic letter with strong elevation; Tā’ is light with soft whisper (Hams).',
    ),
    MinimalPairItem(
      letterA: 'ض',
      nameA: 'Ḍād (Molar Press)',
      wordA: 'ضَلَّ',
      letterB: 'د',
      nameB: 'Dāl (Tongue Tip)',
      wordB: 'دَلَّ',
      contrastDescription: 'Ḍād uses the side of the tongue along molars; Dāl uses only the tip against upper incisors.',
    ),
    MinimalPairItem(
      letterA: 'ق',
      nameA: 'Qāf (Soft Palate)',
      wordA: 'قَلْبٍ',
      letterB: 'ك',
      nameB: 'Kāf (Hard Palate)',
      wordB: 'كَلْبٍ',
      contrastDescription: 'Qāf elevates deeply without breath; Kāf touches hard palate with slight breath release.',
    ),
    MinimalPairItem(
      letterA: 'ع',
      nameA: '‘Ayn (Throat Squeeze)',
      wordA: 'عَلِيمٌ',
      letterB: 'ء',
      nameB: 'Hamzah (Vocal Stop)',
      wordB: 'أَلِيمٌ',
      contrastDescription: '‘Ayn compresses the epiglottis in middle throat; Hamzah is a sharp vocal cord stop.',
    ),
  ];

  static const List<QuizQuestion> quizQuestions = [
    QuizQuestion(
      question: 'Which Tajweed rule applies to the word below due to the Nun Sakinah followed by Qaf?',
      sampleWord: 'مِن قَبْلُ',
      options: ['Izhar', 'Ikhfa', 'Idgham', 'Iqlab'],
      correctIndex: 1,
      explanation: 'Qaf (ق) is one of the 15 letters of Ikhfa. The Nun Sakinah is concealed with a 2-count Ghunnah.',
    ),
    QuizQuestion(
      question: 'What is the required elongation count (harakat) for Madd Lazim in the word below?',
      sampleWord: 'ٱلضَّآلِّينَ',
      options: ['2 counts', '4 counts', '6 counts', '1 count'],
      correctIndex: 2,
      explanation: 'Madd Lazim occurs when a madd letter is followed by an original shaddah or sukun, requiring exactly 6 counts.',
    ),
    QuizQuestion(
      question: 'Identify the Qalqalah letter carrying sukun in this verse:',
      sampleWord: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
      options: ['Qaf (ق)', 'Lam (ل)', 'Dal (د) at stop', 'Ha (ه)'],
      correctIndex: 2,
      explanation: 'When stopping at the end of the ayah on Ahad (أَحَدٌ), Dal (د) receives a temporary sukun, producing strong Qalqalah Kubra.',
    ),
    QuizQuestion(
      question: 'Which articulation area (Makhraj) produces the letters ‘Ayn (ع) and Ḥā’ (ح)?',
      sampleWord: 'ٱلْعَـٰلَمِينَ',
      options: ['Adna al-Halq (Upper)', 'Wasat al-Halq (Middle Throat)', 'Al-Lisan (Tongue)', 'Ash-Shafatain (Lips)'],
      correctIndex: 1,
      explanation: 'Both ‘Ayn and Ḥā’ originate precisely from Wasat al-Halq (the middle part of the throat).',
    ),
  ];
}

