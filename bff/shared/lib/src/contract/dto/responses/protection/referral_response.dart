import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'referral_response.g.dart';

@JsonSerializable()
class ReferralResponse with Equatable {
  const ReferralResponse({
    required this.id,
    required this.date,
    required this.referredPersonId,
    required this.destinationService,
    required this.reason,
    required this.status,
    this.professionalId,
  });

  factory ReferralResponse.fromJson(Map<String, dynamic> json) =>
      _$ReferralResponseFromJson(json);

  final String id;
  final String date;
  final String? professionalId;
  final String referredPersonId;
  final String destinationService;
  final String reason;
  final String status;

  Map<String, dynamic> toJson() => _$ReferralResponseToJson(this);

  @override
  List<Object?> get props => [
    id,
    date,
    professionalId,
    referredPersonId,
    destinationService,
    reason,
    status,
  ];
}
