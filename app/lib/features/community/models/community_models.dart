class LeaderboardEntry {
  final int rank;
  final String name;
  final String avatar;
  final int streakDays;
  final int recitationMinutes;
  final double accuracyRate;
  final int ayahsMemorized;
  final String badge;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.avatar,
    required this.streakDays,
    required this.recitationMinutes,
    required this.accuracyRate,
    required this.ayahsMemorized,
    required this.badge,
    this.isCurrentUser = false,
  });

  Map<String, dynamic> toMap() => {
    'rank': rank,
    'name': name,
    'avatar': avatar,
    'streakDays': streakDays,
    'recitationMinutes': recitationMinutes,
    'accuracyRate': accuracyRate,
    'ayahsMemorized': ayahsMemorized,
    'badge': badge,
    'isCurrentUser': isCurrentUser,
  };

  factory LeaderboardEntry.fromMap(Map map) => LeaderboardEntry(
    rank: (map['rank'] as num?)?.toInt() ?? 1,
    name: map['name']?.toString() ?? '',
    avatar: map['avatar']?.toString() ?? '👤',
    streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
    recitationMinutes: (map['recitationMinutes'] as num?)?.toInt() ?? 0,
    accuracyRate: (map['accuracyRate'] as num?)?.toDouble() ?? 0.0,
    ayahsMemorized: (map['ayahsMemorized'] as num?)?.toInt() ?? 0,
    badge: map['badge']?.toString() ?? 'Qari',
    isCurrentUser: map['isCurrentUser'] as bool? ?? false,
  );
}

class HalaqahGroup {
  final String id;
  final String name;
  final String ustadzName;
  final int memberCount;
  final String targetJuz;
  final String weeklyTarget;
  final double groupProgressPercent;
  final String description;
  final List<String> announcements;
  final bool isJoined;

  const HalaqahGroup({
    required this.id,
    required this.name,
    required this.ustadzName,
    required this.memberCount,
    required this.targetJuz,
    required this.weeklyTarget,
    required this.groupProgressPercent,
    required this.description,
    this.announcements = const [],
    this.isJoined = false,
  });

  HalaqahGroup copyWith({
    String? id,
    String? name,
    String? ustadzName,
    int? memberCount,
    String? targetJuz,
    String? weeklyTarget,
    double? groupProgressPercent,
    String? description,
    List<String>? announcements,
    bool? isJoined,
  }) {
    return HalaqahGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      ustadzName: ustadzName ?? this.ustadzName,
      memberCount: memberCount ?? this.memberCount,
      targetJuz: targetJuz ?? this.targetJuz,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      groupProgressPercent: groupProgressPercent ?? this.groupProgressPercent,
      description: description ?? this.description,
      announcements: announcements ?? this.announcements,
      isJoined: isJoined ?? this.isJoined,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'ustadzName': ustadzName,
    'memberCount': memberCount,
    'targetJuz': targetJuz,
    'weeklyTarget': weeklyTarget,
    'groupProgressPercent': groupProgressPercent,
    'description': description,
    'announcements': announcements,
    'isJoined': isJoined,
  };

  factory HalaqahGroup.fromMap(Map map) => HalaqahGroup(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    ustadzName: map['ustadzName']?.toString() ?? '',
    memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
    targetJuz: map['targetJuz']?.toString() ?? '',
    weeklyTarget: map['weeklyTarget']?.toString() ?? '',
    groupProgressPercent: (map['groupProgressPercent'] as num?)?.toDouble() ?? 0.0,
    description: map['description']?.toString() ?? '',
    announcements: (map['announcements'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    isJoined: map['isJoined'] as bool? ?? false,
  );
}

class DailyChallenge {
  final String id;
  final String title;
  final int rewardXp;
  final String rewardBadge;
  final int progress;
  final int target;
  final String unit;
  final bool isCompleted;
  final int expiresInHours;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.rewardXp,
    required this.rewardBadge,
    required this.progress,
    required this.target,
    required this.unit,
    this.isCompleted = false,
    this.expiresInHours = 12,
  });

  DailyChallenge copyWith({
    String? id,
    String? title,
    int? rewardXp,
    String? rewardBadge,
    int? progress,
    int? target,
    String? unit,
    bool? isCompleted,
    int? expiresInHours,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      rewardXp: rewardXp ?? this.rewardXp,
      rewardBadge: rewardBadge ?? this.rewardBadge,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
      expiresInHours: expiresInHours ?? this.expiresInHours,
    );
  }

  double get progressPercent => (progress / target).clamp(0.0, 1.0);
}
