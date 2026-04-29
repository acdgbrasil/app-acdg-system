import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_lookup_item_request.g.dart';

@JsonSerializable()
class UpdateLookupItemRequest with Equatable {
  const UpdateLookupItemRequest({this.codigo, this.descricao});

  factory UpdateLookupItemRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateLookupItemRequestFromJson(json);

  final String? codigo;
  final String? descricao;

  Map<String, dynamic> toJson() => _$UpdateLookupItemRequestToJson(this);

  @override
  List<Object?> get props => [codigo, descricao];
}
