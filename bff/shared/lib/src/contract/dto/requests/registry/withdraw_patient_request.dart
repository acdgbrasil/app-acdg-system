import 'package:json_annotation/json_annotation.dart';

part 'withdraw_patient_request.g.dart';

@JsonSerializable()
class WithdrawPatientRequest {
  const WithdrawPatientRequest({required this.reason, this.notes});

  factory WithdrawPatientRequest.fromJson(Map<String, dynamic> json) =>
      _$WithdrawPatientRequestFromJson(json);

  final String reason;
  final String? notes;

  Map<String, dynamic> toJson() => _$WithdrawPatientRequestToJson(this);
}
