import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../commands/assessment_intents.dart';

/// Maps [UpdateSocioEconomicIntent] to the [SocioEconomicSituation] domain
/// value object. Dedicated mapper for the SocioEconomic endpoint.
abstract final class SocioEconomicMapper {
  /// Maps [UpdateSocioEconomicIntent] to [SocioEconomicSituation].
  static Result<SocioEconomicSituation> toSocioEconomic(
    UpdateSocioEconomicIntent intent,
  ) {
    final SocialBenefitsCollection benefitsCollection;
    switch (SocialBenefitsCollection.create(intent.socialBenefits)) {
      case Success(:final value):
        benefitsCollection = value;
      case Failure(:final error):
        return Failure(error);
    }

    return SocioEconomicSituation.create(
      totalFamilyIncome: intent.totalFamilyIncome,
      incomePerCapita: intent.incomePerCapita,
      receivesSocialBenefit: intent.receivesSocialBenefit,
      socialBenefits: benefitsCollection,
      mainSourceOfIncome: intent.mainSourceOfIncome,
      hasUnemployed: intent.hasUnemployed,
    );
  }
}
