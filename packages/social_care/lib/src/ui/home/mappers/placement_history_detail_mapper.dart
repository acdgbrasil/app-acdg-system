import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/intervention_intents.dart';
import '../models/placement_history_detail.dart';

/// Maps [PlacementHistoryDetail] → [UpdatePlacementHistoryIntent].
abstract final class PlacementHistoryDetailMapper {
  static UpdatePlacementHistoryIntent toIntent(
    PlacementHistoryDetail detail, {
    required PatientId patientId,
  }) {
    final placements = detail.individualPlacements
        .map(
          (p) => PlacementRegistry.create(
            id: p.id,
            memberId: PersonId.create(p.memberId).valueOrNull!,
            startDate: TimeStamp.fromIso(p.startDate).valueOrNull!,
            endDate: p.endDate != null
                ? TimeStamp.fromIso(p.endDate!).valueOrNull
                : null,
            reason: p.reason,
          ),
        )
        .whereType<Success<PlacementRegistry>>()
        .map((r) => r.value)
        .toList();

    final history = PlacementHistory(
      familyId: patientId,
      individualPlacements: placements,
      collectiveSituations: CollectiveSituations(
        homeLossReport: detail.homeLossReport,
        thirdPartyGuardReport: detail.thirdPartyGuardReport,
      ),
      separationChecklist: SeparationChecklist(
        adultInPrison: detail.adultInPrison,
        adolescentInInternment: detail.adolescentInInternment,
      ),
    );

    return UpdatePlacementHistoryIntent(
      patientId: patientId,
      history: history,
    );
  }
}
