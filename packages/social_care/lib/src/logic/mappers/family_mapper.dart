import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../data/commands/family_intents.dart';

/// Specialized mapper to assemble Family-related domain objects.
abstract final class FamilyMapper {
  /// Converts an [AddFamilyMemberIntent] into a valid [FamilyMember] domain object.
  static Result<FamilyMember> toFamilyMember(AddFamilyMemberIntent intent) {
    final PersonId personId;
    switch (PersonId.create(UuidUtil.generateV4())) {
      case Success(:final value):
        personId = value;
      case Failure(:final error):
        return Failure(error);
    }

    final LookupId relationshipId;
    switch (LookupId.create(intent.relationshipId)) {
      case Success(:final value):
        relationshipId = value;
      case Failure(:final error):
        return Failure(error);
    }

    final TimeStamp birthDate;
    switch (TimeStamp.fromDate(intent.birthDate)) {
      case Success(:final value):
        birthDate = value;
      case Failure(:final error):
        return Failure(error);
    }

    final fullName = '${intent.firstName} ${intent.lastName}'.trim();

    return FamilyMember.create(
      personId: personId,
      relationshipId: relationshipId,
      isPrimaryCaregiver: intent.isPrimaryCaregiver,
      residesWithPatient: intent.residesWithPatient,
      hasDisability: intent.hasDisability,
      requiredDocuments: intent.requiredDocuments,
      birthDate: birthDate,
      fullName: fullName.isNotEmpty ? fullName : null,
      sex: intent.sex,
    );
  }
}
