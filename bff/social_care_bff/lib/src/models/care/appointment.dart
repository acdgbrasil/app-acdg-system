/// A social care appointment.
final class Appointment {
  const Appointment({
    required this.id,
    required this.professionalId,
    this.date,
    this.type,
    this.summary,
    this.actionPlan,
  });

  final String id;
  final String professionalId;
  final DateTime? date;
  final String? type;
  final String? summary;
  final String? actionPlan;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Appointment && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Appointment(id: $id)';
}
