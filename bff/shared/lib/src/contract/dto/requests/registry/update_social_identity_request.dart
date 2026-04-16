import 'package:json_annotation/json_annotation.dart';

part 'update_social_identity_request.g.dart';

@JsonSerializable()
class UpdateSocialIdentityRequest {
  const UpdateSocialIdentityRequest({required this.typeId, this.description});

  factory UpdateSocialIdentityRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSocialIdentityRequestFromJson(json);

  final String typeId;
  final String? description;

  Map<String, dynamic> toJson() => _$UpdateSocialIdentityRequestToJson(this);
}
