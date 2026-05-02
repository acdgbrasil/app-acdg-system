import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'register_person_request.g.dart';

@JsonSerializable()
class RegisterPersonRequest with Equatable {
  const RegisterPersonRequest({
    required this.fullName,
    required this.birthDate,
    this.cpf,
  });

  factory RegisterPersonRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterPersonRequestFromJson(json);

  final String fullName;
  final String birthDate;
  final String? cpf;

  Map<String, dynamic> toJson() => _$RegisterPersonRequestToJson(this);

  @override
  List<Object?> get props => [fullName, birthDate, cpf];
}
