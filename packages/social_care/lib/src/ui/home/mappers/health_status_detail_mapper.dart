import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../models/health_status_detail.dart';

/// Maps [HealthStatusDetail] → [UpdateHealthStatusIntent].
abstract final class HealthStatusDetailMapper {
  static UpdateHealthStatusIntent toIntent(
    HealthStatusDetail detail, {
    required PatientId patientId,
  }) {
    return UpdateHealthStatusIntent(
      patientId: patientId,
      foodInsecurity: detail.foodInsecurity,
      deficiencies: detail.deficiencies
          .map(
            (d) => MemberDeficiency(
              memberId: PersonId.create(d.memberId).valueOrNull!,
              deficiencyTypeId:
                  LookupId.create(d.deficiencyTypeId).valueOrNull!,
              needsConstantCare: d.needsConstantCare,
              responsibleCaregiverName: d.responsibleCaregiverName,
            ),
          )
          .toList(),
      gestatingMembers: detail.gestatingMembers
          .map(
            (g) => PregnantMember(
              memberId: PersonId.create(g.memberId).valueOrNull!,
              monthsGestation: g.monthsGestation,
              startedPrenatalCare: g.startedPrenatalCare,
            ),
          )
          .toList(),
      constantCareNeeds: detail.constantCareNeeds
          .map((id) => PersonId.create(id).valueOrNull!)
          .toList(),
    );
  }
}
