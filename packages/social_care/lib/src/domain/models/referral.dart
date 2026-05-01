import 'package:core/core.dart';

/// A referral of a patient to an external service.
class Referral with Equatable {
  const Referral({
    required this.referralId,
    required this.date,
    required this.referredPersonId,
    required this.destinationService,
    required this.reason,
    required this.status,
    this.professionalId,
  });

  final String referralId;
  final String date;
  final String referredPersonId;
  final String destinationService;
  final String reason;
  final String status;
  final String? professionalId;

  Referral copyWith({
    String? referralId,
    String? date,
    String? referredPersonId,
    String? destinationService,
    String? reason,
    String? status,
    String? professionalId,
  }) {
    return Referral(
      referralId: referralId ?? this.referralId,
      date: date ?? this.date,
      referredPersonId: referredPersonId ?? this.referredPersonId,
      destinationService: destinationService ?? this.destinationService,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      professionalId: professionalId ?? this.professionalId,
    );
  }

  @override
  List<Object?> get props => [
    referralId,
    date,
    referredPersonId,
    destinationService,
    reason,
    status,
    professionalId,
  ];
}
