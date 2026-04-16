import 'package:json_annotation/json_annotation.dart';

part 'register_person_request.g.dart';

@JsonSerializable()
class RegisterPersonRequest {
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
}
