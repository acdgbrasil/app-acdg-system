import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'standard_response.g.dart';

/// Generic wrapper for standard responses. Value equality is transitive only
/// when the payload type `T` is itself Equatable (or a primitive / Equatable
/// type like String, int, bool). When `T` is a non-Equatable reference type,
/// equality of [data] falls back to reference equality.
@JsonSerializable(genericArgumentFactories: true)
class StandardResponse<T> with Equatable {
  const StandardResponse({required this.data, required this.meta});

  factory StandardResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$StandardResponseFromJson(json, fromJsonT);

  final T data;
  final ResponseMeta meta;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$StandardResponseToJson(this, toJsonT);

  @override
  List<Object?> get props => [data, meta];
}

@JsonSerializable()
class ResponseMeta with Equatable {
  const ResponseMeta({required this.timestamp});

  factory ResponseMeta.fromJson(Map<String, dynamic> json) =>
      _$ResponseMetaFromJson(json);

  final String timestamp;

  Map<String, dynamic> toJson() => _$ResponseMetaToJson(this);

  @override
  List<Object?> get props => [timestamp];
}

@JsonSerializable()
class IdData with Equatable {
  const IdData({required this.id});

  factory IdData.fromJson(Map<String, dynamic> json) => _$IdDataFromJson(json);

  final String id;

  Map<String, dynamic> toJson() => _$IdDataToJson(this);

  @override
  List<Object?> get props => [id];
}

typedef StandardIdResponse = StandardResponse<IdData>;
