import 'package:json_annotation/json_annotation.dart';

part 'readmit_patient_request.g.dart';

@JsonSerializable()
class ReadmitPatientRequest {
  const ReadmitPatientRequest({this.notes});

  factory ReadmitPatientRequest.fromJson(Map<String, dynamic> json) =>
      _$ReadmitPatientRequestFromJson(json);

  final String? notes;

  Map<String, dynamic> toJson() => _$ReadmitPatientRequestToJson(this);
}
