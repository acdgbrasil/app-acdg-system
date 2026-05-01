import 'package:core/core.dart';

/// Personal data of a patient.
///
/// Dates are represented as ISO-8601 strings (`YYYY-MM-DD`) to stay aligned
/// with the BFF schema. Parsing into [DateTime] is responsibility of the
/// presentation layer.
class PersonalData with Equatable {
  const PersonalData({
    required this.firstName,
    required this.lastName,
    required this.motherName,
    required this.nationality,
    required this.sex,
    required this.birthDate,
    this.socialName,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String motherName;
  final String nationality;
  final String sex;
  final String birthDate;
  final String? socialName;
  final String? phone;

  String get fullName => '$firstName $lastName'.trim();

  PersonalData copyWith({
    String? firstName,
    String? lastName,
    String? motherName,
    String? nationality,
    String? sex,
    String? birthDate,
    String? socialName,
    String? phone,
  }) {
    return PersonalData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      motherName: motherName ?? this.motherName,
      nationality: nationality ?? this.nationality,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      socialName: socialName ?? this.socialName,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    motherName,
    nationality,
    sex,
    birthDate,
    socialName,
    phone,
  ];
}
