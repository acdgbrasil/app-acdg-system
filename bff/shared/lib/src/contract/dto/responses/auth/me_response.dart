import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'me_response.g.dart';

@JsonSerializable()
class MeResponse with Equatable {
  const MeResponse({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.roles,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) =>
      _$MeResponseFromJson(json);

  final String userId;
  final String email;
  final String? fullName;
  final List<String> roles;

  Map<String, dynamic> toJson() => _$MeResponseToJson(this);

  @override
  List<Object?> get props => [userId, email, fullName, roles];
}
