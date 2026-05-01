import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../ui/home/models/socioeconomic_situation_detail.dart';
import '../commands/assessment_intents.dart';
import 'shared/social_benefit_detail_mapper.dart';

/// Maps [SocioeconomicSituationDetail] (parsed patient aggregate) to
/// [UpdateSocioEconomicIntent] — used to pre-fill the edit form.
abstract final class SocioeconomicDetailMapper {
  static Result<UpdateSocioEconomicIntent> toIntent(
    SocioeconomicSituationDetail detail, {
    required PatientId patientId,
  }) {
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
      UpdateSocioEconomicIntent(
        patientId: patientId,
        totalFamilyIncome: detail.totalFamilyIncome,
        incomePerCapita: detail.incomePerCapita,
        receivesSocialBenefit: detail.receivesSocialBenefit,
        hasUnemployed: detail.hasUnemployed,
        mainSourceOfIncome: detail.mainSourceOfIncome,
        socialBenefits: benefits,
      ),
    );
  }
}
