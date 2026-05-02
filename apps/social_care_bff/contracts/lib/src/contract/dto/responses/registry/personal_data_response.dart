import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'personal_data_response.g.dart';

@JsonSerializable()
class PersonalDataResponse with Equatable {
  const PersonalDataResponse({
    required this.firstName,
    required this.lastName,
    required this.motherName,
    required this.nationality,
    required this.sex,
    required this.birthDate,
    this.socialName,
    this.phone,
  });

  factory PersonalDataResponse.fromJson(Map<String, dynamic> json) =>
      _$PersonalDataResponseFromJson(json);

  final String firstName;
  final String lastName;
  final String motherName;
  final String nationality;
  final String sex;
  final String birthDate;
  final String? socialName;
  final String? phone;

  Map<String, dynamic> toJson() => _$PersonalDataResponseToJson(this);

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    motherName,
    nationality,
    sex,
    birthDate,
    socialName,
    phone,
  ];
}
