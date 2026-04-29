import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admit_patient_request.g.dart';

@JsonSerializable()
class AdmitPatientRequest with Equatable {
  const AdmitPatientRequest({
    required this.reason,
    required this.admittedAt,
    this.notes,
  });

  factory AdmitPatientRequest.fromJson(Map<String, dynamic> json) =>
      _$AdmitPatientRequestFromJson(json);

  final String reason;
  final String admittedAt;
  final String? notes;

  Map<String, dynamic> toJson() => _$AdmitPatientRequestToJson(this);

  @override
  List<Object?> get props => [reason, admittedAt, notes];
}
