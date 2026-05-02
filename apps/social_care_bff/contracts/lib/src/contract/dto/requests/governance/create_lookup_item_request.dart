import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_lookup_item_request.g.dart';

@JsonSerializable()
class CreateLookupItemRequest with Equatable {
  const CreateLookupItemRequest({
    required this.codigo,
    required this.descricao,
  });

  factory CreateLookupItemRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateLookupItemRequestFromJson(json);

  final String codigo;
  final String descricao;

  Map<String, dynamic> toJson() => _$CreateLookupItemRequestToJson(this);

  @override
  List<Object?> get props => [codigo, descricao];
}
