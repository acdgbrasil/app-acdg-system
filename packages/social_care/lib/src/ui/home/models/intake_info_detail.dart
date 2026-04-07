final class IntakeInfoDetail {
  final String ingressTypeId;
  final String? originName;
  final String? originContact;
  final String serviceReason;
  final List<LinkedProgramDetail> linkedSocialPrograms;

  const IntakeInfoDetail({
    required this.ingressTypeId,
    this.originName,
    this.originContact,
    required this.serviceReason,
    required this.linkedSocialPrograms,
  });

  factory IntakeInfoDetail.fromJson(Map<String, dynamic> json) {
    return IntakeInfoDetail(
      ingressTypeId: json['ingressTypeId'] as String,
      originName: json['originName'] as String?,
      originContact: json['originContact'] as String?,
      serviceReason: json['serviceReason'] as String,
      linkedSocialPrograms: (json['linkedSocialPrograms'] as List)
          .map((e) => LinkedProgramDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

final class LinkedProgramDetail {
  final String programId;
  final String? observation;

  const LinkedProgramDetail({required this.programId, this.observation});

  factory LinkedProgramDetail.fromJson(Map<String, dynamic> json) {
    return LinkedProgramDetail(
      programId: json['programId'] as String,
      observation: json['observation'] as String?,
    );
  }
}
