import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_social_identity_request.g.dart';

@JsonSerializable()
class UpdateSocialIdentityRequest with Equatable {
  const UpdateSocialIdentityRequest({required this.typeId, this.description});

  factory UpdateSocialIdentityRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSocialIdentityRequestFromJson(json);

  final String typeId;
  final String? description;

  Map<String, dynamic> toJson() => _$UpdateSocialIdentityRequestToJson(this);

  @override
  List<Object?> get props => [typeId, description];
}
