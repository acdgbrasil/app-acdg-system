import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

import 'pagination_meta.dart';

part 'paginated_list.g.dart';

/// Generic wrapper for paginated responses. Value equality is transitive only
/// when the element type `T` is itself Equatable (or a primitive / Equatable
/// type like String, int, bool). When `T` is a non-Equatable reference type,
/// equality of the [data] list falls back to element reference equality.
@JsonSerializable(genericArgumentFactories: true)
class PaginatedList<T> with Equatable {
  const PaginatedList({required this.data, required this.meta});

  factory PaginatedList.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PaginatedListFromJson(json, fromJsonT);

  final List<T> data;
  final PaginationMeta meta;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PaginatedListToJson(this, toJsonT);

  @override
  List<Object?> get props => [data, meta];
}
