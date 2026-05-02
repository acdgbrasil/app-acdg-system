import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'indicator_response.g.dart';

@JsonSerializable()
class IndicatorResponse with Equatable {
  const IndicatorResponse({required this.axis, required this.rows, this.meta});

  factory IndicatorResponse.fromJson(Map<String, dynamic> json) =>
      _$IndicatorResponseFromJson(json);

  final String axis;
  final List<IndicatorRowResponse> rows;
  final IndicatorMetaResponse? meta;

  Map<String, dynamic> toJson() => _$IndicatorResponseToJson(this);

  @override
  List<Object?> get props => [axis, rows, meta];
}

@JsonSerializable()
class IndicatorRowResponse with Equatable {
  const IndicatorRowResponse({
    required this.dimensions,
    required this.count,
    this.period,
  });

  factory IndicatorRowResponse.fromJson(Map<String, dynamic> json) =>
      _$IndicatorRowResponseFromJson(json);

  final Map<String, String> dimensions;
  final int count;
  final String? period;

  Map<String, dynamic> toJson() => _$IndicatorRowResponseToJson(this);

  @override
  List<Object?> get props => [dimensions, count, period];
}

@JsonSerializable()
class IndicatorMetaResponse with Equatable {
  const IndicatorMetaResponse({
    this.total = 0,
    this.suppressedGroups = 0,
    this.generalizationLevel,
  });

  factory IndicatorMetaResponse.fromJson(Map<String, dynamic> json) =>
      _$IndicatorMetaResponseFromJson(json);

  final int total;
  final int suppressedGroups;
  final String? generalizationLevel;

  Map<String, dynamic> toJson() => _$IndicatorMetaResponseToJson(this);

  @override
  List<Object?> get props => [total, suppressedGroups, generalizationLevel];
}
