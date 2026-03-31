import 'package:shared/shared.dart';

/// Lightweight model for the family list.
final class PatientSummary {
  final String patientId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? primaryDiagnosis;
  final int memberCount;

  const PatientSummary({
    required this.patientId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.primaryDiagnosis,
    required this.memberCount,
  });

  /// Maps a server JSON summary to a [PatientSummary].
  factory PatientSummary.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName'] as String? ?? '—';
    final lastName = json['lastName'] as String? ?? '—';
    return PatientSummary(
      patientId: json['patientId'] as String,
      firstName: firstName,
      lastName: lastName,
      fullName: json['fullName'] as String? ?? '$firstName $lastName',
      primaryDiagnosis: json['primaryDiagnosis'] as String?,
      memberCount: json['memberCount'] as int? ?? 0,
    );
  }

  /// Maps a domain [Patient] to a [PatientSummary].
  factory PatientSummary.fromPatient(Patient patient) {
    final pd = patient.personalData;
    final firstName = pd?.firstName ?? '—';
    final lastName = pd?.lastName ?? '—';
    final diagnosis = patient.diagnoses.isNotEmpty
        ? patient.diagnoses.first.description
        : null;

    return PatientSummary(
      patientId: patient.id.value,
      firstName: firstName,
      lastName: lastName,
      fullName: '$firstName $lastName',
      primaryDiagnosis: diagnosis,
      memberCount: patient.familyMembers.length,
    );
  }

  /// Converts to JSON for local storage.
  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'firstName': firstName,
    'lastName': lastName,
    'fullName': fullName,
    'primaryDiagnosis': primaryDiagnosis,
    'memberCount': memberCount,
  };
}
