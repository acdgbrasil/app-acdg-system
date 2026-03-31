import 'package:shared/shared.dart';
import '../../../data/commands/intervention_intents.dart';
import '../models/intake_info_detail.dart';

/// Maps [IntakeInfoDetail] → [UpdateIntakeInfoIntent].
abstract final class IntakeInfoDetailMapper {
  static UpdateIntakeInfoIntent toIntent(
    IntakeInfoDetail detail, {
    required PatientId patientId,
  }) {
    final ingressTypeId = LookupId.create(detail.ingressTypeId).valueOrNull!;

    final linkedPrograms = detail.linkedSocialPrograms
        .map(
          (p) => ProgramLink(
            programId: LookupId.create(p.programId).valueOrNull!,
            observation: p.observation,
          ),
        )
        .toList();

    final infoResult = IngressInfo.create(
      ingressTypeId: ingressTypeId,
      originName: detail.originName,
      originContact: detail.originContact,
      serviceReason: detail.serviceReason,
      linkedSocialPrograms: linkedPrograms,
    );

    return UpdateIntakeInfoIntent(
      patientId: patientId,
      info: infoResult.valueOrNull!,
    );
  }
}
