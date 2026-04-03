import 'package:json_annotation/json_annotation.dart';

part 'patient_overview.g.dart';

/// Lightweight remote model for patient listing responses.
///
/// Contains only the fields needed for the home screen list view.
/// Full patient details are fetched on demand via [PatientRemote].
@JsonSerializable()
class PatientOverview {
  const PatientOverview({
    required this.patientId,
    required this.personId,
    this.firstName,
    this.lastName,
    this.fullName,
    this.primaryDiagnosis,
    this.memberCount = 0,
  });

  factory PatientOverview.fromJson(Map<String, dynamic> json) =>
      _$PatientOverviewFromJson(json);

  final String patientId;
  final String personId;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? primaryDiagnosis;
  final int memberCount;

  Map<String, dynamic> toJson() => _$PatientOverviewToJson(this);
}
