import 'package:json_annotation/json_annotation.dart';

part 'family_member_response.g.dart';

@JsonSerializable()
class FamilyMemberResponse {
  const FamilyMemberResponse({
    required this.personId,
    required this.relationshipId,
    required this.birthDate,
    this.isPrimaryCaregiver = false,
    this.residesWithPatient = false,
    this.hasDisability = false,
    this.requiredDocuments = const [],
  });

  factory FamilyMemberResponse.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberResponseFromJson(json);

  final String personId;
  final String relationshipId;
  final bool isPrimaryCaregiver;
  final bool residesWithPatient;
  final bool hasDisability;
  final List<String> requiredDocuments;
  final String birthDate;

  Map<String, dynamic> toJson() => _$FamilyMemberResponseToJson(this);
}
