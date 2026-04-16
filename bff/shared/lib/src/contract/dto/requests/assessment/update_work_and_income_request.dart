import 'package:json_annotation/json_annotation.dart';

import 'update_socio_economic_situation_request.dart';

part 'update_work_and_income_request.g.dart';

@JsonSerializable()
class UpdateWorkAndIncomeRequest {
  const UpdateWorkAndIncomeRequest({
    required this.hasRetiredMembers,
    this.individualIncomes = const [],
    this.socialBenefits = const [],
  });

  factory UpdateWorkAndIncomeRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateWorkAndIncomeRequestFromJson(json);

  final List<IncomeDraftDto> individualIncomes;
  final List<SocialBenefitDraftDto> socialBenefits;
  final bool hasRetiredMembers;

  Map<String, dynamic> toJson() => _$UpdateWorkAndIncomeRequestToJson(this);
}

@JsonSerializable()
class IncomeDraftDto {
  const IncomeDraftDto({
    required this.memberId,
    required this.occupationId,
    required this.hasWorkCard,
    required this.monthlyAmount,
  });

  factory IncomeDraftDto.fromJson(Map<String, dynamic> json) =>
      _$IncomeDraftDtoFromJson(json);

  final String memberId;
  final String occupationId;
  final bool hasWorkCard;
  final double monthlyAmount;

  Map<String, dynamic> toJson() => _$IncomeDraftDtoToJson(this);
}
