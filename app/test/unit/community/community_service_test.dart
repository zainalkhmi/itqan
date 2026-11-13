import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/community/services/community_service.dart';

void main() {
  group('CommunityService Tests', () {
    late CommunityService service;

    setUp(() {
      service = CommunityService();
    });

    test('getLeaderboard returns ranked list with current user entry', () {
      final leaderboard = service.getLeaderboard();
      expect(leaderboard, isNotEmpty);
      expect(leaderboard.first.rank, equals(1));

      final currentUser = leaderboard.firstWhere((e) => e.isCurrentUser);
      expect(currentUser.name, contains('You'));
      expect(currentUser.streakDays, greaterThan(0));
    });

    test('toggleJoinHalaqah joins and leaves circle', () {
      final groups = service.getHalaqahGroups();
      final target = groups.firstWhere((g) => !g.isJoined);
      final initialCount = target.memberCount;

      service.toggleJoinHalaqah(target.id);
      final updated = service.getHalaqahGroups().firstWhere((g) => g.id == target.id);
      expect(updated.isJoined, isTrue);
      expect(updated.memberCount, equals(initialCount + 1));
    });

    test('claimChallenge marks challenge completed', () {
      final challenges = service.getDailyChallenges();
      final pending = challenges.firstWhere((c) => !c.isCompleted);

      service.claimChallenge(pending.id);
      final updated = service.getDailyChallenges().firstWhere((c) => c.id == pending.id);
      expect(updated.isCompleted, isTrue);
    });
  });
}
