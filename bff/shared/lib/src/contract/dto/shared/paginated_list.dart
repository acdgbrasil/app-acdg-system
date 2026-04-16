import 'package:json_annotation/json_annotation.dart';

import 'pagination_meta.dart';

part 'paginated_list.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class PaginatedList<T> {
  const PaginatedList({required this.data, required this.meta});

  factory PaginatedList.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PaginatedListFromJson(json, fromJsonT);

  final List<T> data;
  final PaginationMeta meta;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PaginatedListToJson(this, toJsonT);
}
