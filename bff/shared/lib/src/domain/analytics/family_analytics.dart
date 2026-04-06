import 'package:core_contracts/core_contracts.dart';
import '../registry/family_member.dart';
import '../kernel/time_stamp.dart';

/// Supported age ranges for family profiling.
enum AgeRange {
  range0to6('0-6 anos'),
  range7to14('7-14 anos'),
  range15to17('15-17 anos'),
  range18to29('18-29 anos'),
  range30to59('30-59 anos'),
  range60to64('60-64 anos'),
  range65to69('65-69 anos'),
  range70Plus('70+ anos');

  const AgeRange(this.label);
  final String label;
}

/// Profile result containing counts for each age range.
final class AgeProfile with Equatable {
  const AgeProfile(this.distribution);

  final Map<AgeRange, int> distribution;

  int count(AgeRange range) => distribution[range] ?? 0;

  int get totalMembers => distribution.values.fold(0, (sum, val) => sum + val);

  @override
  List<Object?> get props => [distribution];
}

/// Service for calculating the age profile of a family.
abstract final class FamilyAnalytics {
  /// Classifies each member by age range based on [at] timestamp.
  static AgeProfile calculateAgeProfile({
    required List<FamilyMember> members,
    required TimeStamp at,
  }) {
    final distribution = <AgeRange, int>{};
    for (final range in AgeRange.values) {
      distribution[range] = 0;
    }

    for (final member in members) {
      final age = member.birthDate.yearsAt(referenceDate: at);
      final range = _getRangeForAge(age);
      distribution[range] = (distribution[range] ?? 0) + 1;
    }

    return AgeProfile(Map.unmodifiable(distribution));
  }

  static AgeRange _getRangeForAge(int age) {
    if (age <= 6) return AgeRange.range0to6;
    if (age <= 14) return AgeRange.range7to14;
    if (age <= 17) return AgeRange.range15to17;
    if (age <= 29) return AgeRange.range18to29;
    if (age <= 59) return AgeRange.range30to59;
    if (age <= 64) return AgeRange.range60to64;
    if (age <= 69) return AgeRange.range65to69;
    return AgeRange.range70Plus;
  }
}
