import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../ui/home/models/social_benefit_detail.dart';

/// Shared helper that converts a [SocialBenefitDetail] (from the home
/// aggregate) into a domain [SocialBenefit] value object. Reused by
/// `SocioEconomicDetailMapper` and `WorkAndIncomeDetailMapper`.
abstract final class SocialBenefitDetailMapper {
  static Result<SocialBenefit> toDomain(
    SocialBenefitDetail detail, {
    required String contextLabel,
    required int index,
  }) {
    final LookupId benefitTypeId;
    switch (LookupId.create(detail.benefitTypeId)) {
      case Success(:final value):
        benefitTypeId = value;
      case Failure(:final error):
        return Failure('$contextLabel[$index].benefitTypeId: $error');
    }

    final PersonId beneficiaryId;
    switch (PersonId.create(detail.beneficiaryId)) {
      case Success(:final value):
        beneficiaryId = value;
      case Failure(:final error):
        return Failure('$contextLabel[$index].beneficiaryId: $error');
    }

    switch (SocialBenefit.create(
      benefitName: detail.benefitName,
      benefitTypeId: benefitTypeId,
      amount: detail.amount,
      beneficiaryId: beneficiaryId,
    )) {
      case Success(:final value):
        return Success(value);
      case Failure(:final error):
        return Failure('$contextLabel[$index]: $error');
    }
  }
}
