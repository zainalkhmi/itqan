import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_models.dart';

final communityServiceProvider = Provider<CommunityService>((ref) {
  return CommunityService();
});

class CommunityService {
  final List<LeaderboardEntry> _leaderboard = [
    const LeaderboardEntry(
      rank: 1,
      name: 'Tariq Al-Mansoor',
      avatar: '👑',
      streakDays: 48,
      recitationMinutes: 840,
      accuracyRate: 98.4,
      ayahsMemorized: 604,
      badge: 'Khatim 30 Juz',
    ),
    const LeaderboardEntry(
      rank: 2,
      name: 'Maryam Nurul Huda',
      avatar: '⭐',
      streakDays: 35,
      recitationMinutes: 720,
      accuracyRate: 96.8,
      ayahsMemorized: 450,
      badge: 'Hafizhah Mutqin',
    ),
    const LeaderboardEntry(
      rank: 3,
      name: 'Ahmad Santri (You)',
      avatar: '🌟',
      streakDays: 14,
      recitationMinutes: 380,
      accuracyRate: 92.5,
      ayahsMemorized: 120,
      badge: 'Mujtahid',
      isCurrentUser: true,
    ),
    const LeaderboardEntry(
      rank: 4,
      name: 'Ziyad bin Thabit',
      avatar: '📖',
      streakDays: 21,
      recitationMinutes: 340,
      accuracyRate: 91.0,
      ayahsMemorized: 110,
      badge: 'Murattal',
    ),
    const LeaderboardEntry(
      rank: 5,
      name: 'Aisyah Al-Fasi',
      avatar: '🌸',
      streakDays: 19,
      recitationMinutes: 310,
      accuracyRate: 89.5,
      ayahsMemorized: 95,
      badge: 'Qari\'ah',
    ),
  ];

  final List<HalaqahGroup> _groups = [
    const HalaqahGroup(
      id: 'hal_1',
      name: 'Halaqah Tahfizh Juz \'Amma (Juz 30)',
      ustadzName: 'Ustadz Abdullah Al-Hafizh',
      memberCount: 38,
      targetJuz: 'Juz 30 (An-Naba\' to An-Nas)',
      weeklyTarget: '3 Surahs / week',
      groupProgressPercent: 0.78,
      description: 'Program akselerasi hafalan Juz 30 berstandar tajwid mutqin dengan evaluasi mingguan.',
      announcements: [
        'Setoran pekanan Surah Al-Muthaffifin dibuka hingga Ahad malam.',
        'Kajian live makharijul huruf hari Sabtu pukul 06.00 WIB.',
      ],
      isJoined: true,
    ),
    const HalaqahGroup(
      id: 'hal_2',
      name: 'Kajian Tajwid Matn Al-Jazariyyah',
      ustadzName: 'Shaykh Luqman Hakim',
      memberCount: 54,
      targetJuz: 'Muqaddimah & Bab Makhraj',
      weeklyTarget: '10 Bait / week',
      groupProgressPercent: 0.62,
      description: 'Bedah bait منظومة المقدمة الجزائية dengan talaqqi sanad keilmuan.',
      announcements: [
        'Ujian hafalan bait 1-20 dimulai pekan depan.',
      ],
      isJoined: false,
    ),
    const HalaqahGroup(
      id: 'hal_3',
      name: 'Subuh Muraja\'ah Club',
      ustadzName: 'Ustadzah Fatimah',
      memberCount: 112,
      targetJuz: 'Juz 1–5 Continuous Review',
      weeklyTarget: '1/2 Juz / day',
      groupProgressPercent: 0.91,
      description: 'Lingkaran muraja\'ah istiqamah ba\'da Subuh bersama santri dari seluruh penjuru nusantara.',
      announcements: [
        'Alhamdulillah 12 anggota baru saja menyelesaikan khataman putaran pertama!',
      ],
      isJoined: false,
    ),
  ];

  final List<DailyChallenge> _challenges = [
    const DailyChallenge(
      id: 'ch_1',
      title: 'Recite Surah Al-Kahf (First 10 Ayahs)',
      rewardXp: 150,
      rewardBadge: '🛡️ Kahf Light',
      progress: 10,
      target: 10,
      unit: 'ayahs',
      isCompleted: true,
      expiresInHours: 8,
    ),
    const DailyChallenge(
      id: 'ch_2',
      title: 'Complete 15 Minutes Daily Muraja\'ah',
      rewardXp: 100,
      rewardBadge: '🔥 Consistency Flame',
      progress: 9,
      target: 15,
      unit: 'mins',
      isCompleted: false,
      expiresInHours: 14,
    ),
    const DailyChallenge(
      id: 'ch_3',
      title: 'Score ≥85% on Qalqalah & Madd Drill',
      rewardXp: 120,
      rewardBadge: '🎯 Tajweed Precision',
      progress: 1,
      target: 1,
      unit: 'drill',
      isCompleted: false,
      expiresInHours: 18,
    ),
  ];

  List<LeaderboardEntry> getLeaderboard() => _leaderboard;

  List<HalaqahGroup> getHalaqahGroups() => _groups;

  void toggleJoinHalaqah(String id) {
    final idx = _groups.indexWhere((g) => g.id == id);
    if (idx != -1) {
      final g = _groups[idx];
      _groups[idx] = g.copyWith(
        isJoined: !g.isJoined,
        memberCount: g.isJoined ? g.memberCount - 1 : g.memberCount + 1,
      );
    }
  }

  List<DailyChallenge> getDailyChallenges() => _challenges;

  void claimChallenge(String id) {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _challenges[idx] = _challenges[idx].copyWith(isCompleted: true);
    }
  }
}
