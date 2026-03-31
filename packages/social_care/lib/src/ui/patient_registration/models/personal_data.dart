import 'package:social_care/src/ui/patient_registration/models/enums/gender.dart';
import 'package:social_care/src/ui/patient_registration/models/enums/nationality.dart';

final class PersonalData {
  final String firstName;
  final String lastName;
  final String motherName;
  final String? socialName;
  final Nationality nationality;
  final Gender sex;
  final String? phone;

  PersonalData({
    required this.firstName,
    required this.lastName,
    required this.motherName,
    this.socialName,
    required this.nationality,
    required this.sex,
    this.phone,
  });
}