import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../ui/home/models/work_and_income_detail.dart';
import '../commands/assessment_intents.dart';
import 'shared/social_benefit_detail_mapper.dart';

/// Maps [WorkAndIncomeDetail] (parsed patient aggregate) to
/// [UpdateWorkAndIncomeIntent] — used to pre-fill the edit form.
abstract final class WorkAndIncomeDetailMapper {
  static Result<UpdateWorkAndIncomeIntent> toIntent(
    WorkAndIncomeDetail detail, {
    required PatientId patientId,
  }) {
    final incomes = <WorkIncomeVO>[];
    for (final (i, item) in detail.individualIncomes.indexed) {
      final PersonId memberId;
      switch (PersonId.create(item.memberId)) {
        case Success(:final value):
          memberId = value;
        case Failure(:final error):
          return Failure('individualIncomes[$i].memberId: $error');
      }

      final LookupId occupationId;
      switch (LookupId.create(item.occupationId)) {
        case Success(:final value):
          occupationId = value;
        case Failure(:final error):
          return Failure('individualIncomes[$i].occupationId: $error');
      }

      switch (WorkIncomeVO.create(
        memberId: memberId,
        occupationId: occupationId,
        hasWorkCard: item.hasWorkCard,
        monthlyAmount: item.monthlyAmount,
      )) {
        case Success(:final value):
          incomes.add(value);
        case Failure(:final error):
          return Failure('individualIncomes[$i]: $error');
      }
    }

    final benefits = <SocialBenefit>[];
    for (final (i, b) in detail.socialBenefits.indexed) {
      switch (SocialBenefitDetailMapper.toDomain(
        b,
        contextLabel: 'socialBenefits',
        index: i,
      )) {
        case Success(:final value):
          benefits.add(value);
        case Failure(:final error):
          return Failure(error);
      }
    }

    return Success(
      UpdateWorkAndIncomeIntent(
        patientId: patientId,
        hasRetiredMembers: detail.hasRetiredMembers,
        individualIncomes: incomes,
        socialBenefits: benefits,
      ),
    );
  }
}
