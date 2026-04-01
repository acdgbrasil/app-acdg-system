import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/intervention_intents.dart';
import '../models/intake_info_detail.dart';

/// Maps [IntakeInfoDetail] → [UpdateIntakeInfoIntent].
abstract final class IntakeInfoDetailMapper {
  static Result<UpdateIntakeInfoIntent> toIntent(
    IntakeInfoDetail detail, {
    required PatientId patientId,
  }) {
    final LookupId ingressTypeId;
    switch (LookupId.create(detail.ingressTypeId)) {
      case Success(:final value): ingressTypeId = value;
      case Failure(:final error):
        return Failure('intakeInfo.ingressTypeId: $error');
    }

    final programs = <ProgramLink>[];
    for (final (i, p) in detail.linkedSocialPrograms.indexed) {
      final LookupId programId;
      switch (LookupId.create(p.programId)) {
        case Success(:final value): programId = value;
        case Failure(:final error):
          return Failure('linkedSocialPrograms[$i].programId: $error');
      }

      programs.add(ProgramLink(
        programId: programId,
        observation: p.observation,
      ));
    }

    final IngressInfo info;
    switch (IngressInfo.create(
      ingressTypeId: ingressTypeId,
      originName: detail.originName,
      originContact: detail.originContact,
      serviceReason: detail.serviceReason,
      linkedSocialPrograms: programs,
    )) {
      case Success(:final value): info = value;
      case Failure(:final error):
        return Failure('intakeInfo: $error');
    }

    return Success(UpdateIntakeInfoIntent(
      patientId: patientId,
      info: info,
    ));
  }
}
