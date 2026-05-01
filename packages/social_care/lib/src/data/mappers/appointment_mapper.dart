import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../commands/intervention_intents.dart';

/// Maps [RegisterAppointmentIntent] to the [SocialCareAppointment] domain
/// aggregate. Dedicated mapper for the Register Appointment endpoint.
abstract final class AppointmentMapper {
  /// Maps [RegisterAppointmentIntent] to [SocialCareAppointment].
  static Result<SocialCareAppointment> toAppointment(
    RegisterAppointmentIntent intent,
  ) {
    final AppointmentId id;
    switch (AppointmentId.create(UuidUtil.generateV4())) {
      case Success(:final value):
        id = value;
      case Failure(:final error):
        return Failure(error);
    }

    final ProfessionalId professionalInChargeId;
    switch (ProfessionalId.create(intent.professionalId)) {
      case Success(:final value):
        professionalInChargeId = value;
      case Failure(:final error):
        return Failure(error);
    }

    final TimeStamp date;
    switch (TimeStamp.fromDate(intent.date ?? DateTime.now())) {
      case Success(:final value):
        date = value;
      case Failure(:final error):
        return Failure(error);
    }

    return SocialCareAppointment.create(
      id: id,
      date: date,
      professionalInChargeId: professionalInChargeId,
      type: intent.type,
      summary: intent.summary,
      actionPlan: intent.actionPlan,
    );
  }
}
