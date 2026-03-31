import 'social_benefit_detail.dart';

final class SocioeconomicSituationDetail {
  final double totalFamilyIncome;
  final double incomePerCapita;
  final bool receivesSocialBenefit;
  final bool hasUnemployed;
  final String mainSourceOfIncome;
  final List<SocialBenefitDetail> socialBenefits;

  const SocioeconomicSituationDetail({
    required this.totalFamilyIncome,
    required this.incomePerCapita,
    required this.receivesSocialBenefit,
    required this.hasUnemployed,
    required this.mainSourceOfIncome,
    required this.socialBenefits,
  });

  factory SocioeconomicSituationDetail.fromJson(Map<String, dynamic> json) {
    return SocioeconomicSituationDetail(
      totalFamilyIncome: (json['totalFamilyIncome'] as num).toDouble(),
      incomePerCapita: (json['incomePerCapita'] as num).toDouble(),
      receivesSocialBenefit: json['receivesSocialBenefit'] as bool,
      hasUnemployed: json['hasUnemployed'] as bool,
      mainSourceOfIncome: json['mainSourceOfIncome'] as String,
      socialBenefits: (json['socialBenefits'] as List)
          .map((e) => SocialBenefitDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
