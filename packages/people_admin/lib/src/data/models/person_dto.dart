import 'package:equatable/equatable.dart';
import '../../domain/models/person.dart';

final class PersonDto with EquatableMixin {
  const PersonDto({
    required this.id,
    required this.fullName,
    required this.active,
    this.cpf,
    this.birthDate,
    this.email,
    this.zitadelUserId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String? cpf;
  final String? birthDate;
  final String? email;
  final String? zitadelUserId;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    fullName,
    cpf,
    birthDate,
    email,
    zitadelUserId,
    active,
    createdAt,
    updatedAt,
  ];

  factory PersonDto.fromJson(Map<String, dynamic> json) {
    return PersonDto(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      cpf: json['cpf'] as String?,
      birthDate: json['birthDate'] as String?,
      email: json['email'] as String?,
      zitadelUserId: json['zitadelUserId'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String)
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'] as String)
              : null,
    );
  }

  Person toDomain() {
    return Person(
      id: id,
      fullName: fullName,
      active: active,
      cpf: cpf,
      birthDate: birthDate,
      email: email,
      zitadelUserId: zitadelUserId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
