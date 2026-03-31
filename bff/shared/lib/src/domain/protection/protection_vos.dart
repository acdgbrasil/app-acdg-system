import 'package:core/core.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';
import '../kernel/ids.dart';
import '../kernel/time_stamp.dart';

// =============================================================================
// REFERRAL
// =============================================================================

enum DestinationService { cras, creas, healthCare, education, legal, other }

enum ReferralStatus { pending, completed, cancelled }

final class Referral with Equatable {
  const Referral._({
    required this.id,
    required this.date,
    required this.requestingProfessionalId,
    required this.referredPersonId,
    required this.destinationService,
    required this.reason,
    required this.status,
  });

  final ReferralId id;
  final TimeStamp date;
  final ProfessionalId requestingProfessionalId;
  final PersonId referredPersonId;
  final DestinationService destinationService;
  final String reason;
  final ReferralStatus status;

  @override
  List<Object?> get props => [id];

  Referral copyWith({
    ReferralId? id,
    TimeStamp? date,
    ProfessionalId? requestingProfessionalId,
    PersonId? referredPersonId,
    DestinationService? destinationService,
    String? reason,
    ReferralStatus? status,
  }) {
    return Referral._(
      id: id ?? this.id,
      date: date ?? this.date,
      requestingProfessionalId:
          requestingProfessionalId ?? this.requestingProfessionalId,
      referredPersonId: referredPersonId ?? this.referredPersonId,
      destinationService: destinationService ?? this.destinationService,
      reason: reason ?? this.reason,
      status: status ?? this.status,
    );
  }

  static Result<Referral> create({
    required ReferralId id,
    required TimeStamp date,
    required ProfessionalId requestingProfessionalId,
    required PersonId referredPersonId,
    required DestinationService destinationService,
    required String? reason,
    ReferralStatus status = ReferralStatus.pending,
    TimeStamp? now,
  }) {
    final refNow = now ?? TimeStamp.now;
    if (date.date.isAfter(refNow.date)) {
      return Failure(
        _buildRefError(
          'REF-001',
          'Data do encaminhamento não pode ser no futuro',
        ),
      );
    }

    final r = reason?.normalizedTrim();
    if (r == null || r.isEmpty) {
      return Failure(
        _buildRefError(
          'REF-002',
          'Motivo do encaminhamento não pode ser vazio',
        ),
      );
    }

    return Success(
      Referral._(
        id: id,
        date: date,
        requestingProfessionalId: requestingProfessionalId,
        referredPersonId: referredPersonId,
        destinationService: destinationService,
        reason: r,
        status: status,
      ),
    );
  }

  Result<Referral> complete() {
    if (status != ReferralStatus.pending)
      return Failure(
        _buildRefError(
          'REF-003',
          'Transição de status inválida. Só é possível alterar status a partir de PENDING',
          severity: ErrorSeverity.error,
        ),
      );
    return Success(
      Referral._(
        id: id,
        date: date,
        requestingProfessionalId: requestingProfessionalId,
        referredPersonId: referredPersonId,
        destinationService: destinationService,
        reason: reason,
        status: ReferralStatus.completed,
      ),
    );
  }

  Result<Referral> cancel() {
    if (status != ReferralStatus.pending)
      return Failure(
        _buildRefError(
          'REF-003',
          'Transição de status inválida. Só é possível alterar status a partir de PENDING',
          severity: ErrorSeverity.error,
        ),
      );
    return Success(
      Referral._(
        id: id,
        date: date,
        requestingProfessionalId: requestingProfessionalId,
        referredPersonId: referredPersonId,
        destinationService: destinationService,
        reason: reason,
        status: ReferralStatus.cancelled,
      ),
    );
  }

  static AppError _buildRefError(
    String code,
    String message, {
    ErrorSeverity severity = ErrorSeverity.warning,
  }) {
    return AppError(
      code: code,
      message: message,
      module: 'social-care/referral',
      kind: 'domainValidation',
      http: 422,
      observability: Observability(
        category: ErrorCategory.domainRuleViolation,
        severity: severity,
      ),
    );
  }
}

// =============================================================================
// RIGHTS VIOLATION REPORT
// =============================================================================

enum ViolationType {
  neglect,
  psychologicalViolence,
  physicalViolence,
  sexualAbuse,
  sexualExploitation,
  childLabor,
  financialExploitation,
  discrimination,
  other,
}

final class RightsViolationReport with Equatable {
  const RightsViolationReport._({
    required this.id,
    required this.reportDate,
    this.incidentDate,
    required this.victimId,
    required this.violationType,
    required this.descriptionOfFact,
    this.actionsTaken,
  });

  final ViolationReportId id;
  final TimeStamp reportDate;
  final TimeStamp? incidentDate;
  final PersonId victimId;
  final ViolationType violationType;
  final String descriptionOfFact;
  final String? actionsTaken;

  @override
  List<Object?> get props => [id];

