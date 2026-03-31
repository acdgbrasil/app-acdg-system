import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../models/work_and_income_detail.dart';

/// Maps [WorkAndIncomeDetail] → [UpdateWorkAndIncomeIntent].
abstract final class WorkAndIncomeDetailMapper {
  static UpdateWorkAndIncomeIntent toIntent(
    WorkAndIncomeDetail detail, {
    required PatientId patientId,
  }) {
    return UpdateWorkAndIncomeIntent(
      patientId: patientId,
      hasRetiredMembers: detail.hasRetiredMembers,
      individualIncomes: detail.individualIncomes
          .map(
            (i) => WorkIncomeVO.create(
              memberId: PersonId.create(i.memberId).valueOrNull!,
              occupationId: LookupId.create(i.occupationId).valueOrNull!,
              hasWorkCard: i.hasWorkCard,
              monthlyAmount: i.monthlyAmount,
            ),
          )
          .whereType<Success<WorkIncomeVO>>()
          .map((r) => r.value)
          .toList(),
      socialBenefits: detail.socialBenefits
          .map(
            (b) => SocialBenefit.create(
              benefitName: b.benefitName,
              amount: b.amount,
              beneficiaryId: PersonId.create(b.beneficiaryId).valueOrNull!,
            ),
          )
          .whereType<Success<SocialBenefit>>()
          .map((r) => r.value)
          .toList(),
    );
  }
}
