import 'package:core/core.dart';

/// Educational status of the household (ficha Educação).
class EducationalStatus with Equatable {
  const EducationalStatus({
    this.memberProfiles = const [],
    this.programOccurrences = const [],
  });

  final List<EducationalProfile> memberProfiles;
  final List<ProgramOccurrence> programOccurrences;

  EducationalStatus copyWith({
    List<EducationalProfile>? memberProfiles,
    List<ProgramOccurrence>? programOccurrences,
  }) {
    return EducationalStatus(
      memberProfiles: memberProfiles ?? this.memberProfiles,
      programOccurrences: programOccurrences ?? this.programOccurrences,
    );
  }

  @override
  List<Object?> get props => [memberProfiles, programOccurrences];
}

/// Educational profile for a single member.
class EducationalProfile with Equatable {
  const EducationalProfile({
    required this.memberId,
    required this.canReadWrite,
    required this.attendsSchool,
    required this.educationLevelId,
  });

  final String memberId;
  final bool canReadWrite;
  final bool attendsSchool;
  final String educationLevelId;

  EducationalProfile copyWith({
    String? memberId,
    bool? canReadWrite,
    bool? attendsSchool,
    String? educationLevelId,
  }) {
    return EducationalProfile(
      memberId: memberId ?? this.memberId,
      canReadWrite: canReadWrite ?? this.canReadWrite,
      attendsSchool: attendsSchool ?? this.attendsSchool,
      educationLevelId: educationLevelId ?? this.educationLevelId,
    );
  }

  @override
  List<Object?> get props => [
    memberId,
    canReadWrite,
    attendsSchool,
    educationLevelId,
  ];
}

/// Event registered against a member inside a social program.
class ProgramOccurrence with Equatable {
  const ProgramOccurrence({
    required this.memberId,
    required this.date,
    required this.effectId,
    required this.isSuspensionRequested,
  });

  final String memberId;
  final String date;
  final String effectId;
  final bool isSuspensionRequested;

  ProgramOccurrence copyWith({
    String? memberId,
    String? date,
    String? effectId,
    bool? isSuspensionRequested,
  }) {
    return ProgramOccurrence(
      memberId: memberId ?? this.memberId,
      date: date ?? this.date,
      effectId: effectId ?? this.effectId,
      isSuspensionRequested:
          isSuspensionRequested ?? this.isSuspensionRequested,
    );
  }

  @override
  List<Object?> get props => [memberId, date, effectId, isSuspensionRequested];
}
