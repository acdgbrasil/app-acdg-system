import 'package:json_annotation/json_annotation.dart';

part 'appointment_response.g.dart';

@JsonSerializable()
class AppointmentResponse {
  const AppointmentResponse({
    required this.id,
    required this.date,
    required this.professionalId,
    required this.type,
    required this.summary,
    required this.actionPlan,
  });

  factory AppointmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AppointmentResponseFromJson(json);

  final String id;
  final String date;
  final String professionalId;
  final String type;
  final String summary;
  final String actionPlan;

  Map<String, dynamic> toJson() => _$AppointmentResponseToJson(this);
}
