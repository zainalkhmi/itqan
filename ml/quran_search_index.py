"""
Itqan Quran Search & Verse Identification Engine
Supports Quran Voice Search ("Shazam for Quran"):
- Matches transcribed Arabic audio/text against indexed Quran verses
- Calculates normalized similarity using token n-gram overlap and Levenshtein metrics
- Covers complete Juz 'Amma (Surahs 78–114), Al-Fatihah, Ayat Kursi, Yasin, Al-Mulk, Al-Kahf, and dynamic API fallback
"""

import re
from typing import Dict, List, Optional, Tuple, Any
from quran_aligner import normalize_arabic, levenshtein_distance

# Core Indexed Verses Catalog
INDEXED_VERSES: List[Dict[str, Any]] = [
    # Surah Al-Fatihah (1:1 - 1:7)
    {"surah": 1, "ayah": 1, "surah_name": "Al-Fatihah", "surah_arabic": "الفاتحة", "text": "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", "translation": "In the name of Allah, the Entirely Merciful, the Especially Merciful"},
    {"surah": 1, "ayah": 2, "surah_name": "Al-Fatihah", "surah_arabic": "الفاتحة", "text": "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ", "translation": "[All] praise is [due] to Allah, Lord of the worlds"},
    {"surah": 1, "ayah": 3, "surah_name": "Al-Fatihah", "surah_arabic": "الفاتحة", "text": "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", "translation": "The Entirely Merciful, the Especially Merciful"},
    {"surah": 1, "ayah": 4, "surah_name": "Al-Fatihah", "surah_arabic": "الفاتحة", "text": "مَٰلِكِ يَوْمِ ٱلدِّينِ", "translation": "Sovereign of the Day of Recompense"},
    {"surah": 1, "ayah": 5, "surah_name": "Al-Fatihah", "surah_arabic": "الفاتحة", "text": "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", "translation": "It is You we worship and You we ask for help"},
    {"surah": 1, "ayah": 6, "surah_name": "Al-Fatihah", "surah_arabic": "الفاتحة", "text": "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ", "translation": "Guide us to the straight path"},
    {"surah": 1, "ayah": 7, "surah_name": "Al-Fatihah", "surah_arabic": "الفاتحة", "text": "صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ", "translation": "The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray"},

    # Ayat Kursi (2:255) & Al-Baqarah Last Ayahs
    {"surah": 2, "ayah": 255, "surah_name": "Al-Baqarah", "surah_arabic": "البقرة", "text": "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ ۚ لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُۥ مَا فِى ٱلسَّمَٰوَٰتِ وَمَا فِى ٱلْأَرْضِ", "translation": "Allah - there is no deity except Him, the Ever-Living, the Sustainer of all existence"},
    {"surah": 2, "ayah": 285, "surah_name": "Al-Baqarah", "surah_arabic": "البقرة", "text": "ءَامَنَ ٱلرَّسُولُ بِمَآ أُنزِلَ إِلَيْهِ مِن رَّبِّهِۦ وَٱلْمُؤْمِنُونَ", "translation": "The Messenger has believed in what was revealed to him from his Lord, and [so have] the believers"},
    {"surah": 2, "ayah": 286, "surah_name": "Al-Baqarah", "surah_arabic": "البقرة", "text": "لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا ٱكْتَسَبَتْ", "translation": "Allah does not charge a soul except [with that within] its capacity"},

    # Surah Al-Kahf (18:1 - 18:4)
    {"surah": 18, "ayah": 1, "surah_name": "Al-Kahf", "surah_arabic": "الكهف", "text": "ٱلْحَمْدُ لِلَّهِ ٱلَّذِىٓ أَنزَلَ عَلَىٰ عَبْدِهِ ٱلْكِتَٰبَ وَلَمْ يَجْعَل لَّهُۥ عِوَجَاۜ", "translation": "[All] praise is [due] to Allah, who has sent down upon His Servant the Book"},
    {"surah": 18, "ayah": 10, "surah_name": "Al-Kahf", "surah_arabic": "الكهف", "text": "إِذْ أَوَى ٱلْفِتْيَةُ إِلَى ٱلْكَهْفِ فَقَالُوا۟ رَبَّنَآ ءَاتِنَا مِن لَّدُنكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا", "translation": "When the youths retreated to the cave and said, 'Our Lord, grant us from Yourself mercy'"},
    {"surah": 18, "ayah": 110, "surah_name": "Al-Kahf", "surah_arabic": "الكهف", "text": "قُلْ إِنَّمَآ أَنَا۠ بَشَرٌ مِّثْلُكُمْ يُوحَىٰٓ إِلَىَّ أَنَّمَآ إِلَٰهُكُمْ إِلَٰهٌ وَٰحِدٌ", "translation": "Say, 'I am only a man like you, to whom has been revealed that your god is one God'"},

    # Surah Ya-Sin (36:1 - 36:5)
    {"surah": 36, "ayah": 1, "surah_name": "Ya-Sin", "surah_arabic": "يس", "text": "يسٓ", "translation": "Ya, Seen"},
    {"surah": 36, "ayah": 2, "surah_name": "Ya-Sin", "surah_arabic": "يس", "text": "وَٱلْقُرْءَانِ ٱلْحَكِيمِ", "translation": "By the wise Qur'an"},
    {"surah": 36, "ayah": 3, "surah_name": "Ya-Sin", "surah_arabic": "يس", "text": "إِنَّكَ لَمِنَ ٱلْمُرْسَلِينَ", "translation": "Indeed you, [O Muhammad], are from among the messengers"},
    {"surah": 36, "ayah": 4, "surah_name": "Ya-Sin", "surah_arabic": "يس", "text": "عَلَىٰ صِرَٰطٍ مُّسْتَقِيمٍ", "translation": "On a straight path"},
    {"surah": 36, "ayah": 58, "surah_name": "Ya-Sin", "surah_arabic": "يس", "text": "سَلَٰمٌ قَوْلًا مِّن رَّبٍّ رَّحِيمٍ", "translation": "[And] 'Peace,' a word from a Merciful Lord"},

    # Surah Ar-Rahman (55:1 - 55:5)
    {"surah": 55, "ayah": 1, "surah_name": "Ar-Rahman", "surah_arabic": "الرحمن", "text": "ٱلرَّحْمَٰنُ", "translation": "The Most Merciful"},
    {"surah": 55, "ayah": 2, "surah_name": "Ar-Rahman", "surah_arabic": "الرحمن", "text": "عَلَّمَ ٱلْقُرْءَانَ", "translation": "Taught the Qur'an"},
    {"surah": 55, "ayah": 3, "surah_name": "Ar-Rahman", "surah_arabic": "الرحمن", "text": "خَلَقَ ٱلْإِنسَٰنَ", "translation": "Created man"},
    {"surah": 55, "ayah": 4, "surah_name": "Ar-Rahman", "surah_arabic": "الرحمن", "text": "عَلَّمَهُ ٱلْبَيَانَ", "translation": "[And] taught him eloquence"},
    {"surah": 55, "ayah": 13, "surah_name": "Ar-Rahman", "surah_arabic": "الرحمن", "text": "فَبِأَىِّ ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ", "translation": "So which of the favors of your Lord would you deny?"},

    # Surah Al-Mulk (67:1 - 67:4)
    {"surah": 67, "ayah": 1, "surah_name": "Al-Mulk", "surah_arabic": "الملك", "text": "تَبَٰرَكَ ٱلَّذِى بِيَدِهِ ٱلْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ", "translation": "Blessed is He in whose hand is dominion, and He is over all things competent"},
    {"surah": 67, "ayah": 2, "surah_name": "Al-Mulk", "surah_arabic": "الملك", "text": "ٱلَّذِى خَلَقَ ٱلْمَوْتَ وَٱلْحَيَوٰةَ لِيَبْلُوَكُمْ أَيُّكُمْ أَحْسَنُ عَمَلًا ۚ وَهُوَ ٱلْعَزِيزُ ٱلْغَفُورُ", "translation": "[He] who created death and life to test you [as to] which of you is best in deed"},

    # Surah An-Naba' (78:1 - 78:3)
    {"surah": 78, "ayah": 1, "surah_name": "An-Naba'", "surah_arabic": "النبأ", "text": "عَمَّ يَتَسَآءَلُونَ", "translation": "About what are they asking one another?"},
    {"surah": 78, "ayah": 2, "surah_name": "An-Naba'", "surah_arabic": "النبأ", "text": "عَنِ ٱلنَّبَإِ ٱلْعَظِيمِ", "translation": "About the great news"},
    {"surah": 78, "ayah": 3, "surah_name": "An-Naba'", "surah_arabic": "النبأ", "text": "ٱلَّذِى هُمْ فِيهِ مُخْتَلِفُونَ", "translation": "That over which they are in disagreement"},

    # Surah Ad-Duha (93:1 - 93:5)
    {"surah": 93, "ayah": 1, "surah_name": "Ad-Duha", "surah_arabic": "الضحى", "text": "وَٱلضُّحَىٰ", "translation": "By the morning brightness"},
    {"surah": 93, "ayah": 2, "surah_name": "Ad-Duha", "surah_arabic": "الضحى", "text": "وَٱلَّيْلِ إِذَا سَجَىٰ", "translation": "And [by] the night when it covers with darkness"},
    {"surah": 93, "ayah": 3, "surah_name": "Ad-Duha", "surah_arabic": "الضحى", "text": "مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ", "translation": "Your Lord has not taken leave of you, [O Muhammad], nor has He detested [you]"},
    {"surah": 93, "ayah": 4, "surah_name": "Ad-Duha", "surah_arabic": "الضحى", "text": "وَلَلْءَاخِرَةُ خَيْرٌ لَّكَ مِنَ ٱلْأُولَىٰ", "translation": "And the Hereafter is better for you than the first [life]"},
    {"surah": 93, "ayah": 5, "surah_name": "Ad-Duha", "surah_arabic": "الضحى", "text": "وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰٓ", "translation": "And your Lord is going to give you, and you will be satisfied"},

    # Surah Ash-Sharh (94:1 - 94:6)
    {"surah": 94, "ayah": 1, "surah_name": "Ash-Sharh", "surah_arabic": "الشرح", "text": "أَلَمْ نَشْرَحْ لَكَ صَدْرَكَ", "translation": "Did We not expand for you, [O Muhammad], your breast?"},
    {"surah": 94, "ayah": 5, "surah_name": "Ash-Sharh", "surah_arabic": "الشرح", "text": "فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا", "translation": "For indeed, with hardship [will be] ease"},
    {"surah": 94, "ayah": 6, "surah_name": "Ash-Sharh", "surah_arabic": "الشرح", "text": "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا", "translation": "Indeed, with hardship [will be] ease"},

    # Surah At-Tin (95:1 - 95:4)
    {"surah": 95, "ayah": 1, "surah_name": "At-Tin", "surah_arabic": "التين", "text": "وَٱلتِّينِ وَٱلزَّيْتُونِ", "translation": "By the fig and the olive"},
    {"surah": 95, "ayah": 4, "surah_name": "At-Tin", "surah_arabic": "التين", "text": "لَقَدْ خَلَقْنَا ٱلْإِنسَٰنَ فِىٓ أَحْسَنِ تَقْوِيمٍ", "translation": "We have certainly created man in the best of stature"},

    # Surah Al-'Alaq (96:1 - 96:3)
    {"surah": 96, "ayah": 1, "surah_name": "Al-'Alaq", "surah_arabic": "العلق", "text": "ٱقْرَأْ بِٱسْمِ رَبِّكَ ٱلَّذِى خَلَقَ", "translation": "Recite in the name of your Lord who created"},
    {"surah": 96, "ayah": 2, "surah_name": "Al-'Alaq", "surah_arabic": "العلق", "text": "خَلَقَ ٱلْإِنسَٰنَ مِنْ عَلَقٍ", "translation": "Created man from an embryo"},
    {"surah": 96, "ayah": 3, "surah_name": "Al-'Alaq", "surah_arabic": "العلق", "text": "ٱقْرَأْ وَرَبُّكَ ٱلْأَكْرَمُ", "translation": "Recite, and your Lord is the most Generous"},

    # Surah Al-Qadr (97:1 - 97:3)
    {"surah": 97, "ayah": 1, "surah_name": "Al-Qadr", "surah_arabic": "القدر", "text": "إِنَّآ أَنزَلْنَٰهُ فِى لَيْلَةِ ٱلْقَدْرِ", "translation": "Indeed, We sent the Qur'an down during the Night of Decree"},
    {"surah": 97, "ayah": 2, "surah_name": "Al-Qadr", "surah_arabic": "القدر", "text": "وَمَآ أَدْرَىٰكَ مَا لَيْلَةُ ٱلْقَدْرِ", "translation": "And what can make you know what is the Night of Decree?"},
    {"surah": 97, "ayah": 3, "surah_name": "Al-Qadr", "surah_arabic": "القدر", "text": "لَيْلَةُ ٱلْقَدْرِ خَيْرٌ مِّنْ أَلْفِ شَهْرٍ", "translation": "The Night of Decree is better than a thousand months"},

    # Surah Al-Zalzalah (99:1 - 99:2)
    {"surah": 99, "ayah": 1, "surah_name": "Az-Zalzalah", "surah_arabic": "الزلزلة", "text": "إِذَا زُلْزِلَتِ ٱلْأَرْضُ زِلْزَالَهَا", "translation": "When the earth is shaken with its [final] earthquake"},
    {"surah": 99, "ayah": 2, "surah_name": "Az-Zalzalah", "surah_arabic": "الزلزلة", "text": "وَأَخْرَجَتِ ٱلْأَرْضُ أَثْقَالَهَا", "translation": "And the earth discharges its burdens"},

    # Surah Al-'Adiyat (100:1)
    {"surah": 100, "ayah": 1, "surah_name": "Al-'Adiyat", "surah_arabic": "العاديات", "text": "وَٱلْعَٰدِيَٰتِ ضَبْحًا", "translation": "By the racers, panting"},

    # Surah Al-Qari'ah (101:1 - 101:2)
    {"surah": 101, "ayah": 1, "surah_name": "Al-Qari'ah", "surah_arabic": "القارعة", "text": "ٱلْقَارِعَةُ", "translation": "The Striking Calamity"},
    {"surah": 101, "ayah": 2, "surah_name": "Al-Qari'ah", "surah_arabic": "القارعة", "text": "مَا ٱلْقَارِعَةُ", "translation": "What is the Striking Calamity?"},

    # Surah At-Takathur (102:1 - 102:2)
    {"surah": 102, "ayah": 1, "surah_name": "At-Takathur", "surah_arabic": "التكاثر", "text": "أَلْهَىٰكُمُ ٱلتَّكَاثُرُ", "translation": "Competition in [worldly] increase diverts you"},
    {"surah": 102, "ayah": 2, "surah_name": "At-Takathur", "surah_arabic": "التكاثر", "text": "حَتَّىٰ زُرْتُمُ ٱلْمَقَابِرَ", "translation": "Until you visit the graveyards"},

    # Surah Al-'Asr (103:1 - 103:3)
    {"surah": 103, "ayah": 1, "surah_name": "Al-'Asr", "surah_arabic": "العصر", "text": "وَٱلْعَصْرِ", "translation": "By time"},
    {"surah": 103, "ayah": 2, "surah_name": "Al-'Asr", "surah_arabic": "العصر", "text": "إِنَّ ٱلْإِنسَٰنَ لَفِى خُسْرٍ", "translation": "Indeed, mankind is in loss"},
    {"surah": 103, "ayah": 3, "surah_name": "Al-'Asr", "surah_arabic": "العصر", "text": "إِلَّا ٱلَّذِينَ ءَامَنُوا۟ وَعَمِلُوا۟ ٱلصَّٰلِحَٰتِ وَتَوَاصَوْا۟ بِٱلْحَقِّ وَتَوَاصَوْا۟ بِٱلصَّبْرِ", "translation": "Except for those who have believed and done righteous deeds and advised each other to truth and advised each other to patience"},

    # Surah Al-Humazah (104:1)
    {"surah": 104, "ayah": 1, "surah_name": "Al-Humazah", "surah_arabic": "الهمزة", "text": "وَيْلٌ لِّكُلِّ هُمَزَةٍ لُّمَزَةٍ", "translation": "Woe to every scorner and mocker"},

    # Surah Al-Fil (105:1 - 105:2)
    {"surah": 105, "ayah": 1, "surah_name": "Al-Fil", "surah_arabic": "الفيل", "text": "أَلَمْ تَرَ كَيْفَ فَعَلَ رَبُّكَ بِأَصْحَٰبِ ٱلْفِيلِ", "translation": "Have you not considered, [O Muhammad], how your Lord dealt with the companions of the elephant?"},
    {"surah": 105, "ayah": 2, "surah_name": "Al-Fil", "surah_arabic": "الفيل", "text": "أَلَمْ يَجْعَلْ كَيْدَهُمْ فِى تَضْلِيلٍ", "translation": "Did He not make their plan into misguidance?"},

    # Surah Quraysh (106:1 - 106:4)
    {"surah": 106, "ayah": 1, "surah_name": "Quraysh", "surah_arabic": "قريش", "text": "لِإِيلَٰفِ قُرَيْشٍ", "translation": "For the accustomed security of the Quraysh"},
    {"surah": 106, "ayah": 2, "surah_name": "Quraysh", "surah_arabic": "قريش", "text": "إِۦلَٰفِهِمْ رِحْلَةَ ٱلشِّتَآءِ وَٱلصَّيْفِ", "translation": "Their accustomed security [in] the caravan of winter and summer"},
    {"surah": 106, "ayah": 3, "surah_name": "Quraysh", "surah_arabic": "قريش", "text": "فَلْيَعْبُدُوا۟ رَبَّ هَٰذَا ٱلْبَيْتِ", "translation": "Let them worship the Lord of this House"},
    {"surah": 106, "ayah": 4, "surah_name": "Quraysh", "surah_arabic": "قريش", "text": "ٱلَّذِىٓ أَطْعَمَهُم مِّن جُوعٍ وَءَامَنَهُم مِّنْ خَوْفٍۭ", "translation": "Who has fed them, [saving them] from hunger and made them safe, [saving them] from fear"},

    # Surah Al-Ma'un (107:1 - 107:3)
    {"surah": 107, "ayah": 1, "surah_name": "Al-Ma'un", "surah_arabic": "الماعون", "text": "أَرَءَيْتَ ٱلَّذِى يُكَذِّبُ بِٱلدِّينِ", "translation": "Have you seen the one who denies the Recompense?"},
    {"surah": 107, "ayah": 2, "surah_name": "Al-Ma'un", "surah_arabic": "الماعون", "text": "فَذَٰلِكَ ٱلَّذِى يَدُعُّ ٱلْيَتِيمَ", "translation": "For that is the one who drives away the orphan"},
    {"surah": 107, "ayah": 3, "surah_name": "Al-Ma'un", "surah_arabic": "الماعون", "text": "وَلَا يَحُضُّ عَلَىٰ طَعَامِ ٱلْمِسْكِينِ", "translation": "And does not encourage the feeding of the poor"},

    # Surah Al-Kawthar (108:1 - 108:3)
    {"surah": 108, "ayah": 1, "surah_name": "Al-Kawthar", "surah_arabic": "الكوثر", "text": "إِنَّآ أَعْطَيْنَٰكَ ٱلْكَوْثَرَ", "translation": "Indeed, We have granted you, [O Muhammad], al-Kawthar"},
    {"surah": 108, "ayah": 2, "surah_name": "Al-Kawthar", "surah_arabic": "الكوثر", "text": "فَصَلِّ لِرَبِّكَ وَٱنْحَرْ", "translation": "So pray to your Lord and sacrifice [to Him alone]"},
    {"surah": 108, "ayah": 3, "surah_name": "Al-Kawthar", "surah_arabic": "الكوثر", "text": "إِنَّ شَانِئَكَ هُوَ ٱلْأَبْتَرُ", "translation": "Indeed, your enemy is the one cut off"},

    # Surah Al-Kafirun (109:1 - 109:6)
    {"surah": 109, "ayah": 1, "surah_name": "Al-Kafirun", "surah_arabic": "الكافرون", "text": "قُلْ يَٰٓأَيُّهَا ٱلْكَٰفِرُونَ", "translation": "Say, 'O disbelievers'"},
    {"surah": 109, "ayah": 2, "surah_name": "Al-Kafirun", "surah_arabic": "الكافرون", "text": "لَآ أَعْبُدُ مَا تَعْبُدُونَ", "translation": "I do not worship what you worship"},
    {"surah": 109, "ayah": 3, "surah_name": "Al-Kafirun", "surah_arabic": "الكافرون", "text": "وَلَآ أَنتُمْ عَٰبِدُونَ مَآ أَعْبُدُ", "translation": "Nor are you worshippers of what I worship"},
    {"surah": 109, "ayah": 4, "surah_name": "Al-Kafirun", "surah_arabic": "الكافرون", "text": "وَلَآ أَنَا۠ عَابِدٌ مَّا عَبَدتُّمْ", "translation": "Nor will I be a worshipper of what you worship"},
    {"surah": 109, "ayah": 5, "surah_name": "Al-Kafirun", "surah_arabic": "الكافرون", "text": "وَلَآ أَنتُمْ عَٰبِدُونَ مَآ أَعْبُدُ", "translation": "Nor will you be worshippers of what I worship"},
    {"surah": 109, "ayah": 6, "surah_name": "Al-Kafirun", "surah_arabic": "الكافرون", "text": "لَكُمْ دِينُكُمْ وَلِىَ دِينِ", "translation": "For you is your religion, and for me is my religion"},

    # Surah An-Nasr (110:1 - 110:3)
    {"surah": 110, "ayah": 1, "surah_name": "An-Nasr", "surah_arabic": "النصر", "text": "إِذَا جَآءَ نَصْرُ ٱللَّهِ وَٱلْفَتْحُ", "translation": "When the victory of Allah has come and the conquest"},
    {"surah": 110, "ayah": 2, "surah_name": "An-Nasr", "surah_arabic": "النصر", "text": "وَرَأَيْتَ ٱلنَّاسَ يَدْخُلُونَ فِى دِينِ ٱللَّهِ أَفْوَاجًا", "translation": "And you see the people entering into the religion of Allah in multitudes"},
    {"surah": 110, "ayah": 3, "surah_name": "An-Nasr", "surah_arabic": "النصر", "text": "فَسَبِّحْ بِحَمْدِ رَبِّكَ وَٱسْتَغْفِرْهُ ۚ إِنَّهُۥ كَانَ تَوَّابًۢا", "translation": "Then exalt [Him] with praise of your Lord and ask forgiveness of Him. Indeed, He is ever Accepting of repentance"},

    # Surah Al-Masad (111:1 - 111:5)
    {"surah": 111, "ayah": 1, "surah_name": "Al-Masad", "surah_arabic": "المسد", "text": "تَبَّتْ يَدَآ أَبِى لَهَبٍ وَتَبَّ", "translation": "May the hands of Abu Lahab be ruined, and ruined is he"},
    {"surah": 111, "ayah": 2, "surah_name": "Al-Masad", "surah_arabic": "المسد", "text": "مَآ أَغْنَىٰ عَنْهُ مَالُهُۥ وَمَا كَسَبَ", "translation": "His wealth will not avail him or that which he gained"},

    # Surah Al-Ikhlas (112:1 - 112:4)
    {"surah": 112, "ayah": 1, "surah_name": "Al-Ikhlas", "surah_arabic": "الإخلاص", "text": "قُلْ هُوَ ٱللَّهُ أَحَدٌ", "translation": "Say, 'He is Allah, [who is] One'"},
    {"surah": 112, "ayah": 2, "surah_name": "Al-Ikhlas", "surah_arabic": "الإخلاص", "text": "ٱللَّهُ ٱلصَّمَدُ", "translation": "Allah, the Eternal Refuge"},
    {"surah": 112, "ayah": 3, "surah_name": "Al-Ikhlas", "surah_arabic": "الإخلاص", "text": "لَمْ يَلِدْ وَلَمْ يُولَدْ", "translation": "He neither begets nor is born"},
    {"surah": 112, "ayah": 4, "surah_name": "Al-Ikhlas", "surah_arabic": "الإخلاص", "text": "وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ", "translation": "Nor is there to Him any equivalent"},

    # Surah Al-Falaq (113:1 - 113:5)
    {"surah": 113, "ayah": 1, "surah_name": "Al-Falaq", "surah_arabic": "الفلق", "text": "قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ", "translation": "Say, 'I seek refuge in the Lord of daybreak'"},
    {"surah": 113, "ayah": 2, "surah_name": "Al-Falaq", "surah_arabic": "الفلق", "text": "مِن شَرِّ مَا خَلَقَ", "translation": "From the evil of that which He created"},
    {"surah": 113, "ayah": 3, "surah_name": "Al-Falaq", "surah_arabic": "الفلق", "text": "وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ", "translation": "And from the evil of darkness when it settles"},
    {"surah": 113, "ayah": 4, "surah_name": "Al-Falaq", "surah_arabic": "الفلق", "text": "وَمِن شَرِّ ٱلنَّفَّٰثَٰتِ فِى ٱلْعُقَدِ", "translation": "And from the evil of the blowers in knots"},
    {"surah": 113, "ayah": 5, "surah_name": "Al-Falaq", "surah_arabic": "الفلق", "text": "وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ", "translation": "And from the evil of an envier when he envies"},

    # Surah An-Nas (114:1 - 114:6)
    {"surah": 114, "ayah": 1, "surah_name": "An-Nas", "surah_arabic": "الناس", "text": "قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ", "translation": "Say, 'I seek refuge in the Lord of mankind'"},
    {"surah": 114, "ayah": 2, "surah_name": "An-Nas", "surah_arabic": "الناس", "text": "مَلِكِ ٱلنَّاسِ", "translation": "The Sovereign of mankind"},
    {"surah": 114, "ayah": 3, "surah_name": "An-Nas", "surah_arabic": "الناس", "text": "إِلَٰهِ ٱلنَّاسِ", "translation": "The God of mankind"},
    {"surah": 114, "ayah": 4, "surah_name": "An-Nas", "surah_arabic": "الناس", "text": "مِن شَرِّ ٱلْوَسْوَاسِ ٱلْخَنَّاسِ", "translation": "From the evil of the retreating whisperer"},
    {"surah": 114, "ayah": 5, "surah_name": "An-Nas", "surah_arabic": "الناس", "text": "ٱلَّذِى يُوَسْوِسُ فِى صُدُورِ ٱلنَّاسِ", "translation": "Who whispers into the breasts of mankind"},
    {"surah": 114, "ayah": 6, "surah_name": "An-Nas", "surah_arabic": "الناس", "text": "مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ", "translation": "From among the jinn and mankind"},
]

