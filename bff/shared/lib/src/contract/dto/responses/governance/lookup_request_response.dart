import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lookup_request_response.g.dart';

@JsonSerializable()
class LookupRequestResponse with Equatable {
  const LookupRequestResponse({
    required this.id,
    required this.tableName,
    required this.codigo,
    required this.descricao,
    required this.justificativa,
    required this.status,
    required this.createdAt,
    required this.requestedBy,
  });

  factory LookupRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$LookupRequestResponseFromJson(json);

  final String id;
  final String tableName;
  final String codigo;
  final String descricao;
  final String? justificativa;
  final String status;
  final String createdAt;
  final String requestedBy;

  Map<String, dynamic> toJson() => _$LookupRequestResponseToJson(this);

  @override
  List<Object?> get props => [
    id,
    tableName,
    codigo,
    descricao,
    justificativa,
    status,
    createdAt,
    requestedBy,
  ];
}
