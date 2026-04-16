import 'package:json_annotation/json_annotation.dart';

part 'person_response.g.dart';

@JsonSerializable()
class PersonResponse {
  const PersonResponse({
    required this.id,
    required this.fullName,
    this.birthDate,
    this.cpf,
  });

  factory PersonResponse.fromJson(Map<String, dynamic> json) =>
      _$PersonResponseFromJson(json);

  final String id;
  final String fullName;
  final String? birthDate;
  final String? cpf;

  Map<String, dynamic> toJson() => _$PersonResponseToJson(this);
}
