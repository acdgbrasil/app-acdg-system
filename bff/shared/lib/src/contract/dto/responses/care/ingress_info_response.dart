import 'package:json_annotation/json_annotation.dart';

part 'ingress_info_response.g.dart';

@JsonSerializable()
class IngressInfoResponse {
  const IngressInfoResponse({
    required this.ingressTypeId,
    required this.serviceReason,
    this.originName,
    this.originContact,
    this.linkedSocialPrograms = const [],
  });

  factory IngressInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$IngressInfoResponseFromJson(json);

  final String ingressTypeId;
  final String? originName;
  final String? originContact;
  final String serviceReason;
  final List<ProgramLinkResponse> linkedSocialPrograms;

  Map<String, dynamic> toJson() => _$IngressInfoResponseToJson(this);
}

@JsonSerializable()
class ProgramLinkResponse {
  const ProgramLinkResponse({required this.programId, this.observation});

  factory ProgramLinkResponse.fromJson(Map<String, dynamic> json) =>
      _$ProgramLinkResponseFromJson(json);

  final String programId;
  final String? observation;

  Map<String, dynamic> toJson() => _$ProgramLinkResponseToJson(this);
}
