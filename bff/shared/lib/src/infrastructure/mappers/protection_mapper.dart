import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'json_helpers.dart';

/// Mapper for the Protection bounded context:
/// PlacementHistory, RightsViolationReport, Referral.
abstract final class ProtectionMapper {
  // ── To JSON ─────────────────────────────────────────────────

  static Map<String, dynamic> placementHistoryToJson(PlacementHistory p) => {
    'registries': p.individualPlacements
        .map(
          (r) => {
            'id': r.id,
            'memberId': r.memberId.value,
            'startDate': r.startDate.toIso8601(),
            'endDate': r.endDate?.toIso8601(),
            'reason': r.reason,
          },
        )
        .toList(),
    'collectiveSituations': {
      'homeLossReport': p.collectiveSituations.homeLossReport,
      'thirdPartyGuardReport': p.collectiveSituations.thirdPartyGuardReport,
    },
    'separationChecklist': {
      'adultInPrison': p.separationChecklist.adultInPrison,
      'adolescentInInternment': p.separationChecklist.adolescentInInternment,
    },
  };

  static Map<String, dynamic> violationReportToJson(RightsViolationReport r) =>
      {
        'id': r.id.value,
        'victimId': r.victimId.value,
        'violationType': r.violationType.name.toSnakeCaseUpper(),
        'violationTypeId': r.violationTypeId?.value,
        'descriptionOfFact': r.descriptionOfFact,
        'reportDate': r.reportDate.toIso8601(),
        'incidentDate': r.incidentDate?.toIso8601(),
        'actionsTaken': r.actionsTaken,
      };

  static Map<String, dynamic> referralToJson(Referral r) => {
    'id': r.id.value,
    'referredPersonId': r.referredPersonId.value,
    'destinationService': r.destinationService.name.toSnakeCaseUpper(),
    'reason': r.reason,
    'date': r.date.toIso8601(),
    'professionalId': r.requestingProfessionalId.value,
    'status': r.status.name.toSnakeCaseUpper(),
  };

  // ── From JSON ───────────────────────────────────────────────

  static Result<PlacementHistory> placementHistoryFromJson(
    Map<String, dynamic> j,
  ) {
    final PatientId familyId;
    switch (idFromJsonOrDefault(PatientId.create, j['familyId'], defaultUuid)) {
      case Success(:final value):
        familyId = value;
      case Failure(:final error):
        return Failure('placementHistory.familyId: $error');
    }

    final registries = <PlacementRegistry>[];
    for (final (i, r) in ((j['registries'] as List?) ?? []).indexed) {
      final m = r as Map<String, dynamic>;

      final PersonId memberId;
      switch (PersonId.create(m['memberId'])) {
        case Success(:final value):
          memberId = value;
        case Failure(:final error):
          return Failure('placementHistory.registries[$i].memberId: $error');
      }

      final TimeStamp startDate;
      switch (TimeStamp.fromIso(m['startDate'])) {
        case Success(:final value):
          startDate = value;
        case Failure(:final error):
          return Failure('placementHistory.registries[$i].startDate: $error');
      }

      TimeStamp? endDate;
      if (m['endDate'] != null) {
        switch (TimeStamp.fromIso(m['endDate'])) {
          case Success(:final value):
            endDate = value;
          case Failure(:final error):
            return Failure('placementHistory.registries[$i].endDate: $error');
        }
      }

      switch (PlacementRegistry.create(
        id: m['id'],
        memberId: memberId,
        startDate: startDate,
        endDate: endDate,
        reason: m['reason'],
      )) {
        case Success(:final value):
          registries.add(value);
        case Failure(:final error):
          return Failure('placementHistory.registries[$i]: $error');
      }
    }

    return Success(
      PlacementHistory(
        familyId: familyId,
        individualPlacements: registries,
        collectiveSituations: CollectiveSituations(
          homeLossReport: j['collectiveSituations']['homeLossReport'],
          thirdPartyGuardReport:
              j['collectiveSituations']['thirdPartyGuardReport'],
        ),
        separationChecklist: SeparationChecklist(
          adultInPrison: j['separationChecklist']['adultInPrison'],
          adolescentInInternment:
              j['separationChecklist']['adolescentInInternment'],
        ),
      ),
    );
  }

