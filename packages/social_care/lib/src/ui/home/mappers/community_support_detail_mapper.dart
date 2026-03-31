import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../models/community_support_network_detail.dart';

/// Maps [CommunitySupportNetworkDetail] → [UpdateCommunitySupportIntent].
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
