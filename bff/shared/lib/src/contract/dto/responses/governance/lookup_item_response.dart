import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lookup_item_response.g.dart';

@JsonSerializable()
class LookupItemResponse with Equatable {
  const LookupItemResponse({
    required this.id,
    required this.codigo,
    required this.descricao,
  });

  factory LookupItemResponse.fromJson(Map<String, dynamic> json) =>
      _$LookupItemResponseFromJson(json);

  final String id;
  final String codigo;
  final String descricao;

  Map<String, dynamic> toJson() => _$LookupItemResponseToJson(this);

  @override
  List<Object?> get props => [id, codigo, descricao];
}
