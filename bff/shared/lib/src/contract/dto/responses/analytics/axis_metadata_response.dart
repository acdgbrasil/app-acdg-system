import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'axis_metadata_response.g.dart';

@JsonSerializable()
class AxisMetadataResponse with Equatable {
  const AxisMetadataResponse({
    required this.name,
    this.description,
    this.availableDimensions = const [],
    this.availablePeriods = const [],
  });

  factory AxisMetadataResponse.fromJson(Map<String, dynamic> json) =>
      _$AxisMetadataResponseFromJson(json);

  final String name;
  final String? description;
  final List<String> availableDimensions;
  final List<String> availablePeriods;

  Map<String, dynamic> toJson() => _$AxisMetadataResponseToJson(this);

  @override
  List<Object?> get props => [
    name,
    description,
    availableDimensions,
    availablePeriods,
  ];
}
