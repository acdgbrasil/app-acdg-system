import 'package:shared/src/domain/analytics/family_analytics.dart';
import 'package:shared/src/domain/kernel/ids.dart';
import 'package:shared/src/domain/kernel/time_stamp.dart';
import 'package:shared/src/domain/registry/family_member.dart';
import 'package:test/test.dart';

void main() {
  group('FamilyAnalytics - Perfil Etário', () {
    final relId = LookupId.create(
      '550e8400-e29b-41d4-a716-446655440001',
    ).valueOrNull!;
    final now = TimeStamp.fromIso('2026-03-12T00:00:00.000Z').valueOrNull!;

    test('Deve classificar membros corretamente por faixa etária', () {
      final members = [
        // 5 anos (range0to6)
        FamilyMember.create(
          personId: PersonId.create(
            '550e8400-e29b-41d4-a716-446655440002',
          ).valueOrNull!,
          relationshipId: relId,
          residesWithPatient: true,
          birthDate: TimeStamp.fromIso('2021-03-12T00:00:00.000Z').valueOrNull!,
        ).valueOrNull!,
        // 10 anos (range7to14)
        FamilyMember.create(
          personId: PersonId.create(
            '550e8400-e29b-41d4-a716-446655440003',
          ).valueOrNull!,
          relationshipId: relId,
          residesWithPatient: true,
          birthDate: TimeStamp.fromIso('2016-03-12T00:00:00.000Z').valueOrNull!,
        ).valueOrNull!,
        // 75 anos (range70Plus)
        FamilyMember.create(
          personId: PersonId.create(
            '550e8400-e29b-41d4-a716-446655440004',
          ).valueOrNull!,
          relationshipId: relId,
          residesWithPatient: true,
          birthDate: TimeStamp.fromIso('1951-03-12T00:00:00.000Z').valueOrNull!,
        ).valueOrNull!,
      ];

      final profile = FamilyAnalytics.calculateAgeProfile(
        members: members,
        at: now,
      );

      expect(profile.count(AgeRange.range0to6), 1);
      expect(profile.count(AgeRange.range7to14), 1);
      expect(profile.count(AgeRange.range70Plus), 1);
      expect(profile.totalMembers, 3);
    });
  });
}
