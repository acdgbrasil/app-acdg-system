/// Intake/ingress information for a patient.
final class IntakeInfo {
  const IntakeInfo({
    required this.ingressTypeId,
    required this.serviceReason,
    required this.linkedSocialPrograms,
    this.originName,
    this.originContact,
  });

  final String ingressTypeId;
  final String? originName;
  final String? originContact;
  final String serviceReason;
  final List<ProgramLink> linkedSocialPrograms;
}

/// A linked social program in the intake context.
final class ProgramLink {
  const ProgramLink({required this.programId, this.observation});

  final String programId;
  final String? observation;
}
