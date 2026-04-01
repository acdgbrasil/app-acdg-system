import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/intervention_intents.dart';
import '../models/placement_history_detail.dart';

/// Maps [PlacementHistoryDetail] → [UpdatePlacementHistoryIntent].
abstract final class PlacementHistoryDetailMapper {
  static Result<UpdatePlacementHistoryIntent> toIntent(
    PlacementHistoryDetail detail, {
    required PatientId patientId,
  }) {
    final placements = <PlacementRegistry>[];
    for (final (i, p) in detail.individualPlacements.indexed) {
      final PersonId memberId;
      switch (PersonId.create(p.memberId)) {
        case Success(:final value): memberId = value;
        case Failure(:final error):
          return Failure('individualPlacements[$i].memberId: $error');
      }

      final TimeStamp startDate;
      switch (TimeStamp.fromIso(p.startDate)) {
        case Success(:final value): startDate = value;
        case Failure(:final error):
          return Failure('individualPlacements[$i].startDate: $error');
      }

      TimeStamp? endDate;
      if (p.endDate != null) {
        switch (TimeStamp.fromIso(p.endDate!)) {
          case Success(:final value): endDate = value;
          case Failure(:final error):
            return Failure('individualPlacements[$i].endDate: $error');
        }
      }

      switch (PlacementRegistry.create(
        id: p.id,
        memberId: memberId,
        startDate: startDate,
        endDate: endDate,
        reason: p.reason,
      )) {
        case Success(:final value): placements.add(value);
        case Failure(:final error):
          return Failure('individualPlacements[$i]: $error');
      }
    }

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

    return Success(UpdatePlacementHistoryIntent(
      patientId: patientId,
      history: history,
    ));
  }
}
