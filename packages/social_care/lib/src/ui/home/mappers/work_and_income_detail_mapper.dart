import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../models/work_and_income_detail.dart';

/// Maps [WorkAndIncomeDetail] → [UpdateWorkAndIncomeIntent].
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
      final LookupId benefitTypeId;
      switch (LookupId.create(b.benefitTypeId)) {
        case Success(:final value):
          benefitTypeId = value;
        case Failure(:final error):
          return Failure('socialBenefits[$i].benefitTypeId: $error');
      }

      final PersonId beneficiaryId;
      switch (PersonId.create(b.beneficiaryId)) {
        case Success(:final value):
          beneficiaryId = value;
        case Failure(:final error):
          return Failure('socialBenefits[$i].beneficiaryId: $error');
      }

      switch (SocialBenefit.create(
        benefitName: b.benefitName,
        benefitTypeId: benefitTypeId,
        amount: b.amount,
        beneficiaryId: beneficiaryId,
      )) {
        case Success(:final value):
          benefits.add(value);
        case Failure(:final error):
          return Failure('socialBenefits[$i]: $error');
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
