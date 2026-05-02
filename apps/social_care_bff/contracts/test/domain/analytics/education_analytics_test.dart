import 'package:shared/src/domain/analytics/education_analytics_service.dart';
import 'package:shared/src/domain/kernel/ids.dart';
import 'package:shared/src/domain/kernel/time_stamp.dart';
import 'package:test/test.dart';

void main() {
  group('EducationAnalyticsService - Vulnerabilidades', () {
    final now = TimeStamp.fromIso('2026-03-12T00:00:00.000Z').valueOrNull!;

    test('Deve detectar analfabetismo em adulto', () {
      final members = [
        EducationalMember(
          personId: PersonId.create(
            '550e8400-e29b-41d4-a716-446655440002',
          ).valueOrNull!,
          birthDate: TimeStamp.fromIso(
            '1990-01-01T00:00:00.000Z',
          ).valueOrNull!, // ~36 anos
          attendsSchool: false,
          canReadWrite: false, // Analfabeto
        ),
      ];

      final report = EducationAnalyticsService.calculateVulnerabilities(
        members: members,
        at: now,
      );

      expect(
        report.count(VulnerabilityType.illiteracy, EduAgeRange.range18to59),
        1,
      );
    });

    test('Deve detectar criança fora da escola', () {
      final members = [
        EducationalMember(
          personId: PersonId.create(
            '550e8400-e29b-41d4-a716-446655440003',
          ).valueOrNull!,
          birthDate: TimeStamp.fromIso(
            '2018-01-01T00:00:00.000Z',
          ).valueOrNull!, // ~8 anos
          attendsSchool: false,
          canReadWrite: true,
        ),
      ];

      final report = EducationAnalyticsService.calculateVulnerabilities(
        members: members,
        at: now,
      );

      expect(
        report.count(VulnerabilityType.notInSchool, EduAgeRange.range6to14),
        1,
      );
    });
  });
}
