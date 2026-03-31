import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../models/social_health_summary_detail.dart';

/// Maps [SocialHealthSummaryDetail] → [UpdateSocialHealthSummaryIntent].
abstract final class SocialHealthSummaryDetailMapper {
  static UpdateSocialHealthSummaryIntent toIntent(
    SocialHealthSummaryDetail detail, {
    required PatientId patientId,
  }) {
    return UpdateSocialHealthSummaryIntent(
      patientId: patientId,
      requiresConstantCare: detail.requiresConstantCare,
      hasMobilityImpairment: detail.hasMobilityImpairment,
      hasRelevantDrugTherapy: detail.hasRelevantDrugTherapy,
      functionalDependencies: detail.functionalDependencies,
    );
  }
}
