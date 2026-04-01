import 'package:core/core.dart';
import 'package:shared/shared.dart';

/// Intent to register an appointment with raw data.
final class RegisterAppointmentIntent with Equatable {
  const RegisterAppointmentIntent({
    required this.patientId,
    required this.professionalId,
    required this.type,
    this.summary,
    this.actionPlan,
    this.date,
  });

  final PatientId patientId;
  final String professionalId;
  final AppointmentType type;
  final String? summary;
  final String? actionPlan;
  final DateTime? date;

  @override
  List<Object?> get props => [
    patientId,
    professionalId,
    type,
    summary,
    actionPlan,
    date,
  ];
}

/// Intent to report a violation with raw data.
final class ReportViolationIntent with Equatable {
  const ReportViolationIntent({
    required this.patientId,
    required this.victimId,
    required this.violationType,
    this.violationTypeId,
    required this.descriptionOfFact,
    this.incidentDate,
    this.actionsTaken,
  });

  final PatientId patientId;
  final String victimId;
  final ViolationType violationType;
  final String? violationTypeId;
  final String descriptionOfFact;
  final DateTime? incidentDate;
  final String? actionsTaken;

  @override
  List<Object?> get props => [
    patientId,
    victimId,
    violationType,
    violationTypeId,
    descriptionOfFact,
    incidentDate,
    actionsTaken,
  ];
}

/// Intent to create a referral with raw data.
final class CreateReferralIntent with Equatable {
  const CreateReferralIntent({
    required this.patientId,
    required this.referredPersonId,
    required this.professionalId,
    required this.destinationService,
    required this.reason,
    this.date,
  });

  final PatientId patientId;
  final String referredPersonId;
  final String professionalId;
  final DestinationService destinationService;
  final String reason;
  final DateTime? date;

  @override
  List<Object?> get props => [
    patientId,
    referredPersonId,
    professionalId,
    destinationService,
    reason,
    date,
  ];
}

/// Intent to update intake information.
final class UpdateIntakeInfoIntent with Equatable {
  const UpdateIntakeInfoIntent({required this.patientId, required this.info});

  final PatientId patientId;
  final IngressInfo info;

  @override
  List<Object?> get props => [patientId, info];
}

/// Intent to update institutional placement history.
final class UpdatePlacementHistoryIntent with Equatable {
  const UpdatePlacementHistoryIntent({
    required this.patientId,
    required this.history,
  });

  final PatientId patientId;
  final PlacementHistory history;

  @override
  List<Object?> get props => [patientId, history];
}
