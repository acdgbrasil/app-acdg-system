final class AddressDetail {
  final String? cep;
  final bool isShelter;
  final String residenceLocation;
  final String? street;
  final String? neighborhood;
  final String? number;
  final String? complement;
  final String state;
  final String city;

  const AddressDetail({
    this.cep,
    required this.isShelter,
    required this.residenceLocation,
    this.street,
    this.neighborhood,
    this.number,
    this.complement,
    required this.state,
    required this.city,
  });

  factory AddressDetail.fromJson(Map<String, dynamic> json) {
    return AddressDetail(
      cep: json['cep'] as String?,
      isShelter: json['isShelter'] as bool,
      residenceLocation: json['residenceLocation'] as String,
      street: json['street'] as String?,
      neighborhood: json['neighborhood'] as String?,
      number: json['number'] as String?,
      complement: json['complement'] as String?,
      state: json['state'] as String,
      city: json['city'] as String,
    );
  }
}
