import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../data/commands/family_intents.dart';

/// Specialized mapper to assemble Family-related domain objects.
abstract final class FamilyMapper {
  /// Converts an [AddFamilyMemberIntent] into a valid [FamilyMember] domain object.
  static Result<FamilyMember> toFamilyMember(AddFamilyMemberIntent intent) {
    return FamilyMember.create(
      personId: PersonId.create(UuidUtil.generateV4()).valueOrNull!,
      relationshipId: LookupId.create(intent.relationshipId).valueOrNull!,
      isPrimaryCaregiver: intent.isPrimaryCaregiver,
      residesWithPatient: intent.residesWithPatient,
      hasDisability: intent.hasDisability,
      requiredDocuments: intent.requiredDocuments,
      birthDate: TimeStamp.fromDate(intent.birthDate).valueOrNull!,
    );
  }
}
