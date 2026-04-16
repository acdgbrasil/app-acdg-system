import 'package:json_annotation/json_annotation.dart';

part 'discharge_info_response.g.dart';

@JsonSerializable()
class DischargeInfoResponse {
  const DischargeInfoResponse({
    required this.reason,
    required this.dischargedAt,
    required this.dischargedBy,
    this.notes,
  });

  factory DischargeInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$DischargeInfoResponseFromJson(json);

  final String reason;
  final String? notes;
  final String dischargedAt;
  final String dischargedBy;

  Map<String, dynamic> toJson() => _$DischargeInfoResponseToJson(this);
}