  static Result<RightsViolationReport> violationReportFromJson(
    Map<String, dynamic> j,
  ) {
    final ViolationReportId id;
    switch (idFromJsonOrDefault(
      ViolationReportId.create,
      j['id'],
      defaultUuid,
    )) {
      case Success(:final value):
        id = value;
      case Failure(:final error):
        return Failure('violationReport.id: $error');
    }

    final TimeStamp reportDate;
    switch (TimeStamp.fromIso(j['reportDate'])) {
      case Success(:final value):
        reportDate = value;
      case Failure(:final error):
        return Failure('violationReport.reportDate: $error');
    }

    final PersonId victimId;
    switch (PersonId.create(j['victimId'])) {
      case Success(:final value):
        victimId = value;
      case Failure(:final error):
        return Failure('violationReport.victimId: $error');
    }

    final ViolationType violationType;
    switch (enumFromJson(
      ViolationType.values,
      j['violationType'],
      'violationReport.violationType',
    )) {
      case Success(:final value):
        violationType = value;
      case Failure(:final error):
        return Failure(error);
    }

    LookupId? violationTypeId;
    if (j['violationTypeId'] != null) {
      switch (LookupId.create(j['violationTypeId'])) {
        case Success(:final value):
          violationTypeId = value;
        case Failure(:final error):
          return Failure('violationReport.violationTypeId: $error');
      }
    }

    TimeStamp? incidentDate;
    if (j['incidentDate'] != null) {
      switch (TimeStamp.fromIso(j['incidentDate'])) {
        case Success(:final value):
          incidentDate = value;
        case Failure(:final error):
          return Failure('violationReport.incidentDate: $error');
      }
    }

    return RightsViolationReport.create(
      id: id,
      reportDate: reportDate,
      victimId: victimId,
      violationType: violationType,
      violationTypeId: violationTypeId,
      descriptionOfFact: j['descriptionOfFact'],
      incidentDate: incidentDate,
      actionsTaken: j['actionsTaken'],
    );
  }

  static Result<Referral> referralFromJson(Map<String, dynamic> j) {
    final ReferralId id;
    switch (idFromJsonOrDefault(ReferralId.create, j['id'], defaultUuid)) {
      case Success(:final value):
        id = value;
      case Failure(:final error):
        return Failure('referral.id: $error');
    }

    final TimeStamp date;
    switch (TimeStamp.fromIso(j['date'])) {
      case Success(:final value):
        date = value;
      case Failure(:final error):
        return Failure('referral.date: $error');
    }

    final ProfessionalId professionalId;
    switch (ProfessionalId.create(j['professionalId'])) {
      case Success(:final value):
        professionalId = value;
      case Failure(:final error):
        return Failure('referral.professionalId: $error');
    }

    final PersonId referredPersonId;
    switch (PersonId.create(j['referredPersonId'])) {
      case Success(:final value):
        referredPersonId = value;
      case Failure(:final error):
        return Failure('referral.referredPersonId: $error');
    }

    final DestinationService destinationService;
    switch (enumFromJson(
      DestinationService.values,
      j['destinationService'],
      'referral.destinationService',
    )) {
      case Success(:final value):
        destinationService = value;
      case Failure(:final error):
        return Failure(error);
    }

    ReferralStatus status = ReferralStatus.pending;
    if (j['status'] != null) {
      switch (enumFromJson(
        ReferralStatus.values,
        j['status'],
        'referral.status',
      )) {
        case Success(:final value):
          status = value;
        case Failure(:final error):
          return Failure(error);
      }
    }

    return Referral.create(
      id: id,
      date: date,
      requestingProfessionalId: professionalId,
      referredPersonId: referredPersonId,
      destinationService: destinationService,
      reason: j['reason'],
      status: status,
    );
  }
}
