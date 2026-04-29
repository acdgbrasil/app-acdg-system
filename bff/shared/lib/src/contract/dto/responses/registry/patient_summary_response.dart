import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'patient_summary_response.g.dart';

@JsonSerializable()
class PatientSummaryResponse with Equatable {
  const PatientSummaryResponse({
    required this.patientId,
    required this.personId,
    this.firstName,
    this.lastName,
    this.fullName,
    this.primaryDiagnosis,
    this.memberCount = 0,
    this.status = 'admitted',
  });

  factory PatientSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$PatientSummaryResponseFromJson(json);

  final String patientId;
  final String personId;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? primaryDiagnosis;
  final int memberCount;
  final String status;

  Map<String, dynamic> toJson() => _$PatientSummaryResponseToJson(this);

  @override
  List<Object?> get props => [
    patientId,
    personId,
    firstName,
    lastName,
    fullName,
    primaryDiagnosis,
    memberCount,
    status,
  ];
}
