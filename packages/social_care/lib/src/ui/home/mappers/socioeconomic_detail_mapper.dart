import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../models/socioeconomic_situation_detail.dart';

/// Maps [SocioeconomicSituationDetail] → [UpdateSocioEconomicIntent].
abstract final class SocioeconomicDetailMapper {
  static Result<UpdateSocioEconomicIntent> toIntent(
    SocioeconomicSituationDetail detail, {
    required PatientId patientId,
  }) {
    final benefits = <SocialBenefit>[];
    for (final (i, b) in detail.socialBenefits.indexed) {
      final LookupId benefitTypeId;
      switch (LookupId.create(b.benefitTypeId)) {
        case Success(:final value): benefitTypeId = value;
        case Failure(:final error):
          return Failure('socialBenefits[$i].benefitTypeId: $error');
      }

      final PersonId beneficiaryId;
      switch (PersonId.create(b.beneficiaryId)) {
        case Success(:final value): beneficiaryId = value;
        case Failure(:final error):
          return Failure('socialBenefits[$i].beneficiaryId: $error');
      }

      switch (SocialBenefit.create(
        benefitName: b.benefitName,
        benefitTypeId: benefitTypeId,
        amount: b.amount,
        beneficiaryId: beneficiaryId,
      )) {
        case Success(:final value): benefits.add(value);
        case Failure(:final error):
          return Failure('socialBenefits[$i]: $error');
      }
    }

    return Success(UpdateSocioEconomicIntent(
      patientId: patientId,
      totalFamilyIncome: detail.totalFamilyIncome,
      incomePerCapita: detail.incomePerCapita,
      receivesSocialBenefit: detail.receivesSocialBenefit,
      hasUnemployed: detail.hasUnemployed,
      mainSourceOfIncome: detail.mainSourceOfIncome,
      socialBenefits: benefits,
    ));
  }
}
