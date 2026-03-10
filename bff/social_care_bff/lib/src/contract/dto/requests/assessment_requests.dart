/// Request to update housing condition.
final class UpdateHousingConditionRequest {
  const UpdateHousingConditionRequest({
    required this.type,
    required this.wallMaterial,
    required this.numberOfRooms,
    required this.numberOfBedrooms,
    required this.numberOfBathrooms,
    required this.waterSupply,
    required this.hasPipedWater,
    required this.electricityAccess,
    required this.sewageDisposal,
    required this.wasteCollection,
    required this.accessibilityLevel,
    required this.isInGeographicRiskArea,
    required this.hasDifficultAccess,
    required this.isInSocialConflictArea,
    required this.hasDiagnosticObservations,
  });

  final String type;
  final String wallMaterial;
  final int numberOfRooms;
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final String waterSupply;
  final bool hasPipedWater;
  final String electricityAccess;
  final String sewageDisposal;
  final String wasteCollection;
  final String accessibilityLevel;
  final bool isInGeographicRiskArea;
  final bool hasDifficultAccess;
  final bool isInSocialConflictArea;
  final bool hasDiagnosticObservations;

  Map<String, dynamic> toJson() => {
    'type': type,
    'wallMaterial': wallMaterial,
    'numberOfRooms': numberOfRooms,
    'numberOfBedrooms': numberOfBedrooms,
    'numberOfBathrooms': numberOfBathrooms,
    'waterSupply': waterSupply,
    'hasPipedWater': hasPipedWater,
    'electricityAccess': electricityAccess,
    'sewageDisposal': sewageDisposal,
    'wasteCollection': wasteCollection,
    'accessibilityLevel': accessibilityLevel,
    'isInGeographicRiskArea': isInGeographicRiskArea,
    'hasDifficultAccess': hasDifficultAccess,
    'isInSocialConflictArea': isInSocialConflictArea,
    'hasDiagnosticObservations': hasDiagnosticObservations,
  };
}

/// Request to update socioeconomic situation.
final class UpdateSocioEconomicSituationRequest {
  const UpdateSocioEconomicSituationRequest({
    required this.totalFamilyIncome,
    required this.incomePerCapita,
    required this.receivesSocialBenefit,
    required this.socialBenefits,
    required this.mainSourceOfIncome,
    required this.hasUnemployed,
  });

  final double totalFamilyIncome;
  final double incomePerCapita;
  final bool receivesSocialBenefit;
  final List<SocialBenefitDto> socialBenefits;
  final String mainSourceOfIncome;
  final bool hasUnemployed;

  Map<String, dynamic> toJson() => {
    'totalFamilyIncome': totalFamilyIncome,
    'incomePerCapita': incomePerCapita,
    'receivesSocialBenefit': receivesSocialBenefit,
    'socialBenefits': socialBenefits.map((b) => b.toJson()).toList(),
    'mainSourceOfIncome': mainSourceOfIncome,
    'hasUnemployed': hasUnemployed,
  };
}

final class SocialBenefitDto {
  const SocialBenefitDto({
    required this.benefitName,
    required this.amount,
    required this.beneficiaryId,
    this.benefitTypeId,
  });

  final String benefitName;
  final double amount;
  final String beneficiaryId;
  final String? benefitTypeId;

  Map<String, dynamic> toJson() => {
    'benefitName': benefitName,
    'amount': amount,
    'beneficiaryId': beneficiaryId,
    if (benefitTypeId != null) 'benefitTypeId': benefitTypeId,
  };
}

/// Request to update work and income.
final class UpdateWorkAndIncomeRequest {
  const UpdateWorkAndIncomeRequest({
    required this.individualIncomes,
    required this.socialBenefits,
    required this.hasRetiredMembers,
  });

  final List<IndividualIncomeDto> individualIncomes;
  final List<SocialBenefitDto> socialBenefits;
  final bool hasRetiredMembers;

  Map<String, dynamic> toJson() => {
    'individualIncomes': individualIncomes.map((i) => i.toJson()).toList(),
    'socialBenefits': socialBenefits.map((b) => b.toJson()).toList(),
    'hasRetiredMembers': hasRetiredMembers,
  };
}

final class IndividualIncomeDto {
  const IndividualIncomeDto({
    required this.memberId,
    required this.occupationId,
    required this.hasWorkCard,
    required this.monthlyAmount,
  });

  final String memberId;
  final String occupationId;
  final bool hasWorkCard;
  final double monthlyAmount;

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'occupationId': occupationId,
    'hasWorkCard': hasWorkCard,
    'monthlyAmount': monthlyAmount,
  };
}

/// Request to update educational status.
final class UpdateEducationalStatusRequest {
  const UpdateEducationalStatusRequest({
    required this.memberProfiles,
    required this.programOccurrences,
  });

