import 'package:core/core.dart';

/// Health status assessment (ficha Saúde).
class HealthStatus with Equatable {
  const HealthStatus({
    required this.foodInsecurity,
    this.deficiencies = const [],
    this.gestatingMembers = const [],
    this.constantCareNeeds = const [],
  });

  final bool foodInsecurity;
  final List<MemberDeficiency> deficiencies;
  final List<PregnantMember> gestatingMembers;
  final List<String> constantCareNeeds;

  HealthStatus copyWith({
    bool? foodInsecurity,
    List<MemberDeficiency>? deficiencies,
    List<PregnantMember>? gestatingMembers,
    List<String>? constantCareNeeds,
  }) {
    return HealthStatus(
      foodInsecurity: foodInsecurity ?? this.foodInsecurity,
      deficiencies: deficiencies ?? this.deficiencies,
      gestatingMembers: gestatingMembers ?? this.gestatingMembers,
      constantCareNeeds: constantCareNeeds ?? this.constantCareNeeds,
    );
  }

  @override
  List<Object?> get props => [
    foodInsecurity,
    deficiencies,
    gestatingMembers,
    constantCareNeeds,
  ];
}

/// Deficiency registered against a single member.
class MemberDeficiency with Equatable {
  const MemberDeficiency({
    required this.memberId,
    required this.deficiencyTypeId,
    required this.needsConstantCare,
    this.responsibleCaregiverName,
  });

  final String memberId;
  final String deficiencyTypeId;
  final bool needsConstantCare;
  final String? responsibleCaregiverName;

  MemberDeficiency copyWith({
    String? memberId,
    String? deficiencyTypeId,
    bool? needsConstantCare,
    String? responsibleCaregiverName,
  }) {
    return MemberDeficiency(
      memberId: memberId ?? this.memberId,
      deficiencyTypeId: deficiencyTypeId ?? this.deficiencyTypeId,
      needsConstantCare: needsConstantCare ?? this.needsConstantCare,
      responsibleCaregiverName:
          responsibleCaregiverName ?? this.responsibleCaregiverName,
    );
  }

  @override
  List<Object?> get props => [
    memberId,
    deficiencyTypeId,
    needsConstantCare,
    responsibleCaregiverName,
  ];
}

/// Pregnancy information for a family member.
class PregnantMember with Equatable {
  const PregnantMember({
    required this.memberId,
    required this.monthsGestation,
    required this.startedPrenatalCare,
  });

  final String memberId;
  final int monthsGestation;
  final bool startedPrenatalCare;

  PregnantMember copyWith({
    String? memberId,
    int? monthsGestation,
    bool? startedPrenatalCare,
  }) {
    return PregnantMember(
      memberId: memberId ?? this.memberId,
      monthsGestation: monthsGestation ?? this.monthsGestation,
      startedPrenatalCare: startedPrenatalCare ?? this.startedPrenatalCare,
    );
  }

  @override
  List<Object?> get props => [memberId, monthsGestation, startedPrenatalCare];
}
