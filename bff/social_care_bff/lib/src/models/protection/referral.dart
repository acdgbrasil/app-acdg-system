/// A referral to another service.
final class Referral {
  const Referral({
    required this.id,
    required this.referredPersonId,
    required this.destinationService,
    required this.reason,
    this.date,
    this.professionalId,
    this.status,
  });

  final String id;
  final String referredPersonId;
  final String destinationService;
  final String reason;
  final DateTime? date;
  final String? professionalId;
  final String? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Referral && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Referral(id: $id)';
}
