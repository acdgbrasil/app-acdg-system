import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'health_status_response.g.dart';

@JsonSerializable()
class HealthStatusResponse with Equatable {
  const HealthStatusResponse({
    required this.foodInsecurity,
    this.deficiencies = const [],
    this.gestatingMembers = const [],
    this.constantCareNeeds = const [],
  });

  factory HealthStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthStatusResponseFromJson(json);

  final bool foodInsecurity;
  final List<MemberDeficiencyResponse> deficiencies;
  final List<PregnantMemberResponse> gestatingMembers;
  final List<String> constantCareNeeds;

  Map<String, dynamic> toJson() => _$HealthStatusResponseToJson(this);

  @override
  List<Object?> get props => [
    foodInsecurity,
    deficiencies,
    gestatingMembers,
    constantCareNeeds,
  ];
}

@JsonSerializable()
class MemberDeficiencyResponse with Equatable {
  const MemberDeficiencyResponse({
    required this.memberId,
    required this.deficiencyTypeId,
    required this.needsConstantCare,
    this.responsibleCaregiverName,
  });

  factory MemberDeficiencyResponse.fromJson(Map<String, dynamic> json) =>
      _$MemberDeficiencyResponseFromJson(json);

  final String memberId;
  final String deficiencyTypeId;
  final bool needsConstantCare;
  final String? responsibleCaregiverName;

  Map<String, dynamic> toJson() => _$MemberDeficiencyResponseToJson(this);

  @override
  List<Object?> get props => [
    memberId,
    deficiencyTypeId,
    needsConstantCare,
    responsibleCaregiverName,
  ];
}

@JsonSerializable()
class PregnantMemberResponse with Equatable {
  const PregnantMemberResponse({
    required this.memberId,
    required this.monthsGestation,
    required this.startedPrenatalCare,
  });

  factory PregnantMemberResponse.fromJson(Map<String, dynamic> json) =>
      _$PregnantMemberResponseFromJson(json);

  final String memberId;
  final int monthsGestation;
  final bool startedPrenatalCare;

  Map<String, dynamic> toJson() => _$PregnantMemberResponseToJson(this);

  @override
  List<Object?> get props => [
    memberId,
    monthsGestation,
    startedPrenatalCare,
  ];
}
