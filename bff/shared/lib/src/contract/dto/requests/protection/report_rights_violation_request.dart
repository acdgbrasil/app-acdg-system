import 'package:json_annotation/json_annotation.dart';

part 'report_rights_violation_request.g.dart';

@JsonSerializable()
class ReportRightsViolationRequest {
  const ReportRightsViolationRequest({
    required this.victimId,
    required this.violationType,
    required this.descriptionOfFact,
    this.violationTypeId,
    this.reportDate,
    this.incidentDate,
    this.actionsTaken,
  });

  factory ReportRightsViolationRequest.fromJson(Map<String, dynamic> json) =>
      _$ReportRightsViolationRequestFromJson(json);

  final String victimId;
  final String violationType;
  final String? violationTypeId;
  final String? reportDate;
  final String? incidentDate;
  final String descriptionOfFact;
  final String? actionsTaken;

  Map<String, dynamic> toJson() => _$ReportRightsViolationRequestToJson(this);
}
