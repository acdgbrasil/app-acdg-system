import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../commands/assessment_intents.dart';

/// Maps [UpdateEducationalStatusIntent] to the [EducationalStatus] domain
/// object. Dedicated mapper for the Educational Status endpoint.
abstract final class EducationalStatusMapper {
  /// Maps [UpdateEducationalStatusIntent] to [EducationalStatus].
  static Result<EducationalStatus> toEducationalStatus(
    UpdateEducationalStatusIntent intent,
  ) {
    return Success(
      EducationalStatus(
        familyId: intent.patientId,
        memberProfiles: intent.memberProfiles,
        programOccurrences: intent.programOccurrences,
      ),
    );
  }
}