  final List<EducationalProfileDto> memberProfiles;
  final List<ProgramOccurrenceDto> programOccurrences;

  Map<String, dynamic> toJson() => {
    'memberProfiles': memberProfiles.map((p) => p.toJson()).toList(),
    'programOccurrences': programOccurrences.map((o) => o.toJson()).toList(),
  };
}

final class EducationalProfileDto {
  const EducationalProfileDto({
    required this.memberId,
    required this.canReadWrite,
    required this.attendsSchool,
    required this.educationLevelId,
  });

  final String memberId;
  final bool canReadWrite;
  final bool attendsSchool;
  final String educationLevelId;

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'canReadWrite': canReadWrite,
    'attendsSchool': attendsSchool,
    'educationLevelId': educationLevelId,
  };
}

final class ProgramOccurrenceDto {
  const ProgramOccurrenceDto({
    required this.memberId,
    required this.effectId,
    required this.isSuspensionRequested,
    this.date,
  });

  final String memberId;
  final DateTime? date;
  final String effectId;
  final bool isSuspensionRequested;

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'effectId': effectId,
    'isSuspensionRequested': isSuspensionRequested,
    if (date != null) 'date': date!.toIso8601String(),
  };
}

/// Request to update health status.
final class UpdateHealthStatusRequest {
  const UpdateHealthStatusRequest({
    required this.deficiencies,
    required this.gestatingMembers,
    required this.constantCareNeeds,
    required this.foodInsecurity,
  });

  final List<DeficiencyDto> deficiencies;
  final List<GestatingMemberDto> gestatingMembers;
  final List<String> constantCareNeeds;
  final bool foodInsecurity;

  Map<String, dynamic> toJson() => {
    'deficiencies': deficiencies.map((d) => d.toJson()).toList(),
    'gestatingMembers': gestatingMembers.map((g) => g.toJson()).toList(),
    'constantCareNeeds': constantCareNeeds,
    'foodInsecurity': foodInsecurity,
  };
}

final class DeficiencyDto {
  const DeficiencyDto({
    required this.memberId,
    required this.deficiencyTypeId,
    required this.needsConstantCare,
    this.responsibleCaregiverName,
  });

  final String memberId;
  final String deficiencyTypeId;
  final bool needsConstantCare;
  final String? responsibleCaregiverName;

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'deficiencyTypeId': deficiencyTypeId,
    'needsConstantCare': needsConstantCare,
    if (responsibleCaregiverName != null)
      'responsibleCaregiverName': responsibleCaregiverName,
  };
}

final class GestatingMemberDto {
  const GestatingMemberDto({
    required this.memberId,
    required this.monthsGestation,
    required this.startedPrenatalCare,
  });

  final String memberId;
  final int monthsGestation;
  final bool startedPrenatalCare;

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'monthsGestation': monthsGestation,
    'startedPrenatalCare': startedPrenatalCare,
  };
}

/// Request to update community support network.
final class UpdateCommunitySupportNetworkRequest {
  const UpdateCommunitySupportNetworkRequest({
    required this.hasRelativeSupport,
    required this.hasNeighborSupport,
    required this.familyConflicts,
    required this.patientParticipatesInGroups,
    required this.familyParticipatesInGroups,
    required this.patientHasAccessToLeisure,
    required this.facesDiscrimination,
  });

  final bool hasRelativeSupport;
  final bool hasNeighborSupport;
  final String familyConflicts;
  final bool patientParticipatesInGroups;
  final bool familyParticipatesInGroups;
  final bool patientHasAccessToLeisure;
  final bool facesDiscrimination;

  Map<String, dynamic> toJson() => {
    'hasRelativeSupport': hasRelativeSupport,
    'hasNeighborSupport': hasNeighborSupport,
    'familyConflicts': familyConflicts,
    'patientParticipatesInGroups': patientParticipatesInGroups,
    'familyParticipatesInGroups': familyParticipatesInGroups,
    'patientHasAccessToLeisure': patientHasAccessToLeisure,
    'facesDiscrimination': facesDiscrimination,
  };
}

/// Request to update social health summary.
final class UpdateSocialHealthSummaryRequest {
  const UpdateSocialHealthSummaryRequest({
    required this.requiresConstantCare,
    required this.hasMobilityImpairment,
    required this.functionalDependencies,
    required this.hasRelevantDrugTherapy,
  });

  final bool requiresConstantCare;
  final bool hasMobilityImpairment;
  final List<String> functionalDependencies;
  final bool hasRelevantDrugTherapy;

  Map<String, dynamic> toJson() => {
    'requiresConstantCare': requiresConstantCare,
    'hasMobilityImpairment': hasMobilityImpairment,
    'functionalDependencies': functionalDependencies,
    'hasRelevantDrugTherapy': hasRelevantDrugTherapy,
  };
}