  RightsViolationReport copyWith({
    ViolationReportId? id,
    TimeStamp? reportDate,
    TimeStamp? Function()? incidentDate,
    PersonId? victimId,
    ViolationType? violationType,
    String? descriptionOfFact,
    String? Function()? actionsTaken,
  }) {
    return RightsViolationReport._(
      id: id ?? this.id,
      reportDate: reportDate ?? this.reportDate,
      incidentDate: incidentDate != null ? incidentDate() : this.incidentDate,
      victimId: victimId ?? this.victimId,
      violationType: violationType ?? this.violationType,
      descriptionOfFact: descriptionOfFact ?? this.descriptionOfFact,
      actionsTaken: actionsTaken != null ? actionsTaken() : this.actionsTaken,
    );
  }

  static Result<RightsViolationReport> create({
    required ViolationReportId id,
    required TimeStamp reportDate,
    TimeStamp? incidentDate,
    required PersonId victimId,
    required ViolationType violationType,
    required String? descriptionOfFact,
    String? actionsTaken,
    TimeStamp? now,
  }) {
    final refNow = now ?? TimeStamp.now;
    if (reportDate.date.isAfter(refNow.date)) {
      return Failure(
        _buildRvrError('RVR-001', 'Data da notificação não pode ser no futuro'),
      );
    }

    if (incidentDate != null && incidentDate.date.isAfter(reportDate.date)) {
      return Failure(
        _buildRvrError(
          'RVR-002',
          'Data do incidente não pode ser posterior à data da notificação',
        ),
      );
    }

    final desc = descriptionOfFact?.normalizedTrim();
    if (desc == null || desc.isEmpty) {
      return Failure(
        _buildRvrError('RVR-003', 'Descrição do fato não pode ser vazia'),
      );
    }

    return Success(
      RightsViolationReport._(
        id: id,
        reportDate: reportDate,
        incidentDate: incidentDate,
        victimId: victimId,
        violationType: violationType,
        descriptionOfFact: desc,
        actionsTaken: actionsTaken?.normalizedTrim(),
      ),
    );
  }

  RightsViolationReport updateActions(String newActions) {
    return RightsViolationReport._(
      id: id,
      reportDate: reportDate,
      incidentDate: incidentDate,
      victimId: victimId,
      violationType: violationType,
      descriptionOfFact: descriptionOfFact,
      actionsTaken: newActions.normalizedTrim(),
    );
  }

  static AppError _buildRvrError(String code, String message) {
    return AppError(
      code: code,
      message: message,
      module: 'social-care/rights-violation',
      kind: 'domainValidation',
      http: 422,
      observability: const Observability(
        category: ErrorCategory.domainRuleViolation,
        severity: ErrorSeverity.warning,
      ),
    );
  }
}

// =============================================================================
// PLACEMENT HISTORY
// =============================================================================

final class PlacementRegistry with Equatable {
  const PlacementRegistry._({
    required this.id,
    required this.memberId,
    required this.startDate,
    this.endDate,
    required this.reason,
  });

  final String id;
  final PersonId memberId;
  final TimeStamp startDate;
  final TimeStamp? endDate;
  final String reason;

  @override
  List<Object?> get props => [id, memberId, startDate, endDate, reason];

  static Result<PlacementRegistry> create({
    String? id,
    required PersonId memberId,
    required TimeStamp startDate,
    TimeStamp? endDate,
    required String reason,
  }) {
    if (endDate != null && endDate.date.isBefore(startDate.date)) {
      return Failure(
        AppError(
          code: 'PLC-001',
          message: 'Data de término não pode ser anterior à data de início',
          module: 'social-care/placement',
          kind: 'domainValidation',
          http: 422,
          observability: const Observability(
            category: ErrorCategory.domainRuleViolation,
            severity: ErrorSeverity.warning,
          ),
        ),
      );
    }
    // id could be auto-generated UUID if null, but as string. We'll use DateTime for fake generation if null, though real system uses UUID.
    final finalId = id ?? DateTime.now().microsecondsSinceEpoch.toString();
    return Success(
      PlacementRegistry._(
        id: finalId,
        memberId: memberId,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      ),
    );
  }
}

final class CollectiveSituations with Equatable {
  const CollectiveSituations({this.homeLossReport, this.thirdPartyGuardReport});
  final String? homeLossReport;
  final String? thirdPartyGuardReport;
  @override
  List<Object?> get props => [homeLossReport, thirdPartyGuardReport];
}

final class SeparationChecklist with Equatable {
  const SeparationChecklist({
    required this.adultInPrison,
    required this.adolescentInInternment,
  });
  final bool adultInPrison;
  final bool adolescentInInternment;
  @override
  List<Object?> get props => [adultInPrison, adolescentInInternment];
}

final class PlacementHistory with Equatable {
  const PlacementHistory({
    required this.familyId,
    required this.individualPlacements,
    required this.collectiveSituations,
    required this.separationChecklist,
  });

  final PatientId familyId;
  final List<PlacementRegistry> individualPlacements;
  final CollectiveSituations collectiveSituations;
  final SeparationChecklist separationChecklist;

  @override
  List<Object?> get props => [
    familyId,
    individualPlacements,
    collectiveSituations,
    separationChecklist,
  ];
}
