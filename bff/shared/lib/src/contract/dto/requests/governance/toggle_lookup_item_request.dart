import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'toggle_lookup_item_request.g.dart';

@JsonSerializable()
class ToggleLookupItemRequest with Equatable {
  const ToggleLookupItemRequest({required this.active});

  factory ToggleLookupItemRequest.fromJson(Map<String, dynamic> json) =>
      _$ToggleLookupItemRequestFromJson(json);

  final bool active;

  Map<String, dynamic> toJson() => _$ToggleLookupItemRequestToJson(this);

  @override
  List<Object?> get props => [active];
}
