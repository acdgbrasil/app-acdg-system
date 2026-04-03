final class ReferralDetail {
  final String id;
  final String date;
  final String professionalId;
  final String referredPersonId;
  final String destinationService;
  final String reason;
  final String status;

  const ReferralDetail({
    required this.id,
    required this.date,
    required this.professionalId,
    required this.referredPersonId,
    required this.destinationService,
    required this.reason,
    required this.status,
  });

  factory ReferralDetail.fromJson(Map<String, dynamic> json) {
    return ReferralDetail(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      professionalId: json['professionalId'] as String? ?? '',
      referredPersonId: json['referredPersonId'] as String? ?? '',
      destinationService: json['destinationService'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  /// Raw JSON access -- provides untyped access to all fields.
  Map<String, dynamic> get json => {
        'id': id,
        'date': date,
        'professionalId': professionalId,
        'referredPersonId': referredPersonId,
        'destinationService': destinationService,
        'reason': reason,
        'status': status,
      };
}
