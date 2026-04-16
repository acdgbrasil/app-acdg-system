import 'package:json_annotation/json_annotation.dart';

part 'create_referral_request.g.dart';

@JsonSerializable()
class CreateReferralRequest {
  const CreateReferralRequest({
    required this.referredPersonId,
    required this.destinationService,
    required this.reason,
    this.professionalId,
    this.date,
  });

  factory CreateReferralRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateReferralRequestFromJson(json);

  final String referredPersonId;
  final String? professionalId;
  final String destinationService;
  final String reason;
  final String? date;

  Map<String, dynamic> toJson() => _$CreateReferralRequestToJson(this);
}
