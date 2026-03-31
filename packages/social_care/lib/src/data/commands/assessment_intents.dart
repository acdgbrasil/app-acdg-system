import 'package:core/core.dart';
import 'package:shared/shared.dart';

/// Intent to update housing condition with raw data.
final class UpdateHousingConditionIntent with Equatable {
  const UpdateHousingConditionIntent({
    required this.patientId,
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

  final PatientId patientId;
  final ConditionType type;
  final WallMaterial wallMaterial;
  final int numberOfRooms;
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final WaterSupply waterSupply;
  final bool hasPipedWater;
  final ElectricityAccess electricityAccess;
  final SewageDisposal sewageDisposal;
  final WasteCollection wasteCollection;
  final AccessibilityLevel accessibilityLevel;
  final bool isInGeographicRiskArea;
  final bool hasDifficultAccess;
  final bool isInSocialConflictArea;
  final bool hasDiagnosticObservations;

  @override
  List<Object?> get props => [
    patientId,
    type,
    wallMaterial,
    numberOfRooms,
    numberOfBedrooms,
    numberOfBathrooms,
    waterSupply,
    hasPipedWater,
    electricityAccess,
    sewageDisposal,
    wasteCollection,
    accessibilityLevel,
    isInGeographicRiskArea,
    hasDifficultAccess,
    isInSocialConflictArea,
    hasDiagnosticObservations,
  ];
}

/// Intent to update socioeconomic situation.
final class UpdateSocioEconomicIntent with Equatable {
  const UpdateSocioEconomicIntent({
    required this.patientId,
    required this.totalFamilyIncome,
    required this.incomePerCapita,
    required this.receivesSocialBenefit,
    required this.socialBenefits,
    required this.mainSourceOfIncome,
    required this.hasUnemployed,
  });

  final PatientId patientId;
  final double totalFamilyIncome;
  final double incomePerCapita;
  final bool receivesSocialBenefit;
  final List<SocialBenefit> socialBenefits;
  final String mainSourceOfIncome;
  final bool hasUnemployed;

  @override
  List<Object?> get props => [
    patientId,
    totalFamilyIncome,
    incomePerCapita,
    receivesSocialBenefit,
    socialBenefits,
    mainSourceOfIncome,
    hasUnemployed,
  ];
}

/// Intent to update work and income.
final class UpdateWorkAndIncomeIntent with Equatable {
  const UpdateWorkAndIncomeIntent({
    required this.patientId,
    required this.individualIncomes,
    required this.socialBenefits,
    required this.hasRetiredMembers,
  });

  final PatientId patientId;
  final List<WorkIncomeVO> individualIncomes;
  final List<SocialBenefit> socialBenefits;
  final bool hasRetiredMembers;

  @override
  List<Object?> get props => [
    patientId,
    individualIncomes,
    socialBenefits,
    hasRetiredMembers,
  ];
}

/// Intent to update educational status.
final class UpdateEducationalStatusIntent with Equatable {
  const UpdateEducationalStatusIntent({
    required this.patientId,
    required this.memberProfiles,
    required this.programOccurrences,
  });

  final PatientId patientId;
  final List<MemberEducationalProfile> memberProfiles;
  final List<ProgramOccurrence> programOccurrences;

  @override
  List<Object?> get props => [patientId, memberProfiles, programOccurrences];
}

/// Intent to update health status.
final class UpdateHealthStatusIntent with Equatable {
  const UpdateHealthStatusIntent({
    required this.patientId,
    required this.deficiencies,
    required this.gestatingMembers,
    required this.constantCareNeeds,
    required this.foodInsecurity,
  });

  final PatientId patientId;
  final List<MemberDeficiency> deficiencies;
  final List<PregnantMember> gestatingMembers;
  final List<PersonId> constantCareNeeds;
  final bool foodInsecurity;

  @override
  List<Object?> get props => [
    patientId,
    deficiencies,
    gestatingMembers,
    constantCareNeeds,
    foodInsecurity,
  ];
}

/// Intent to update community support network.
final class UpdateCommunitySupportIntent with Equatable {
  const UpdateCommunitySupportIntent({
    required this.patientId,
    required this.hasRelativeSupport,
    required this.hasNeighborSupport,
    required this.familyConflicts,
    required this.patientParticipatesInGroups,
    required this.familyParticipatesInGroups,
    required this.patientHasAccessToLeisure,
    required this.facesDiscrimination,
  });

  final PatientId patientId;
  final bool hasRelativeSupport;
  final bool hasNeighborSupport;
  final String familyConflicts;
  final bool patientParticipatesInGroups;
  final bool familyParticipatesInGroups;
  final bool patientHasAccessToLeisure;
  final bool facesDiscrimination;

  @override
  List<Object?> get props => [
    patientId,
    hasRelativeSupport,
    hasNeighborSupport,
    familyConflicts,
    patientParticipatesInGroups,
    familyParticipatesInGroups,
    patientHasAccessToLeisure,
    facesDiscrimination,
  ];
}

/// Intent to update social health summary.
final class UpdateSocialHealthSummaryIntent with Equatable {
  const UpdateSocialHealthSummaryIntent({
    required this.patientId,
    required this.requiresConstantCare,
    required this.hasMobilityImpairment,
    required this.functionalDependencies,
    required this.hasRelevantDrugTherapy,
  });

  final PatientId patientId;
  final bool requiresConstantCare;
  final bool hasMobilityImpairment;
  final List<String> functionalDependencies;
  final bool hasRelevantDrugTherapy;

  @override
  List<Object?> get props => [
    patientId,
    requiresConstantCare,
    hasMobilityImpairment,
    functionalDependencies,
    hasRelevantDrugTherapy,
  ];
}
