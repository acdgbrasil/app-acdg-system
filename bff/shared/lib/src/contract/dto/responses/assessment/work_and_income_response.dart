import 'package:json_annotation/json_annotation.dart';

import 'social_benefit_response.dart';

part 'work_and_income_response.g.dart';

@JsonSerializable()
class WorkAndIncomeResponse {
  const WorkAndIncomeResponse({
    required this.hasRetiredMembers,
    this.individualIncomes = const [],
    this.socialBenefits = const [],
  });

  factory WorkAndIncomeResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkAndIncomeResponseFromJson(json);

  final bool hasRetiredMembers;
  final List<WorkIncomeResponse> individualIncomes;
  final List<SocialBenefitResponse> socialBenefits;

  Map<String, dynamic> toJson() => _$WorkAndIncomeResponseToJson(this);
}

@JsonSerializable()
class WorkIncomeResponse {
  const WorkIncomeResponse({
    required this.memberId,
    required this.occupationId,
    required this.hasWorkCard,
    required this.monthlyAmount,
  });

  factory WorkIncomeResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkIncomeResponseFromJson(json);

  final String memberId;
  final String occupationId;
  final bool hasWorkCard;
  final double monthlyAmount;

  Map<String, dynamic> toJson() => _$WorkIncomeResponseToJson(this);
}
