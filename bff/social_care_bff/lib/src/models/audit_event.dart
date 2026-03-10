/// An entry in the patient audit trail.
final class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.aggregateId,
    required this.eventType,
    required this.payload,
    required this.occurredAt,
    required this.recordedAt,
    this.actorId,
  });

  final String id;
  final String aggregateId;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final String? actorId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuditEvent && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AuditEvent(id: $id, type: $eventType)';
}
