import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../commands/assessment_intents.dart';

/// Maps [UpdateHealthStatusIntent] to the [HealthStatus] domain object.
/// Dedicated mapper for the Health Status endpoint.
abstract final class HealthStatusMapper {
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
