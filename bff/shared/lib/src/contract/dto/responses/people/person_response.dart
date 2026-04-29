import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'person_response.g.dart';

@JsonSerializable()
class PersonResponse with Equatable {
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

  @override
  List<Object?> get props => [id, fullName, birthDate, cpf];
}
