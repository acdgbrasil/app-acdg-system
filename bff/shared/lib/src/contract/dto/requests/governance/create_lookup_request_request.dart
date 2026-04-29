import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_lookup_request_request.g.dart';

@JsonSerializable()
class CreateLookupRequestRequest with Equatable {
  const CreateLookupRequestRequest({
    required this.tableName,
    required this.codigo,
    required this.descricao,
    this.justificativa,
  });

  factory CreateLookupRequestRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateLookupRequestRequestFromJson(json);

  final String tableName;
  final String codigo;
  final String descricao;
  final String? justificativa;

  Map<String, dynamic> toJson() => _$CreateLookupRequestRequestToJson(this);

  @override
  List<Object?> get props => [tableName, codigo, descricao, justificativa];
}
