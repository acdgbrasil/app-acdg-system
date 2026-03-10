/// Request to register a social care appointment.
final class RegisterAppointmentRequest {
  const RegisterAppointmentRequest({
    required this.professionalId,
    this.summary,
    this.actionPlan,
    this.type,
    this.date,
  });

  final String professionalId;
  final String? summary;
  final String? actionPlan;
  final String? type;
  final DateTime? date;

  Map<String, dynamic> toJson() => {
    'professionalId': professionalId,
    if (summary != null) 'summary': summary,
    if (actionPlan != null) 'actionPlan': actionPlan,
    if (type != null) 'type': type,
    if (date != null) 'date': date!.toIso8601String(),
  };
}

/// Request to register intake/ingress information.
final class RegisterIntakeInfoRequest {
  const RegisterIntakeInfoRequest({
    required this.ingressTypeId,
    required this.serviceReason,
    required this.linkedSocialPrograms,
    this.originName,
    this.originContact,
  });

  final String ingressTypeId;
  final String serviceReason;
  final List<ProgramLinkDto> linkedSocialPrograms;
  final String? originName;
  final String? originContact;

  Map<String, dynamic> toJson() => {
    'ingressTypeId': ingressTypeId,
    'serviceReason': serviceReason,
    'linkedSocialPrograms': linkedSocialPrograms
        .map((p) => p.toJson())
        .toList(),
    if (originName != null) 'originName': originName,
    if (originContact != null) 'originContact': originContact,
  };
}

final class ProgramLinkDto {
  const ProgramLinkDto({required this.programId, this.observation});

  final String programId;
  final String? observation;

  Map<String, dynamic> toJson() => {
    'programId': programId,
    if (observation != null) 'observation': observation,
  };
}
