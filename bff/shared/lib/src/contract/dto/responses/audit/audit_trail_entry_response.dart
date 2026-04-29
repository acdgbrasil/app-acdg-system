import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'audit_trail_entry_response.g.dart';

/// Note: [payload] is a `Map<String, dynamic>?`. Equatable's map equality is
/// structural but does not descend through `dynamic` values, so nested
/// structures inside payload fall back to reference equality. Accepted
/// limitation for this DTO shape.
@JsonSerializable()
class AuditTrailEntryResponse with Equatable {
  const AuditTrailEntryResponse({
    required this.id,
    required this.aggregateId,
    required this.eventType,
    required this.occurredAt,
    required this.recordedAt,
    this.actorId,
    this.payload,
  });

  factory AuditTrailEntryResponse.fromJson(Map<String, dynamic> json) =>
      _$AuditTrailEntryResponseFromJson(json);

  final String id;
  final String aggregateId;
  final String eventType;
  final String? actorId;
  final Map<String, dynamic>? payload;
  final String occurredAt;
  final String recordedAt;

  Map<String, dynamic> toJson() => _$AuditTrailEntryResponseToJson(this);

  @override
  List<Object?> get props => [
    id,
    aggregateId,
    eventType,
    actorId,
    payload,
    occurredAt,
    recordedAt,
  ];
}
