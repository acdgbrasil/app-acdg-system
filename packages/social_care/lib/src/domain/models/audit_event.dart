import 'package:core/core.dart';

/// An entry in the audit trail for a given aggregate.
///
/// The payload is kept as a generic map because each event type has its own
/// shape and decoding is the responsibility of consumers (usually the UI
/// rendering a timeline).
class AuditEvent with Equatable {
  const AuditEvent({
    required this.eventId,
    required this.aggregateId,
    required this.eventType,
    required this.occurredAt,
    required this.recordedAt,
    this.actorId,
    this.payload,
  });

  final String eventId;
  final String aggregateId;
  final String eventType;
  final String occurredAt;
  final String recordedAt;
  final String? actorId;
  final Map<String, dynamic>? payload;

  AuditEvent copyWith({
    String? eventId,
    String? aggregateId,
    String? eventType,
    String? occurredAt,
    String? recordedAt,
    String? actorId,
    Map<String, dynamic>? payload,
  }) {
    return AuditEvent(
      eventId: eventId ?? this.eventId,
      aggregateId: aggregateId ?? this.aggregateId,
      eventType: eventType ?? this.eventType,
      occurredAt: occurredAt ?? this.occurredAt,
      recordedAt: recordedAt ?? this.recordedAt,
      actorId: actorId ?? this.actorId,
      payload: payload ?? this.payload,
    );
  }

  @override
  List<Object?> get props => [
    eventId,
    aggregateId,
    eventType,
    occurredAt,
    recordedAt,
    actorId,
    payload,
  ];
}
