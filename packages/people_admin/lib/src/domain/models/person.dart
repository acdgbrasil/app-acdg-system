import 'package:equatable/equatable.dart';

final class Person with EquatableMixin {
  const Person({
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
}
