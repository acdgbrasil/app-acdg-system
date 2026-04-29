import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'add_family_member_request.g.dart';

@JsonSerializable()
class AddFamilyMemberRequest with Equatable {
  const AddFamilyMemberRequest({
    required this.memberPersonId,
    required this.relationship,
    required this.isResiding,
    required this.isCaregiver,
    required this.hasDisability,
    required this.birthDate,
    required this.prRelationshipId,
    this.requiredDocuments = const [],
  });

  factory AddFamilyMemberRequest.fromJson(Map<String, dynamic> json) =>
      _$AddFamilyMemberRequestFromJson(json);

  final String memberPersonId;
  final String relationship;
  final bool isResiding;
  final bool isCaregiver;
  final bool hasDisability;
  final List<String> requiredDocuments;
  final String birthDate;
  final String prRelationshipId;

  Map<String, dynamic> toJson() => _$AddFamilyMemberRequestToJson(this);

  @override
  List<Object?> get props => [
    memberPersonId,
    relationship,
    isResiding,
    isCaregiver,
    hasDisability,
    requiredDocuments,
    birthDate,
    prRelationshipId,
  ];
}
