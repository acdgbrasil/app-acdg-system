import '../../models/care/appointment.dart';
import '../../models/care/intake_info.dart';
import 'patient_mapper.dart';

/// JSON → domain model mappers for Care bounded context.
abstract final class CareMappers {
  static Appointment appointmentFromJson(Map<String, dynamic> json) =>
      Appointment(
        id: json['id'] as String,
        professionalId: json['professionalId'] as String,
        date: parseDateTime(json['date']),
        type: json['type'] as String?,
        summary: json['summary'] as String?,
        actionPlan: json['actionPlan'] as String?,
      );

  static IntakeInfo? intakeInfoFromJson(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return IntakeInfo(
      ingressTypeId: m['ingressTypeId'] as String,
      originName: m['originName'] as String?,
      originContact: m['originContact'] as String?,
      serviceReason: m['serviceReason'] as String,
      linkedSocialPrograms: parseList(
        m['linkedSocialPrograms'],
        _parseProgramLink,
      ),
    );
  }

  static ProgramLink _parseProgramLink(Map<String, dynamic> json) =>
      ProgramLink(
        programId: json['programId'] as String,
        observation: json['observation'] as String?,
      );
}
