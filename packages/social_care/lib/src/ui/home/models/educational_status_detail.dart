final class EducationalStatusDetail {
  final List<MemberProfileDetail> memberProfiles;
  final List<ProgramOccurrenceDetail> programOccurrences;

  const EducationalStatusDetail({
    required this.memberProfiles,
    required this.programOccurrences,
  });

  factory EducationalStatusDetail.fromJson(Map<String, dynamic> json) {
    return EducationalStatusDetail(
      memberProfiles: (json['memberProfiles'] as List)
          .map((e) => MemberProfileDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      programOccurrences: (json['programOccurrences'] as List)
          .map(
            (e) => ProgramOccurrenceDetail.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

final class MemberProfileDetail {
  final String memberId;
  final bool canReadWrite;
  final bool attendsSchool;
  final String educationLevelId;

  const MemberProfileDetail({
    required this.memberId,
    required this.canReadWrite,
    required this.attendsSchool,
    required this.educationLevelId,
  });

  factory MemberProfileDetail.fromJson(Map<String, dynamic> json) {
    return MemberProfileDetail(
      memberId: json['memberId'] as String,
      canReadWrite: json['canReadWrite'] as bool,
      attendsSchool: json['attendsSchool'] as bool,
      educationLevelId: json['educationLevelId'] as String,
    );
  }
}

final class ProgramOccurrenceDetail {
  final String memberId;
  final String date;
  final String effectId;
  final bool isSuspensionRequested;

  const ProgramOccurrenceDetail({
    required this.memberId,
    required this.date,
    required this.effectId,
    required this.isSuspensionRequested,
  });

  factory ProgramOccurrenceDetail.fromJson(Map<String, dynamic> json) {
    return ProgramOccurrenceDetail(
      memberId: json['memberId'] as String,
      date: json['date'] as String,
      effectId: json['effectId'] as String,
      isSuspensionRequested: json['isSuspensionRequested'] as bool,
    );
  }
}
