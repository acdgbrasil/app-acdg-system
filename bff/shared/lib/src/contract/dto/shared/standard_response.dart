import 'package:json_annotation/json_annotation.dart';

part 'standard_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class StandardResponse<T> {
  const StandardResponse({required this.data, required this.meta});

  factory StandardResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$StandardResponseFromJson(json, fromJsonT);

  final T data;
  final ResponseMeta meta;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$StandardResponseToJson(this, toJsonT);
}

@JsonSerializable()
class ResponseMeta {
  const ResponseMeta({required this.timestamp});

  factory ResponseMeta.fromJson(Map<String, dynamic> json) =>
      _$ResponseMetaFromJson(json);

  final String timestamp;

  Map<String, dynamic> toJson() => _$ResponseMetaToJson(this);
}

@JsonSerializable()
class IdData {
  const IdData({required this.id});

  factory IdData.fromJson(Map<String, dynamic> json) => _$IdDataFromJson(json);

  final String id;

  Map<String, dynamic> toJson() => _$IdDataToJson(this);
}

typedef StandardIdResponse = StandardResponse<IdData>;
