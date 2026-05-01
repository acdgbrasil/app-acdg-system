import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../commands/assessment_intents.dart';

/// Maps [UpdateHousingConditionIntent] to the [HousingCondition] domain
/// value object. Dedicated mapper for the Housing Condition endpoint.
abstract final class HousingConditionMapper {
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
}
