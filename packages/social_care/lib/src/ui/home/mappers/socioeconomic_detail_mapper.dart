import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../models/socioeconomic_situation_detail.dart';

/// Maps [SocioeconomicSituationDetail] → [UpdateSocioEconomicIntent].
abstract final class SocioeconomicDetailMapper {
  static UpdateSocioEconomicIntent toIntent(
    SocioeconomicSituationDetail detail, {
    required PatientId patientId,
  }) {
    return UpdateSocioEconomicIntent(
      patientId: patientId,
      totalFamilyIncome: detail.totalFamilyIncome,
      incomePerCapita: detail.incomePerCapita,
      receivesSocialBenefit: detail.receivesSocialBenefit,
      hasUnemployed: detail.hasUnemployed,
      mainSourceOfIncome: detail.mainSourceOfIncome,
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
