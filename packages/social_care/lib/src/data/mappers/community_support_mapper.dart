import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../commands/assessment_intents.dart';

/// Maps [UpdateCommunitySupportIntent] to the [CommunitySupportNetwork]
/// domain value object. Dedicated mapper for the Community Support endpoint.
abstract final class CommunitySupportMapper {
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
}
