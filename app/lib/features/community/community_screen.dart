import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import 'models/community_models.dart';
import 'services/community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityService _service = CommunityService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        backgroundColor: ItqanColors.void_,
        title: const Text('Community & Halaqah', style: ItqanTypography.heading2),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ItqanColors.gold,
          labelColor: ItqanColors.gold,
          unselectedLabelColor: ItqanColors.mist,
          tabs: const [
            Tab(text: 'Leaderboard', icon: Icon(Icons.emoji_events_rounded, size: 20)),
            Tab(text: 'Halaqah Online', icon: Icon(Icons.groups_rounded, size: 20)),
            Tab(text: 'Challenges', icon: Icon(Icons.military_tech_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LeaderboardTab(service: _service),
          _HalaqahTab(
            service: _service,
            onToggleJoin: () => setState(() {}),
          ),
          _ChallengesTab(
            service: _service,
            onClaim: () => setState(() {}),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final CommunityService service;
  const _LeaderboardTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final list = service.getLeaderboard();

    return ListView.builder(
      padding: const EdgeInsets.all(ItqanSpacing.md),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final entry = list[i];
        final isTop3 = entry.rank <= 3;
        final rankColor = entry.rank == 1
            ? const Color(0xFFFFD700)
            : (entry.rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

        return Container(
          margin: const EdgeInsets.only(bottom: ItqanSpacing.sm),
          padding: const EdgeInsets.all(ItqanSpacing.md),
          decoration: BoxDecoration(
            color: entry.isCurrentUser ? ItqanColors.gold.withOpacity(0.12) : ItqanColors.onyx,
            borderRadius: BorderRadius.circular(ItqanRadius.lg),
            border: Border.all(
              color: entry.isCurrentUser
                  ? ItqanColors.gold
                  : (isTop3 ? rankColor.withOpacity(0.4) : ItqanColors.charcoal),
              width: entry.isCurrentUser ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isTop3 ? rankColor.withOpacity(0.2) : ItqanColors.charcoal,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    color: isTop3 ? rankColor : ItqanColors.mist,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: ItqanSpacing.md),
              Text(entry.avatar, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: ItqanSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.name,
                          style: TextStyle(
                            color: entry.isCurrentUser ? ItqanColors.gold : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('${entry.recitationMinutes} mins', style: ItqanTypography.caption),
                        const SizedBox(width: 8),
                        Text('• ${entry.streakDays}d streak', style: ItqanTypography.caption.copyWith(color: const Color(0xFFF97316))),
                        const SizedBox(width: 8),
                        Text('• ${entry.accuracyRate}%', style: ItqanTypography.caption.copyWith(color: ItqanColors.correct)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ItqanColors.charcoal,
                  borderRadius: BorderRadius.circular(ItqanRadius.sm),
                ),
                child: Text(
                  entry.badge,
                  style: const TextStyle(color: ItqanColors.gold, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HalaqahTab extends StatelessWidget {
  final CommunityService service;
  final VoidCallback onToggleJoin;

  const _HalaqahTab({
    required this.service,
    required this.onToggleJoin,
  });

  @override
  Widget build(BuildContext context) {
    final groups = service.getHalaqahGroups();

    return ListView.builder(
      padding: const EdgeInsets.all(ItqanSpacing.md),
      itemCount: groups.length,
      itemBuilder: (ctx, i) {
        final g = groups[i];

        return Container(
          margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
          padding: const EdgeInsets.all(ItqanSpacing.md),
          decoration: BoxDecoration(
            color: ItqanColors.onyx,
            borderRadius: BorderRadius.circular(ItqanRadius.lg),
            border: Border.all(
              color: g.isJoined ? ItqanColors.gold.withOpacity(0.5) : ItqanColors.charcoal,
              width: g.isJoined ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      g.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      service.toggleJoinHalaqah(g.id);
                      onToggleJoin();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: g.isJoined ? ItqanColors.charcoal : ItqanColors.gold,
                      foregroundColor: g.isJoined ? ItqanColors.mist : ItqanColors.void_,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ItqanRadius.full)),
                    ),
                    child: Text(
                      g.isJoined ? 'Joined ✓' : 'Join Halaqah',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Mentor: ${g.ustadzName} • ${g.memberCount} members', style: ItqanTypography.caption),
              const SizedBox(height: ItqanSpacing.sm),
              Text(g.description, style: ItqanTypography.caption.copyWith(color: ItqanColors.cloud)),
              const SizedBox(height: ItqanSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weekly Target: ${g.weeklyTarget}', style: const TextStyle(color: ItqanColors.gold, fontSize: 11)),
                  Text('${(g.groupProgressPercent * 100).round()}% complete', style: const TextStyle(color: ItqanColors.correct, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(ItqanRadius.full),
                child: LinearProgressIndicator(
                  value: g.groupProgressPercent,
                  minHeight: 6,
                  backgroundColor: ItqanColors.charcoal,
                  valueColor: const AlwaysStoppedAnimation(ItqanColors.gold),
                ),
              ),
              if (g.announcements.isNotEmpty) ...[
                const SizedBox(height: ItqanSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ItqanColors.charcoal,
                    borderRadius: BorderRadius.circular(ItqanRadius.sm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.campaign_rounded, size: 14, color: ItqanColors.gold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          g.announcements.first,
                          style: ItqanTypography.caption.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ChallengesTab extends StatelessWidget {
  final CommunityService service;
  final VoidCallback onClaim;

  const _ChallengesTab({
    required this.service,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final challenges = service.getDailyChallenges();

    return ListView.builder(
      padding: const EdgeInsets.all(ItqanSpacing.md),
      itemCount: challenges.length,
      itemBuilder: (ctx, i) {
        final ch = challenges[i];

        return Container(
          margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
          padding: const EdgeInsets.all(ItqanSpacing.md),
          decoration: BoxDecoration(
            color: ItqanColors.onyx,
            borderRadius: BorderRadius.circular(ItqanRadius.lg),
            border: Border.all(
              color: ch.isCompleted ? ItqanColors.correct.withOpacity(0.4) : ItqanColors.charcoal,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ch.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ItqanColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(ItqanRadius.sm),
                    ),
                    child: Text(
                      '+${ch.rewardXp} XP',
                      style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Reward: ${ch.rewardBadge}', style: ItqanTypography.caption.copyWith(fontSize: 11)),
                  const SizedBox(width: 8),
                  Text('• Expires in ${ch.expiresInHours}h', style: ItqanTypography.caption.copyWith(color: ItqanColors.warning, fontSize: 11)),
                ],
              ),
              const SizedBox(height: ItqanSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress: ${ch.progress} / ${ch.target} ${ch.unit}', style: ItqanTypography.caption),
                  Text('${(ch.progressPercent * 100).round()}%', style: const TextStyle(color: ItqanColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(ItqanRadius.full),
                child: LinearProgressIndicator(
                  value: ch.progressPercent,
                  minHeight: 6,
                  backgroundColor: ItqanColors.charcoal,
                  valueColor: AlwaysStoppedAnimation(ch.isCompleted ? ItqanColors.correct : ItqanColors.gold),
                ),
              ),
              const SizedBox(height: ItqanSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: ch.isCompleted
                      ? null
                      : () {
                          service.claimChallenge(ch.id);
                          onClaim();
                        },
                  icon: Icon(
                    ch.isCompleted ? Icons.check_circle_rounded : Icons.star_rounded,
                    size: 15,
                    color: ch.isCompleted ? ItqanColors.mist : ItqanColors.void_,
                  ),
                  label: Text(
                    ch.isCompleted ? 'Claimed' : 'Complete Challenge',
                    style: TextStyle(
                      color: ch.isCompleted ? ItqanColors.mist : ItqanColors.void_,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ch.isCompleted ? ItqanColors.charcoal : ItqanColors.gold,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ItqanRadius.full)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
