import 'package:core/core.dart';

/// A person registered in the People Context.
///
/// Persons are referenced by [Patient] and [FamilyMember] through their
/// [personId]. Enrichment with [fullName]/[birthDate]/[cpf] happens at the
/// BFF boundary and may be partial depending on available metadata.
class Person with Equatable {
  const Person({
    required this.personId,
    required this.fullName,
    this.birthDate,
    this.cpf,
  });

  final String personId;
  final String fullName;
  final String? birthDate;
  final String? cpf;

  Person copyWith({
    String? personId,
    String? fullName,
    String? birthDate,
    String? cpf,
  }) {
    return Person(
      personId: personId ?? this.personId,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      cpf: cpf ?? this.cpf,
    );
  }

  @override
  List<Object?> get props => [personId, fullName, birthDate, cpf];
}
