/// Health status assessment data.
final class HealthStatus {
  const HealthStatus({
    required this.foodInsecurity,
    required this.deficiencies,
    required this.gestatingMembers,
    required this.constantCareNeeds,
  });

  final bool foodInsecurity;
  final List<Deficiency> deficiencies;
  final List<GestatingMember> gestatingMembers;
  final List<String> constantCareNeeds;
}

/// A deficiency reported for a family member.
final class Deficiency {
  const Deficiency({
    required this.memberId,
    required this.deficiencyTypeId,
    required this.needsConstantCare,
    this.responsibleCaregiverName,
  });

  final String memberId;
  final String deficiencyTypeId;
  final bool needsConstantCare;
  final String? responsibleCaregiverName;
}

/// A gestating family member.
final class GestatingMember {
  const GestatingMember({
    required this.memberId,
    required this.monthsGestation,
    required this.startedPrenatalCare,
  });

  final String memberId;
  final int monthsGestation;
  final bool startedPrenatalCare;
}
