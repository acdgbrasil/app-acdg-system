import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../commands/family_intents.dart';

/// Maps [AddFamilyMemberIntent] to a [FamilyMember] domain entity.
/// Dedicated mapper for the Add Family Member endpoint.
abstract final class AddFamilyMemberMapper {
  /// Converts an [AddFamilyMemberIntent] into a valid [FamilyMember].
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
