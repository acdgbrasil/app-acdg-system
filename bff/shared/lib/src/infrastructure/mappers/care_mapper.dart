import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'json_helpers.dart';

/// Mapper for the Care bounded context:
/// SocialCareAppointment, IngressInfo.
abstract final class CareMapper {
  // ── To JSON ─────────────────────────────────────────────────

  static Map<String, dynamic> appointmentToJson(SocialCareAppointment a) => {
        'id': a.id.value,
        'professionalId': a.professionalInChargeId.value,
        'summary': a.summary,
        'actionPlan': a.actionPlan,
        'date': a.date.toIso8601(),
        'type': a.type.name.toSnakeCaseUpper(),
      };

  static Map<String, dynamic> intakeInfoToJson(IngressInfo i) => {
        'ingressTypeId': i.ingressTypeId.value,
        'originName': i.originName,
        'originContact': i.originContact,
        'serviceReason': i.serviceReason,
        'linkedSocialPrograms': i.linkedSocialPrograms
            .map((p) => {
                  'programId': p.programId.value,
                  'observation': p.observation,
                })
            .toList(),
      };

  // ── From JSON ───────────────────────────────────────────────

  static Result<SocialCareAppointment> appointmentFromJson(
    Map<String, dynamic> j,
  ) {
    final AppointmentId id;
    switch (idFromJsonOrDefault(AppointmentId.create, j['id'], defaultUuid)) {
      case Success(:final value): id = value;
      case Failure(:final error): return Failure('appointment.id: $error');
    }

    final TimeStamp date;
    switch (TimeStamp.fromIso(j['date'])) {
      case Success(:final value): date = value;
      case Failure(:final error): return Failure('appointment.date: $error');
    }

    final ProfessionalId professionalId;
    switch (ProfessionalId.create(j['professionalId'])) {
      case Success(:final value): professionalId = value;
      case Failure(:final error):
        return Failure('appointment.professionalId: $error');
    }

    final AppointmentType type;
    switch (enumFromJson(AppointmentType.values, j['type'], 'appointment.type')) {
      case Success(:final value): type = value;
      case Failure(:final error): return Failure(error);
    }

    return SocialCareAppointment.create(
      id: id,
      date: date,
      professionalInChargeId: professionalId,
      type: type,
      summary: j['summary'],
      actionPlan: j['actionPlan'],
    );
  }

  static Result<IngressInfo> intakeInfoFromJson(Map<String, dynamic> j) {
    final LookupId ingressTypeId;
    switch (LookupId.create(j['ingressTypeId'])) {
      case Success(:final value): ingressTypeId = value;
      case Failure(:final error):
        return Failure('intakeInfo.ingressTypeId: $error');
    }

    final programs = <ProgramLink>[];
    for (final (i, p) in ((j['linkedSocialPrograms'] as List?) ?? []).indexed) {
      final m = p as Map<String, dynamic>;

      final LookupId programId;
      switch (LookupId.create(m['programId'])) {
        case Success(:final value): programId = value;
        case Failure(:final error):
          return Failure('intakeInfo.linkedSocialPrograms[$i].programId: $error');
      }

      programs.add(ProgramLink(
        programId: programId,
        observation: m['observation'],
      ));
    }

    return IngressInfo.create(
      ingressTypeId: ingressTypeId,
      originName: j['originName'],
      originContact: j['originContact'],
      serviceReason: j['serviceReason'],
      linkedSocialPrograms: programs,
    );
  }
}
