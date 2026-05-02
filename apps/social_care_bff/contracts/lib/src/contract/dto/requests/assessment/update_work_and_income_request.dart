import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

import 'update_socio_economic_situation_request.dart';

part 'update_work_and_income_request.g.dart';

@JsonSerializable()
class UpdateWorkAndIncomeRequest with Equatable {
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

  @override
  List<Object?> get props => [
    individualIncomes,
    socialBenefits,
    hasRetiredMembers,
  ];
}

@JsonSerializable()
class IncomeDraftDto with Equatable {
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

  @override
  List<Object?> get props => [
    memberId,
    occupationId,
    hasWorkCard,
    monthlyAmount,
  ];
}
