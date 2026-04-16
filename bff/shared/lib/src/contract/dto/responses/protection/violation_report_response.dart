import 'package:json_annotation/json_annotation.dart';

part 'violation_report_response.g.dart';

@JsonSerializable()
class ViolationReportResponse {
  const ViolationReportResponse({
    required this.id,
    required this.reportDate,
    required this.victimId,
    required this.violationType,
    required this.descriptionOfFact,
    required this.actionsTaken,
    this.incidentDate,
  });

  factory ViolationReportResponse.fromJson(Map<String, dynamic> json) =>
      _$ViolationReportResponseFromJson(json);

  final String id;
  final String reportDate;
  final String? incidentDate;
  final String victimId;
  final String violationType;
  final String descriptionOfFact;
  final String actionsTaken;

  Map<String, dynamic> toJson() => _$ViolationReportResponseToJson(this);
}
