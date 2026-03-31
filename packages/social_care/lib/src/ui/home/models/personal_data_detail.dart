final class PersonalDataDetail {
  final String firstName;
  final String lastName;
  final String motherName;
  final String nationality;
  final String sex;
  final String? socialName;
  final String birthDate;
  final String? phone;

  const PersonalDataDetail({
    required this.firstName,
    required this.lastName,
    required this.motherName,
    required this.nationality,
    required this.sex,
    this.socialName,
    required this.birthDate,
    this.phone,
  });

  factory PersonalDataDetail.fromJson(Map<String, dynamic> json) {
    return PersonalDataDetail(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      motherName: json['motherName'] as String,
      nationality: json['nationality'] as String,
      sex: json['sex'] as String,
      socialName: json['socialName'] as String?,
      birthDate: json['birthDate'] as String,
      phone: json['phone'] as String?,
    );
  }
}
