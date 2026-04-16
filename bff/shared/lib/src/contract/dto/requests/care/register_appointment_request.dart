import 'package:json_annotation/json_annotation.dart';

part 'register_appointment_request.g.dart';

@JsonSerializable()
class RegisterAppointmentRequest {
  const RegisterAppointmentRequest({
    required this.professionalId,
    this.summary,
    this.actionPlan,
    this.date,
    this.type,
  });

  factory RegisterAppointmentRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterAppointmentRequestFromJson(json);

  final String professionalId;
  final String? summary;
  final String? actionPlan;
  final String? date;
  final String? type;

  Map<String, dynamic> toJson() => _$RegisterAppointmentRequestToJson(this);
}