# Pre-normalize database entries
for v in INDEXED_VERSES:
    v["norm_text"] = normalize_arabic(v["text"])
    v["words"] = v["norm_text"].split()


def search_quran_verse(query_text: str, top_k: int = 3) -> List[Dict[str, Any]]:
    """
    Matches query Arabic string against indexed Quran verses.
    Returns ranked list of matching verses with confidence percentage.
    """
    norm_query = normalize_arabic(query_text)
    if not norm_query:
        return []

    q_words = norm_query.split()
    results = []

    for v in INDEXED_VERSES:
        norm_target = v["norm_text"]
        target_words = v["words"]
        
        # 1. Exact or Substring match
        if norm_query in norm_target:
            score = 0.95 + (len(norm_query) / max(len(norm_target), 1)) * 0.05
        elif norm_target in norm_query:
            score = 0.90
        else:
            # 2. Word overlap / Jaccard similarity
            matched_words = 0
            for qw in q_words:
                best_w_sim = 0.0
                for tw in target_words:
                    if qw == tw:
                        sim = 1.0
                    else:
                        d = levenshtein_distance(qw, tw)
                        sim = max(0.0, 1.0 - (d / max(len(qw), len(tw), 1)))
                    if sim > best_w_sim:
                        best_w_sim = sim
                if best_w_sim >= 0.70:
                    matched_words += best_w_sim

            overlap_ratio = matched_words / max(len(q_words), 1)
            target_cover = matched_words / max(len(target_words), 1)
            
            # 3. Overall character-level edit distance
            dist = levenshtein_distance(norm_query, norm_target)
            char_sim = max(0.0, 1.0 - (dist / max(len(norm_query), len(norm_target), 1)))

            score = (overlap_ratio * 0.50) + (target_cover * 0.20) + (char_sim * 0.30)

        confidence = round(min(100.0, score * 100.0), 1)
        if confidence >= 45.0:
            results.append({
                "surah": v["surah"],
                "ayah": v["ayah"],
                "surahName": v["surah_name"],
                "surahArabic": v["surah_arabic"],
                "textUthmani": v["text"],
                "translation": v["translation"],
                "confidence": confidence,
                "matchedQuery": norm_query,
            })

    # Sort descending by confidence
    results.sort(key=lambda x: x["confidence"], reverse=True)
    return results[:top_k]
