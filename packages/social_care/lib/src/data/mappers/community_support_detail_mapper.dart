import 'package:shared/shared.dart';

import '../../ui/home/models/community_support_network_detail.dart';
import '../commands/assessment_intents.dart';

/// Maps [CommunitySupportNetworkDetail] (parsed patient aggregate) to
/// [UpdateCommunitySupportIntent] — used to pre-fill the edit form.
abstract final class CommunitySupportDetailMapper {
  static UpdateCommunitySupportIntent toIntent(
    CommunitySupportNetworkDetail detail, {
    required PatientId patientId,
  }) {
    return UpdateCommunitySupportIntent(
      patientId: patientId,
      hasRelativeSupport: detail.hasRelativeSupport,
      hasNeighborSupport: detail.hasNeighborSupport,
      familyConflicts: detail.familyConflicts,
      patientParticipatesInGroups: detail.patientParticipatesInGroups,
      familyParticipatesInGroups: detail.familyParticipatesInGroups,
      patientHasAccessToLeisure: detail.patientHasAccessToLeisure,
      facesDiscrimination: detail.facesDiscrimination,
    );
  }
}
