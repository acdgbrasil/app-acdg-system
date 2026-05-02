import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'register_intake_info_request.g.dart';

@JsonSerializable()
class RegisterIntakeInfoRequest with Equatable {
  const RegisterIntakeInfoRequest({
    required this.ingressTypeId,
    required this.serviceReason,
    this.originName,
    this.originContact,
    this.linkedSocialPrograms = const [],
  });

  factory RegisterIntakeInfoRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterIntakeInfoRequestFromJson(json);

  final String ingressTypeId;
  final String? originName;
  final String? originContact;
  final String serviceReason;
  final List<ProgramLinkDraftDto> linkedSocialPrograms;

  Map<String, dynamic> toJson() => _$RegisterIntakeInfoRequestToJson(this);

  @override
  List<Object?> get props => [
    ingressTypeId,
    originName,
    originContact,
    serviceReason,
    linkedSocialPrograms,
  ];
}

@JsonSerializable()
class ProgramLinkDraftDto with Equatable {
  const ProgramLinkDraftDto({required this.programId, this.observation});

  factory ProgramLinkDraftDto.fromJson(Map<String, dynamic> json) =>
      _$ProgramLinkDraftDtoFromJson(json);

  final String programId;
  final String? observation;

  Map<String, dynamic> toJson() => _$ProgramLinkDraftDtoToJson(this);

  @override
  List<Object?> get props => [programId, observation];
}
