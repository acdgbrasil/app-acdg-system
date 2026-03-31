/// API model for patient summary returned by the list endpoint.
///
/// Handles JSON deserialization only — no business logic.
final class PatientSummaryApiModel {
  final String patientId;
  final String personId;
  final String firstName;
  final String lastName;
  final String? fullName;
  final String? primaryDiagnosis;
  final int memberCount;

  const PatientSummaryApiModel({
    required this.patientId,
    required this.personId,
    required this.firstName,
    required this.lastName,
    this.fullName,
    this.primaryDiagnosis,
    required this.memberCount,
  });

  factory PatientSummaryApiModel.fromJson(Map<String, dynamic> json) {
    return PatientSummaryApiModel(
      patientId: json['patientId'] as String,
      personId: json['personId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '—',
      lastName: json['lastName'] as String? ?? '—',
      fullName: json['fullName'] as String?,
      primaryDiagnosis: json['primaryDiagnosis'] as String?,
      memberCount: json['memberCount'] as int? ?? 0,
    );
  }
}
