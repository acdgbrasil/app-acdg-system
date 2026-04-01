import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../data/commands/intervention_intents.dart';

/// Specialized mapper to assemble Intervention-related domain objects.
abstract final class InterventionMapper {
  /// Maps [RegisterAppointmentIntent] to [SocialCareAppointment].
  static Result<SocialCareAppointment> toAppointment(
    RegisterAppointmentIntent intent,
  ) {
    final idRes = AppointmentId.create(UuidUtil.generateV4());
    final profIdRes = ProfessionalId.create(intent.professionalId);
    final dateRes = TimeStamp.fromDate(intent.date ?? DateTime.now());

    if (idRes case Failure(:final error)) return Failure(error);
    if (profIdRes case Failure(:final error)) return Failure(error);
    if (dateRes case Failure(:final error)) return Failure(error);

    return SocialCareAppointment.create(
      id: (idRes as Success<AppointmentId>).value,
      date: (dateRes as Success<TimeStamp>).value,
      professionalInChargeId: (profIdRes as Success<ProfessionalId>).value,
      type: intent.type,
      summary: intent.summary,
      actionPlan: intent.actionPlan,
    );
  }

  /// Maps [ReportViolationIntent] to [RightsViolationReport].
  static Result<RightsViolationReport> toViolationReport(
    ReportViolationIntent intent,
  ) {
    final idRes = ViolationReportId.create(UuidUtil.generateV4());
    final victimIdRes = PersonId.create(intent.victimId);
    final reportDateRes = TimeStamp.now;
    final incidentDateRes = intent.incidentDate != null
        ? TimeStamp.fromDate(intent.incidentDate)
        : null;
    final violationTypeIdRes = intent.violationTypeId != null
        ? LookupId.create(intent.violationTypeId!)
        : null;

    if (idRes case Failure(:final error)) return Failure(error);
    if (victimIdRes case Failure(:final error)) return Failure(error);
    if (incidentDateRes != null && incidentDateRes is Failure)
      return Failure((incidentDateRes as Failure).error);
    if (violationTypeIdRes case Failure(:final error)) return Failure(error);

    return RightsViolationReport.create(
      id: (idRes as Success<ViolationReportId>).value,
      reportDate: reportDateRes,
      incidentDate: incidentDateRes != null
          ? (incidentDateRes as Success<TimeStamp>).value
          : null,
      victimId: (victimIdRes as Success<PersonId>).value,
      violationType: intent.violationType,
      violationTypeId: violationTypeIdRes != null
          ? (violationTypeIdRes as Success<LookupId>).value
          : null,
      descriptionOfFact: intent.descriptionOfFact,
      actionsTaken: intent.actionsTaken,
    );
  }

  /// Maps [CreateReferralIntent] to [Referral].
  static Result<Referral> toReferral(CreateReferralIntent intent) {
    final idRes = ReferralId.create(UuidUtil.generateV4());
    final referredIdRes = PersonId.create(intent.referredPersonId);
    final profIdRes = intent.professionalId.isNotEmpty
        ? ProfessionalId.create(intent.professionalId)
        : null;
    final dateRes = TimeStamp.fromDate(intent.date ?? DateTime.now());

    if (idRes case Failure(:final error)) return Failure(error);
    if (referredIdRes case Failure(:final error)) return Failure(error);
    if (profIdRes != null && profIdRes is Failure)
      return Failure((profIdRes as Failure).error);
    if (dateRes case Failure(:final error)) return Failure(error);

    return Referral.create(
      id: (idRes as Success<ReferralId>).value,
      date: (dateRes as Success<TimeStamp>).value,
      requestingProfessionalId: profIdRes != null
          ? (profIdRes as Success<ProfessionalId>).value
          : ProfessionalId.create(
              '00000000-0000-0000-0000-000000000000',
            ).valueOrNull!,
      referredPersonId: (referredIdRes as Success<PersonId>).value,
      destinationService: intent.destinationService,
      reason: intent.reason,
    );
  }
}
