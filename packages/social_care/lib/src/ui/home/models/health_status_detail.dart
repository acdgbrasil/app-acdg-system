final class HealthStatusDetail {
  final bool foodInsecurity;
  final List<DeficiencyDetail> deficiencies;
  final List<GestatingMemberDetail> gestatingMembers;
  final List<String> constantCareNeeds;

  const HealthStatusDetail({
    required this.foodInsecurity,
    required this.deficiencies,
    required this.gestatingMembers,
    required this.constantCareNeeds,
  });

  factory HealthStatusDetail.fromJson(Map<String, dynamic> json) {
    return HealthStatusDetail(
      foodInsecurity: json['foodInsecurity'] as bool,
      deficiencies: (json['deficiencies'] as List)
          .map((e) => DeficiencyDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      gestatingMembers: (json['gestatingMembers'] as List)
          .map(
            (e) => GestatingMemberDetail.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      constantCareNeeds: (json['constantCareNeeds'] as List)
          .map((e) => e as String)
          .toList(),
    );
  }
}

final class DeficiencyDetail {
  final String memberId;
  final String deficiencyTypeId;
  final bool needsConstantCare;
  final String? responsibleCaregiverName;

  const DeficiencyDetail({
    required this.memberId,
    required this.deficiencyTypeId,
    required this.needsConstantCare,
    this.responsibleCaregiverName,
  });

  factory DeficiencyDetail.fromJson(Map<String, dynamic> json) {
    return DeficiencyDetail(
      memberId: json['memberId'] as String,
      deficiencyTypeId: json['deficiencyTypeId'] as String,
      needsConstantCare: json['needsConstantCare'] as bool,
      responsibleCaregiverName:
          json['responsibleCaregiverName'] as String?,
    );
  }
}

final class GestatingMemberDetail {
  final String memberId;
  final int monthsGestation;
  final bool startedPrenatalCare;

  const GestatingMemberDetail({
    required this.memberId,
    required this.monthsGestation,
    required this.startedPrenatalCare,
  });

  factory GestatingMemberDetail.fromJson(Map<String, dynamic> json) {
    return GestatingMemberDetail(
      memberId: json['memberId'] as String,
      monthsGestation: json['monthsGestation'] as int,
      startedPrenatalCare: json['startedPrenatalCare'] as bool,
    );
  }
}
