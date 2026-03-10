/// Educational status assessment data.
final class EducationalStatus {
  const EducationalStatus({
    required this.memberProfiles,
    required this.programOccurrences,
  });

  final List<EducationalMemberProfile> memberProfiles;
  final List<ProgramOccurrence> programOccurrences;
}

/// Educational profile for a single family member.
final class EducationalMemberProfile {
  const EducationalMemberProfile({
    required this.memberId,
    required this.canReadWrite,
    required this.attendsSchool,
    required this.educationLevelId,
  });

  final String memberId;
  final bool canReadWrite;
  final bool attendsSchool;
  final String educationLevelId;
}

/// A program occurrence (e.g. Bolsa Família conditionality event).
final class ProgramOccurrence {
  const ProgramOccurrence({
    required this.memberId,
    required this.effectId,
    required this.isSuspensionRequested,
    this.date,
  });

  final String memberId;
  final DateTime? date;
  final String effectId;
  final bool isSuspensionRequested;
}
