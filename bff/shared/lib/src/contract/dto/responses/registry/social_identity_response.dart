import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_identity_response.g.dart';

@JsonSerializable()
class SocialIdentityResponse with Equatable {
  const SocialIdentityResponse({required this.typeId, this.otherDescription});

  factory SocialIdentityResponse.fromJson(Map<String, dynamic> json) =>
      _$SocialIdentityResponseFromJson(json);

  final String typeId;
  final String? otherDescription;

  Map<String, dynamic> toJson() => _$SocialIdentityResponseToJson(this);

  @override
  List<Object?> get props => [typeId, otherDescription];
}
