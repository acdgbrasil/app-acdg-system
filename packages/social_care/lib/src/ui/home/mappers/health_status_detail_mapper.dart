import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../models/health_status_detail.dart';

/// Maps [HealthStatusDetail] → [UpdateHealthStatusIntent].
abstract final class HealthStatusDetailMapper {
  static Result<UpdateHealthStatusIntent> toIntent(
    HealthStatusDetail detail, {
    required PatientId patientId,
  }) {
    final deficiencies = <MemberDeficiency>[];
    for (final (i, d) in detail.deficiencies.indexed) {
      final PersonId memberId;
      switch (PersonId.create(d.memberId)) {
        case Success(:final value): memberId = value;
        case Failure(:final error):
          return Failure('deficiencies[$i].memberId: $error');
      }

      final LookupId deficiencyTypeId;
      switch (LookupId.create(d.deficiencyTypeId)) {
        case Success(:final value): deficiencyTypeId = value;
        case Failure(:final error):
          return Failure('deficiencies[$i].deficiencyTypeId: $error');
      }

      deficiencies.add(MemberDeficiency(
        memberId: memberId,
        deficiencyTypeId: deficiencyTypeId,
        needsConstantCare: d.needsConstantCare,
        responsibleCaregiverName: d.responsibleCaregiverName,
      ));
    }

    final gestating = <PregnantMember>[];
    for (final (i, g) in detail.gestatingMembers.indexed) {
      final PersonId memberId;
      switch (PersonId.create(g.memberId)) {
        case Success(:final value): memberId = value;
        case Failure(:final error):
          return Failure('gestatingMembers[$i].memberId: $error');
      }

      gestating.add(PregnantMember(
        memberId: memberId,
        monthsGestation: g.monthsGestation,
        startedPrenatalCare: g.startedPrenatalCare,
      ));
    }

    final careNeeds = <PersonId>[];
    for (final (i, id) in detail.constantCareNeeds.indexed) {
      switch (PersonId.create(id)) {
        case Success(:final value): careNeeds.add(value);
        case Failure(:final error):
          return Failure('constantCareNeeds[$i]: $error');
      }
    }

    return Success(UpdateHealthStatusIntent(
      patientId: patientId,
      foodInsecurity: detail.foodInsecurity,
      deficiencies: deficiencies,
      gestatingMembers: gestating,
      constantCareNeeds: careNeeds,
    ));
  }
}
