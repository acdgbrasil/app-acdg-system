import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../models/educational_status_detail.dart';

/// Maps [EducationalStatusDetail] → [UpdateEducationalStatusIntent].
abstract final class EducationalStatusDetailMapper {
  static UpdateEducationalStatusIntent toIntent(
    EducationalStatusDetail detail, {
    required PatientId patientId,
  }) {
    return UpdateEducationalStatusIntent(
      patientId: patientId,
      memberProfiles: detail.memberProfiles
          .map(
            (p) => MemberEducationalProfile(
              memberId: PersonId.create(p.memberId).valueOrNull!,
              canReadWrite: p.canReadWrite,
              attendsSchool: p.attendsSchool,
              educationLevelId:
                  LookupId.create(p.educationLevelId).valueOrNull!,
            ),
          )
          .toList(),
      programOccurrences: detail.programOccurrences
          .map(
            (o) => ProgramOccurrence(
              memberId: PersonId.create(o.memberId).valueOrNull!,
              date: TimeStamp.fromIso(o.date).valueOrNull!,
              effectId: LookupId.create(o.effectId).valueOrNull!,
              isSuspensionRequested: o.isSuspensionRequested,
            ),
          )
          .toList(),
    );
  }
}
