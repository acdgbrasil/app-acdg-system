import 'package:json_annotation/json_annotation.dart';

part 'diagnosis_response.g.dart';

@JsonSerializable()
class DiagnosisResponse {
  const DiagnosisResponse({
    required this.icdCode,
    required this.description,
    required this.date,
  });

  factory DiagnosisResponse.fromJson(Map<String, dynamic> json) =>
      _$DiagnosisResponseFromJson(json);

  final String icdCode;
  final String description;
  final String date;

  Map<String, dynamic> toJson() => _$DiagnosisResponseToJson(this);
}
