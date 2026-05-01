import 'package:shared/shared.dart';

import '../../ui/home/models/housing_condition_detail.dart';
import '../commands/assessment_intents.dart';

/// Maps [HousingConditionDetail] (parsed patient aggregate) to
/// [UpdateHousingConditionIntent] — used to pre-fill the edit form.
abstract final class HousingConditionDetailMapper {
  static UpdateHousingConditionIntent toIntent(
    HousingConditionDetail detail, {
    required PatientId patientId,
  }) {
    return UpdateHousingConditionIntent(
      patientId: patientId,
      type: ConditionType.values.byName(detail.type),
      wallMaterial: WallMaterial.values.byName(detail.wallMaterial),
      waterSupply: WaterSupply.values.byName(detail.waterSupply),
      electricityAccess: ElectricityAccess.values.byName(
        detail.electricityAccess,
      ),
      sewageDisposal: SewageDisposal.values.byName(detail.sewageDisposal),
      wasteCollection: WasteCollection.values.byName(detail.wasteCollection),
      accessibilityLevel: AccessibilityLevel.values.byName(
        detail.accessibilityLevel,
      ),
      numberOfRooms: detail.numberOfRooms,
      numberOfBedrooms: detail.numberOfBedrooms,
      numberOfBathrooms: detail.numberOfBathrooms,
      hasPipedWater: detail.hasPipedWater,
      isInGeographicRiskArea: detail.isInGeographicRiskArea,
      hasDifficultAccess: detail.hasDifficultAccess,
      isInSocialConflictArea: detail.isInSocialConflictArea,
      hasDiagnosticObservations: detail.hasDiagnosticObservations,
    );
  }
}
