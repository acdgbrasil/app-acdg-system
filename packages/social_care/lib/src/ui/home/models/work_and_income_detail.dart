import 'social_benefit_detail.dart';

final class WorkAndIncomeDetail {
  final bool hasRetiredMembers;
  final List<IndividualIncomeDetail> individualIncomes;
  final List<SocialBenefitDetail> socialBenefits;

  const WorkAndIncomeDetail({
    required this.hasRetiredMembers,
    required this.individualIncomes,
    required this.socialBenefits,
  });

  factory WorkAndIncomeDetail.fromJson(Map<String, dynamic> json) {
    return WorkAndIncomeDetail(
      hasRetiredMembers: json['hasRetiredMembers'] as bool,
      individualIncomes: (json['individualIncomes'] as List)
          .map(
            (e) =>
                IndividualIncomeDetail.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      socialBenefits: (json['socialBenefits'] as List)
          .map((e) => SocialBenefitDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

final class IndividualIncomeDetail {
  final String memberId;
  final String occupationId;
  final bool hasWorkCard;
  final double monthlyAmount;

  const IndividualIncomeDetail({
    required this.memberId,
    required this.occupationId,
    required this.hasWorkCard,
    required this.monthlyAmount,
  });

  factory IndividualIncomeDetail.fromJson(Map<String, dynamic> json) {
    return IndividualIncomeDetail(
      memberId: json['memberId'] as String,
      occupationId: json['occupationId'] as String,
      hasWorkCard: json['hasWorkCard'] as bool,
      monthlyAmount: (json['monthlyAmount'] as num).toDouble(),
    );
  }
}
