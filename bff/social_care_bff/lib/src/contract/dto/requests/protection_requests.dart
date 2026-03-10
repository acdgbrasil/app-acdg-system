/// Request to update institutional placement history.
final class UpdatePlacementHistoryRequest {
  const UpdatePlacementHistoryRequest({
    required this.registries,
    required this.separationChecklist,
    this.collectiveSituations,
  });

  final List<PlacementRegistryDto> registries;
  final SeparationChecklistDto separationChecklist;
  final CollectiveSituationsDto? collectiveSituations;

  Map<String, dynamic> toJson() => {
    'registries': registries.map((r) => r.toJson()).toList(),
    'separationChecklist': separationChecklist.toJson(),
    if (collectiveSituations != null)
      'collectiveSituations': collectiveSituations!.toJson(),
  };
}

final class PlacementRegistryDto {
  const PlacementRegistryDto({
    required this.memberId,
    required this.startDate,
    required this.reason,
    this.endDate,
  });

  final String memberId;
  final DateTime startDate;
  final String reason;
  final DateTime? endDate;

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'startDate': startDate.toIso8601String(),
    'reason': reason,
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
  };
}

final class CollectiveSituationsDto {
  const CollectiveSituationsDto({
    this.homeLossReport,
    this.thirdPartyGuardReport,
  });

  final String? homeLossReport;
  final String? thirdPartyGuardReport;

  Map<String, dynamic> toJson() => {
    if (homeLossReport != null) 'homeLossReport': homeLossReport,
    if (thirdPartyGuardReport != null)
      'thirdPartyGuardReport': thirdPartyGuardReport,
  };
}

final class SeparationChecklistDto {
  const SeparationChecklistDto({
    required this.adultInPrison,
    required this.adolescentInInternment,
  });

  final bool adultInPrison;
  final bool adolescentInInternment;

  Map<String, dynamic> toJson() => {
    'adultInPrison': adultInPrison,
    'adolescentInInternment': adolescentInInternment,
  };
}

/// Request to report a rights violation.
final class ReportRightsViolationRequest {
  const ReportRightsViolationRequest({
    required this.victimId,
    required this.violationType,
    required this.descriptionOfFact,
    this.violationTypeId,
    this.reportDate,
    this.incidentDate,
    this.actionsTaken,
  });

  final String victimId;
  final String violationType;
  final String descriptionOfFact;
  final String? violationTypeId;
  final DateTime? reportDate;
  final DateTime? incidentDate;
  final String? actionsTaken;

  Map<String, dynamic> toJson() => {
    'victimId': victimId,
    'violationType': violationType,
    'descriptionOfFact': descriptionOfFact,
    if (violationTypeId != null) 'violationTypeId': violationTypeId,
    if (reportDate != null) 'reportDate': reportDate!.toIso8601String(),
    if (incidentDate != null) 'incidentDate': incidentDate!.toIso8601String(),
    if (actionsTaken != null) 'actionsTaken': actionsTaken,
  };
}

/// Request to create a referral.
final class CreateReferralRequest {
  const CreateReferralRequest({
    required this.referredPersonId,
    required this.destinationService,
    required this.reason,
    this.professionalId,
    this.date,
  });

  final String referredPersonId;
  final String destinationService;
  final String reason;
  final String? professionalId;
  final DateTime? date;

  Map<String, dynamic> toJson() => {
    'referredPersonId': referredPersonId,
    'destinationService': destinationService,
    'reason': reason,
    if (professionalId != null) 'professionalId': professionalId,
    if (date != null) 'date': date!.toIso8601String(),
  };
}
