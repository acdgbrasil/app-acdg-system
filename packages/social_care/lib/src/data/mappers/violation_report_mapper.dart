import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../commands/intervention_intents.dart';

/// Maps [ReportViolationIntent] to the [RightsViolationReport] domain
/// aggregate. Dedicated mapper for the Report Rights Violation endpoint.
abstract final class ViolationReportMapper {
  /// Maps [ReportViolationIntent] to [RightsViolationReport].
  static Result<RightsViolationReport> toViolationReport(
    ReportViolationIntent intent,
  ) {
    final ViolationReportId id;
    switch (ViolationReportId.create(UuidUtil.generateV4())) {
      case Success(:final value):
        id = value;
      case Failure(:final error):
        return Failure(error);
    }

    final PersonId victimId;
    switch (PersonId.create(intent.victimId)) {
      case Success(:final value):
        victimId = value;
      case Failure(:final error):
        return Failure(error);
    }

    TimeStamp? incidentDate;
    if (intent.incidentDate != null) {
      switch (TimeStamp.fromDate(intent.incidentDate)) {
        case Success(:final value):
          incidentDate = value;
        case Failure(:final error):
          return Failure(error);
      }
    }

    LookupId? violationTypeId;
    if (intent.violationTypeId != null) {
      switch (LookupId.create(intent.violationTypeId!)) {
        case Success(:final value):
          violationTypeId = value;
        case Failure(:final error):
          return Failure(error);
      }
    }

    return RightsViolationReport.create(
      id: id,
      reportDate: TimeStamp.now,
      incidentDate: incidentDate,
      victimId: victimId,
      violationType: intent.violationType,
      violationTypeId: violationTypeId,
      descriptionOfFact: intent.descriptionOfFact,
      actionsTaken: intent.actionsTaken,
    );
  }
}
