import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../commands/assessment_intents.dart';

/// Maps [UpdateSocialHealthSummaryIntent] to the [SocialHealthSummary]
/// domain value object. Dedicated mapper for the Social Health Summary
/// endpoint.
abstract final class SocialHealthSummaryMapper {
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
}
