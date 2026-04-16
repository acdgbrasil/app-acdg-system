import 'package:json_annotation/json_annotation.dart';

part 'discharge_patient_request.g.dart';

@JsonSerializable()
class DischargePatientRequest {
  const DischargePatientRequest({required this.reason, this.notes});

  factory DischargePatientRequest.fromJson(Map<String, dynamic> json) =>
      _$DischargePatientRequestFromJson(json);

  final String reason;
  final String? notes;

  Map<String, dynamic> toJson() => _$DischargePatientRequestToJson(this);
}
