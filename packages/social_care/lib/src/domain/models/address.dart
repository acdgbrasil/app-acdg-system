import 'package:core/core.dart';

/// Residential address of a patient.
///
/// Pure domain schema — validation and normalization live in the BFF.
class Address with Equatable {
  const Address({
    required this.residenceLocation,
    required this.state,
    required this.city,
    this.cep,
    this.isShelter = false,
    this.isHomeless = false,
    this.street,
    this.neighborhood,
    this.number,
    this.complement,
  });

  final String residenceLocation;
  final String state;
  final String city;
  final String? cep;
  final bool isShelter;
  final bool isHomeless;
  final String? street;
  final String? neighborhood;
  final String? number;
  final String? complement;

  Address copyWith({
    String? residenceLocation,
    String? state,
    String? city,
    String? cep,
    bool? isShelter,
    bool? isHomeless,
    String? street,
    String? neighborhood,
    String? number,
    String? complement,
  }) {
    return Address(
      residenceLocation: residenceLocation ?? this.residenceLocation,
      state: state ?? this.state,
      city: city ?? this.city,
      cep: cep ?? this.cep,
      isShelter: isShelter ?? this.isShelter,
      isHomeless: isHomeless ?? this.isHomeless,
      street: street ?? this.street,
      neighborhood: neighborhood ?? this.neighborhood,
      number: number ?? this.number,
      complement: complement ?? this.complement,
    );
  }

  @override
  List<Object?> get props => [
    residenceLocation,
    state,
    city,
    cep,
    isShelter,
    isHomeless,
    street,
    neighborhood,
    number,
    complement,
  ];
}
