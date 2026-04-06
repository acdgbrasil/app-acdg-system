import 'package:equatable/equatable.dart';
import 'package:social_care/src/ui/patient_registration/models/enums/gender.dart';
import 'package:social_care/src/ui/patient_registration/models/enums/nationality.dart';

final class PersonalData extends Equatable {
  final String firstName;
  final String lastName;
  final String motherName;
  final String? socialName;
  final Nationality nationality;
  final Gender sex;
  final String? phone;

  const PersonalData({
    required this.firstName,
    required this.lastName,
    required this.motherName,
    this.socialName,
    required this.nationality,
    required this.sex,
    this.phone,
  });

  PersonalData copyWith({
    String? firstName,
    String? lastName,
    String? motherName,
    String? socialName,
    Nationality? nationality,
    Gender? sex,
    String? phone,
  }) {
    return PersonalData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      motherName: motherName ?? this.motherName,
      socialName: socialName ?? this.socialName,
      nationality: nationality ?? this.nationality,
      sex: sex ?? this.sex,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    motherName,
    socialName,
    nationality,
    sex,
    phone,
  ];
}
