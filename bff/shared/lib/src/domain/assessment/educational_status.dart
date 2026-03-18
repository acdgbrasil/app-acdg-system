import 'package:core/core.dart';
import '../kernel/ids.dart';
import '../kernel/time_stamp.dart';

final class MemberEducationalProfile with Equatable {
  const MemberEducationalProfile({
    required this.memberId,
    required this.canReadWrite,
    required this.attendsSchool,
    required this.educationLevelId,
  });

  final PersonId memberId;
  final bool canReadWrite;
  final bool attendsSchool;
  final LookupId educationLevelId;

  @override
  List<Object?> get props => [memberId, canReadWrite, attendsSchool, educationLevelId];
}

final class ProgramOccurrence with Equatable {
  const ProgramOccurrence({
    required this.memberId,
    required this.date,
    required this.effectId,
    required this.isSuspensionRequested,
  });

  final PersonId memberId;
  final TimeStamp date;
  final LookupId effectId;
  final bool isSuspensionRequested;

  @override
  List<Object?> get props => [memberId, date, effectId, isSuspensionRequested];
}

final class EducationalStatus with Equatable {
  const EducationalStatus({
    required this.familyId,
    required this.memberProfiles,
    required this.programOccurrences,
  });

  final PatientId familyId;
  final List<MemberEducationalProfile> memberProfiles;
  final List<ProgramOccurrence> programOccurrences;

  @override
  List<Object?> get props => [familyId, memberProfiles, programOccurrences];
}
