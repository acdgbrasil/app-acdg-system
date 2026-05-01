import 'package:shared/shared.dart';

import '../../ui/home/models/social_health_summary_detail.dart';
import '../commands/assessment_intents.dart';

/// Maps [SocialHealthSummaryDetail] (parsed patient aggregate) to
/// [UpdateSocialHealthSummaryIntent] — used to pre-fill the edit form.
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
