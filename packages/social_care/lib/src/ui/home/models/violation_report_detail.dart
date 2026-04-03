final class ViolationReportDetail {
  final String id;
  final String reportDate;
  final String? incidentDate;
  final String victimId;
  final String violationType;
  final String? violationTypeId;
  final String descriptionOfFact;
  final String actionsTaken;

  const ViolationReportDetail({
    required this.id,
    required this.reportDate,
    this.incidentDate,
    required this.victimId,
    required this.violationType,
    this.violationTypeId,
    required this.descriptionOfFact,
    required this.actionsTaken,
  });

  factory ViolationReportDetail.fromJson(Map<String, dynamic> json) {
    return ViolationReportDetail(
      id: json['id'] as String? ?? '',
      reportDate: json['reportDate'] as String? ?? '',
      incidentDate: json['incidentDate'] as String?,
      victimId: json['victimId'] as String? ?? '',
      violationType: json['violationType'] as String? ?? '',
      violationTypeId: json['violationTypeId'] as String?,
      descriptionOfFact: json['descriptionOfFact'] as String? ?? '',
      actionsTaken: json['actionsTaken'] as String? ?? '',
    );
  }

  /// Raw JSON access -- provides untyped access to all fields.
  Map<String, dynamic> get json => {
        'id': id,
        'reportDate': reportDate,
        'incidentDate': incidentDate,
        'victimId': victimId,
        'violationType': violationType,
        'violationTypeId': violationTypeId,
        'descriptionOfFact': descriptionOfFact,
        'actionsTaken': actionsTaken,
      };
}
