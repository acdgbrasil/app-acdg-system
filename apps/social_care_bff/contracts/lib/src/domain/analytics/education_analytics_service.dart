import 'package:core_contracts/core_contracts.dart';
import '../kernel/ids.dart';
import '../kernel/time_stamp.dart';

/// Types of educational vulnerabilities.
enum VulnerabilityType {
  notInSchool('Fora da escola'),
  illiteracy('Analfabetismo');

  const VulnerabilityType(this.label);
  final String label;
}

/// Age ranges for educational monitoring.
enum EduAgeRange {
  range0to5('0-5 anos'),
  range6to14('6-14 anos'),
  range15to17('15-17 anos'),
  range10to17('10-17 anos'),
  range18to59('18-59 anos'),
  range60Plus('60+ anos');

  const EduAgeRange(this.label);
  final String label;
}

/// A simplified member model for education analytics.
final class EducationalMember with Equatable {
  const EducationalMember({
    required this.personId,
    required this.birthDate,
    required this.attendsSchool,
    required this.canReadWrite,
  });

  final PersonId personId;
  final TimeStamp birthDate;
  final bool attendsSchool;
  final bool canReadWrite;

  @override
  List<Object?> get props => [personId, birthDate, attendsSchool, canReadWrite];
}

/// Report containing vulnerability counts by type and age range.
final class VulnerabilityReport with Equatable {
  const VulnerabilityReport(this.counts);

  /// Key format: "vulnerability_ageRange"
  final Map<String, int> counts;

  int count(VulnerabilityType type, EduAgeRange range) {
    return counts['${type.name}_${range.name}'] ?? 0;
  }

  @override
  List<Object?> get props => [counts];
}

/// Service for calculating educational vulnerabilities.
abstract final class EducationAnalyticsService {
  /// Identifies vulnerabilities in a family based on age and school status.
  static VulnerabilityReport calculateVulnerabilities({
    required List<EducationalMember> members,
    required TimeStamp at,
  }) {
    final counts = <String, int>{};

    // Initialize counts
    for (final type in VulnerabilityType.values) {
      for (final range in EduAgeRange.values) {
        counts['${type.name}_${range.name}'] = 0;
      }
    }

    for (final member in members) {
      final age = member.birthDate.yearsAt(referenceDate: at);

      // Not in school checks
      if (!member.attendsSchool) {
        if (age <= 5) {
          _inc(counts, VulnerabilityType.notInSchool, EduAgeRange.range0to5);
        }
        if (age >= 6 && age <= 14) {
          _inc(counts, VulnerabilityType.notInSchool, EduAgeRange.range6to14);
        }
        if (age >= 15 && age <= 17) {
          _inc(counts, VulnerabilityType.notInSchool, EduAgeRange.range15to17);
        }
      }

      // Illiteracy checks
      if (!member.canReadWrite) {
        if (age >= 10 && age <= 17) {
          _inc(counts, VulnerabilityType.illiteracy, EduAgeRange.range10to17);
        }
        if (age >= 18 && age <= 59) {
          _inc(counts, VulnerabilityType.illiteracy, EduAgeRange.range18to59);
        }
        if (age >= 60) {
          _inc(counts, VulnerabilityType.illiteracy, EduAgeRange.range60Plus);
        }
      }
    }

    return VulnerabilityReport(Map.unmodifiable(counts));
  }

  static void _inc(
    Map<String, int> counts,
    VulnerabilityType type,
    EduAgeRange range,
  ) {
    final key = '${type.name}_${range.name}';
    counts[key] = (counts[key] ?? 0) + 1;
  }
}
