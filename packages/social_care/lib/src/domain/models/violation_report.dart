import 'package:core/core.dart';

/// A rights violation report filed against a patient's situation.
class ViolationReport with Equatable {
  const ViolationReport({
    required this.reportId,
    required this.reportDate,
    required this.victimId,
    required this.violationType,
    required this.descriptionOfFact,
    required this.actionsTaken,
    this.incidentDate,
  });

  final String reportId;
  final String reportDate;
  final String victimId;
  final String violationType;
  final String descriptionOfFact;
  final String actionsTaken;
  final String? incidentDate;

  ViolationReport copyWith({
    String? reportId,
    String? reportDate,
    String? victimId,
    String? violationType,
    String? descriptionOfFact,
    String? actionsTaken,
    String? incidentDate,
  }) {
    return ViolationReport(
      reportId: reportId ?? this.reportId,
      reportDate: reportDate ?? this.reportDate,
      victimId: victimId ?? this.victimId,
      violationType: violationType ?? this.violationType,
      descriptionOfFact: descriptionOfFact ?? this.descriptionOfFact,
      actionsTaken: actionsTaken ?? this.actionsTaken,
      incidentDate: incidentDate ?? this.incidentDate,
    );
  }

  @override
  List<Object?> get props => [
    reportId,
    reportDate,
    victimId,
    violationType,
    descriptionOfFact,
    actionsTaken,
    incidentDate,
  ];
}
