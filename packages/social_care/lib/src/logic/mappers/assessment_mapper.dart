import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../data/commands/assessment_intents.dart';

/// Specialized mapper to assemble Assessment-related domain objects.
abstract final class AssessmentMapper {
  /// Maps [UpdateHousingConditionIntent] to [HousingCondition].
  static Result<HousingCondition> toHousingCondition(
    UpdateHousingConditionIntent intent,
  ) {
    return HousingCondition.create(
      type: intent.type,
      wallMaterial: intent.wallMaterial,
      numberOfRooms: intent.numberOfRooms,
      numberOfBedrooms: intent.numberOfBedrooms,
      numberOfBathrooms: intent.numberOfBathrooms,
      waterSupply: intent.waterSupply,
      hasPipedWater: intent.hasPipedWater,
      electricityAccess: intent.electricityAccess,
      sewageDisposal: intent.sewageDisposal,
      wasteCollection: intent.wasteCollection,
      accessibilityLevel: intent.accessibilityLevel,
      isInGeographicRiskArea: intent.isInGeographicRiskArea,
      hasDifficultAccess: intent.hasDifficultAccess,
      isInSocialConflictArea: intent.isInSocialConflictArea,
      hasDiagnosticObservations: intent.hasDiagnosticObservations,
    );
  }

  /// Maps [UpdateSocioEconomicIntent] to [SocioEconomicSituation].
  static Result<SocioEconomicSituation> toSocioEconomic(
    UpdateSocioEconomicIntent intent,
  ) {
    final collectionRes = SocialBenefitsCollection.create(
      intent.socialBenefits,
    );
    if (collectionRes case Failure(:final error)) return Failure(error);

    return SocioEconomicSituation.create(
      totalFamilyIncome: intent.totalFamilyIncome,
      incomePerCapita: intent.incomePerCapita,
      receivesSocialBenefit: intent.receivesSocialBenefit,
      socialBenefits:
          (collectionRes as Success<SocialBenefitsCollection>).value,
      mainSourceOfIncome: intent.mainSourceOfIncome,
      hasUnemployed: intent.hasUnemployed,
    );
  }

  /// Maps [UpdateSocialHealthSummaryIntent] to [SocialHealthSummary].
  static Result<SocialHealthSummary> toSocialHealthSummary(
    UpdateSocialHealthSummaryIntent intent,
  ) {
    return SocialHealthSummary.create(
      requiresConstantCare: intent.requiresConstantCare,
      hasMobilityImpairment: intent.hasMobilityImpairment,
      functionalDependencies: intent.functionalDependencies,
      hasRelevantDrugTherapy: intent.hasRelevantDrugTherapy,
    );
  }

  /// Maps [UpdateCommunitySupportIntent] to [CommunitySupportNetwork].
  static Result<CommunitySupportNetwork> toCommunitySupport(
    UpdateCommunitySupportIntent intent,
  ) {
    return CommunitySupportNetwork.create(
      hasRelativeSupport: intent.hasRelativeSupport,
      hasNeighborSupport: intent.hasNeighborSupport,
      familyConflicts: intent.familyConflicts,
      patientParticipatesInGroups: intent.patientParticipatesInGroups,
      familyParticipatesInGroups: intent.familyParticipatesInGroups,
      patientHasAccessToLeisure: intent.patientHasAccessToLeisure,
      facesDiscrimination: intent.facesDiscrimination,
    );
  }

  /// Maps [UpdateEducationalStatusIntent] to [EducationalStatus].
  static Result<EducationalStatus> toEducationalStatus(
    UpdateEducationalStatusIntent intent,
  ) {
    return Success(
      EducationalStatus(
        familyId: intent.patientId,
        memberProfiles: intent.memberProfiles,
        programOccurrences: intent.programOccurrences,
      ),
    );
  }

  /// Maps [UpdateHealthStatusIntent] to [HealthStatus].
  static Result<HealthStatus> toHealthStatus(UpdateHealthStatusIntent intent) {
    return Success(
      HealthStatus(
        familyId: intent.patientId,
        deficiencies: intent.deficiencies,
        gestatingMembers: intent.gestatingMembers,
        constantCareNeeds: intent.constantCareNeeds,
        foodInsecurity: intent.foodInsecurity,
      ),
    );
  }
}
