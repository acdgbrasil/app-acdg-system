import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'register_person_with_login_request.g.dart';

@JsonSerializable()
class RegisterPersonWithLoginRequest with Equatable {
  const RegisterPersonWithLoginRequest({
    required this.fullName,
    required this.birthDate,
    required this.email,
    this.cpf,
    this.initialPassword,
  });

  factory RegisterPersonWithLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterPersonWithLoginRequestFromJson(json);

  final String fullName;
  final String birthDate;
  final String email;
  final String? cpf;
  final String? initialPassword;

  Map<String, dynamic> toJson() => _$RegisterPersonWithLoginRequestToJson(this);

  @override
  List<Object?> get props => [fullName, birthDate, email, cpf, initialPassword];
}
