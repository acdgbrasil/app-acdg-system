import 'package:json_annotation/json_annotation.dart';

part 'audit_trail_entry_response.g.dart';

@JsonSerializable()
class AuditTrailEntryResponse {
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
}
