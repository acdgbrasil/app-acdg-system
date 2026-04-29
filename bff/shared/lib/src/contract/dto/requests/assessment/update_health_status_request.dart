import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_health_status_request.g.dart';

@JsonSerializable()
class UpdateHealthStatusRequest with Equatable {
  const UpdateHealthStatusRequest({
    required this.foodInsecurity,
    this.deficiencies = const [],
    this.gestatingMembers = const [],
    this.constantCareNeeds = const [],
  });

  factory UpdateHealthStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateHealthStatusRequestFromJson(json);

  final List<DeficiencyDraftDto> deficiencies;
  final List<PregnantDraftDto> gestatingMembers;
  final List<String> constantCareNeeds;
  final bool foodInsecurity;

  Map<String, dynamic> toJson() => _$UpdateHealthStatusRequestToJson(this);

  @override
  List<Object?> get props => [
    deficiencies,
    gestatingMembers,
    constantCareNeeds,
    foodInsecurity,
  ];
}

@JsonSerializable()
class DeficiencyDraftDto with Equatable {
  const DeficiencyDraftDto({
    required this.memberId,
    required this.deficiencyTypeId,
    required this.needsConstantCare,
    this.responsibleCaregiverName,
  });

  factory DeficiencyDraftDto.fromJson(Map<String, dynamic> json) =>
      _$DeficiencyDraftDtoFromJson(json);

  final String memberId;
  final String deficiencyTypeId;
  final bool needsConstantCare;
  final String? responsibleCaregiverName;

  Map<String, dynamic> toJson() => _$DeficiencyDraftDtoToJson(this);

  @override
  List<Object?> get props => [
    memberId,
    deficiencyTypeId,
    needsConstantCare,
    responsibleCaregiverName,
  ];
}

@JsonSerializable()
class PregnantDraftDto with Equatable {
  const PregnantDraftDto({
    required this.memberId,
    required this.monthsGestation,
    required this.startedPrenatalCare,
  });

  factory PregnantDraftDto.fromJson(Map<String, dynamic> json) =>
      _$PregnantDraftDtoFromJson(json);

  final String memberId;
  final int monthsGestation;
  final bool startedPrenatalCare;

  Map<String, dynamic> toJson() => _$PregnantDraftDtoToJson(this);

  @override
  List<Object?> get props => [
    memberId,
    monthsGestation,
    startedPrenatalCare,
  ];
}
