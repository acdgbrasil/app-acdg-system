import 'package:core/core.dart';
import '../kernel/ids.dart';
import '../kernel/time_stamp.dart';

/// Representa um evento de auditoria no histórico do paciente.
final class AuditEvent with Equatable {
  const AuditEvent._({
    required this.id,
    required this.aggregateId,
    required this.eventType,
    this.actorId,
    required this.payload,
    required this.occurredAt,
    required this.recordedAt,
  });

  final String id;
  final String aggregateId;
  final String eventType;
  final String? actorId;
  final Map<String, dynamic> payload;
  final TimeStamp occurredAt;
  final TimeStamp recordedAt;

  @override
  List<Object?> get props => [id];

  /// Reconstitui um evento de auditoria a partir da persistência.
  static AuditEvent reconstitute({
    required String id,
    required String aggregateId,
    required String eventType,
    String? actorId,
    required Map<String, dynamic> payload,
    required TimeStamp occurredAt,
    required TimeStamp recordedAt,
  }) {
    return AuditEvent._(
      id: id,
      aggregateId: aggregateId,
      eventType: eventType,
      actorId: actorId,
      payload: payload,
      occurredAt: occurredAt,
      recordedAt: recordedAt,
    );
  }
}
