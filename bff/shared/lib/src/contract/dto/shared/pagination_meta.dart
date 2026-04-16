import 'package:json_annotation/json_annotation.dart';

part 'pagination_meta.g.dart';

@JsonSerializable()
class PaginationMeta {
  const PaginationMeta({
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
    this.nextCursor,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);

  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final String? nextCursor;

  Map<String, dynamic> toJson() => _$PaginationMetaToJson(this);
}
