import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'readmit_patient_request.g.dart';

@JsonSerializable()
class ReadmitPatientRequest with Equatable {
  const ReadmitPatientRequest({this.notes});

  factory ReadmitPatientRequest.fromJson(Map<String, dynamic> json) =>
      _$ReadmitPatientRequestFromJson(json);

  final String? notes;

  Map<String, dynamic> toJson() => _$ReadmitPatientRequestToJson(this);

  @override
  List<Object?> get props => [notes];
}
