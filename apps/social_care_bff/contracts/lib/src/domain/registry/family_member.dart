import 'package:core_contracts/core_contracts.dart';
import '../kernel/ids.dart';
import '../kernel/time_stamp.dart';
import 'registry_vos.dart';

/// Entidade que representa um membro da composição familiar.
final class FamilyMember with Equatable {
  const FamilyMember._({
    required this.personId,
    required this.relationshipId,
    required this.isPrimaryCaregiver,
    required this.residesWithPatient,
    required this.hasDisability,
    required this.requiredDocuments,
    required this.birthDate,
    this.fullName,
    this.sex,
  });

  final PersonId personId;
  final LookupId relationshipId;
  final bool isPrimaryCaregiver;
  final bool residesWithPatient;
  final bool hasDisability;
  final List<RequiredDocument> requiredDocuments;
  final TimeStamp birthDate;
  final String? fullName;
  final String? sex;

  @override
  List<Object?> get props => [personId]; // Igualdade por personId conforme design

  static Result<FamilyMember> create({
    required PersonId personId,
    required LookupId relationshipId,
    bool isPrimaryCaregiver = false,
    required bool residesWithPatient,
    bool hasDisability = false,
    List<RequiredDocument> requiredDocuments = const [],
    required TimeStamp birthDate,
    String? fullName,
    String? sex,
  }) {
    // Deduplicar e ordenar documentos requeridos
    final docs = requiredDocuments.toSet().toList();
    docs.sort((a, b) => a.value.compareTo(b.value));

    return Success(
      FamilyMember._(
        personId: personId,
        relationshipId: relationshipId,
        isPrimaryCaregiver: isPrimaryCaregiver,
        residesWithPatient: residesWithPatient,
        hasDisability: hasDisability,
        requiredDocuments: List.unmodifiable(docs),
        birthDate: birthDate,
        fullName: fullName,
        sex: sex,
      ),
    );
  }

  /// Reconstitui um membro familiar a partir da persistência sem validações.
  static FamilyMember reconstitute({
    required PersonId personId,
    required LookupId relationshipId,
    required bool isPrimaryCaregiver,
    required bool residesWithPatient,
    required bool hasDisability,
    required List<RequiredDocument> requiredDocuments,
    required TimeStamp birthDate,
    String? fullName,
    String? sex,
  }) {
    return FamilyMember._(
      personId: personId,
      relationshipId: relationshipId,
      isPrimaryCaregiver: isPrimaryCaregiver,
      residesWithPatient: residesWithPatient,
      hasDisability: hasDisability,
      requiredDocuments: List.unmodifiable(requiredDocuments),
      birthDate: birthDate,
      fullName: fullName,
      sex: sex,
    );
  }

  FamilyMember copyWith({
    PersonId? personId,
    LookupId? relationshipId,
    bool? isPrimaryCaregiver,
    bool? residesWithPatient,
    bool? hasDisability,
    List<RequiredDocument>? requiredDocuments,
    TimeStamp? birthDate,
    String? fullName,
    String? sex,
  }) {
    return FamilyMember._(
      personId: personId ?? this.personId,
      relationshipId: relationshipId ?? this.relationshipId,
      isPrimaryCaregiver: isPrimaryCaregiver ?? this.isPrimaryCaregiver,
      residesWithPatient: residesWithPatient ?? this.residesWithPatient,
      hasDisability: hasDisability ?? this.hasDisability,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      birthDate: birthDate ?? this.birthDate,
      fullName: fullName ?? this.fullName,
      sex: sex ?? this.sex,
    );
  }
}
