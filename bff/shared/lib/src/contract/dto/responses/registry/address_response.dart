import 'package:json_annotation/json_annotation.dart';

part 'address_response.g.dart';

@JsonSerializable()
class AddressResponse {
  const AddressResponse({
    required this.isShelter,
    required this.residenceLocation,
    required this.state,
    required this.city,
    this.cep,
    this.isHomeless = false,
    this.street,
    this.neighborhood,
    this.number,
    this.complement,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) =>
      _$AddressResponseFromJson(json);

  final String? cep;
  final bool isShelter;
  final bool isHomeless;
  final String residenceLocation;
  final String? street;
  final String? neighborhood;
  final String? number;
  final String? complement;
  final String state;
  final String city;

  Map<String, dynamic> toJson() => _$AddressResponseToJson(this);
}
