import '../../models/protection/placement_history.dart';
import '../../models/protection/referral.dart';
import '../../models/protection/violation_report.dart';
import 'patient_mapper.dart';

/// JSON → domain model mappers for Protection bounded context.
abstract final class ProtectionMappers {
  static PlacementHistory? placementHistoryFromJson(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return PlacementHistory(
      individualPlacements: parseList(
        m['individualPlacements'],
        _parsePlacementRegistry,
      ),
      homeLossReport: m['homeLossReport'] as String?,
      thirdPartyGuardReport: m['thirdPartyGuardReport'] as String?,
      adultInPrison: m['adultInPrison'] as bool?,
      adolescentInInternment: m['adolescentInInternment'] as bool?,
    );
  }

  static PlacementRegistry _parsePlacementRegistry(
    Map<String, dynamic> json,
  ) => PlacementRegistry(
    id: json['id'] as String,
    memberId: json['memberId'] as String,
    reason: json['reason'] as String,
    startDate: parseDateTime(json['startDate']),
    endDate: parseDateTime(json['endDate']),
  );

  static Referral referralFromJson(Map<String, dynamic> json) => Referral(
    id: json['id'] as String,
    referredPersonId: json['referredPersonId'] as String,
    destinationService: json['destinationService'] as String,
    reason: json['reason'] as String,
    date: parseDateTime(json['date']),
    professionalId: json['professionalId'] as String?,
    status: json['status'] as String?,
  );

  static ViolationReport violationReportFromJson(Map<String, dynamic> json) =>
      ViolationReport(
        id: json['id'] as String,
        victimId: json['victimId'] as String,
        violationType: json['violationType'] as String,
        descriptionOfFact: json['descriptionOfFact'] as String,
        reportDate: parseDateTime(json['reportDate']),
        incidentDate: parseDateTime(json['incidentDate']),
        actionsTaken: json['actionsTaken'] as String?,
      );
}
