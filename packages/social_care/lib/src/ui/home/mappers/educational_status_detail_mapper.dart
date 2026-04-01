import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../models/educational_status_detail.dart';

/// Maps [EducationalStatusDetail] → [UpdateEducationalStatusIntent].
abstract final class EducationalStatusDetailMapper {
  static Result<UpdateEducationalStatusIntent> toIntent(
    EducationalStatusDetail detail, {
    required PatientId patientId,
  }) {
    final profiles = <MemberEducationalProfile>[];
    for (final (i, p) in detail.memberProfiles.indexed) {
      final PersonId memberId;
      switch (PersonId.create(p.memberId)) {
        case Success(:final value): memberId = value;
        case Failure(:final error):
          return Failure('memberProfiles[$i].memberId: $error');
      }

      final LookupId educationLevelId;
      switch (LookupId.create(p.educationLevelId)) {
        case Success(:final value): educationLevelId = value;
        case Failure(:final error):
          return Failure('memberProfiles[$i].educationLevelId: $error');
      }

      profiles.add(MemberEducationalProfile(
        memberId: memberId,
        canReadWrite: p.canReadWrite,
        attendsSchool: p.attendsSchool,
        educationLevelId: educationLevelId,
      ));
    }

    final occurrences = <ProgramOccurrence>[];
    for (final (i, o) in detail.programOccurrences.indexed) {
      final PersonId memberId;
      switch (PersonId.create(o.memberId)) {
        case Success(:final value): memberId = value;
        case Failure(:final error):
          return Failure('programOccurrences[$i].memberId: $error');
      }

      final TimeStamp date;
      switch (TimeStamp.fromIso(o.date)) {
        case Success(:final value): date = value;
        case Failure(:final error):
          return Failure('programOccurrences[$i].date: $error');
      }

      final LookupId effectId;
      switch (LookupId.create(o.effectId)) {
        case Success(:final value): effectId = value;
        case Failure(:final error):
          return Failure('programOccurrences[$i].effectId: $error');
      }

      occurrences.add(ProgramOccurrence(
        memberId: memberId,
        date: date,
        effectId: effectId,
        isSuspensionRequested: o.isSuspensionRequested,
      ));
    }

    return Success(UpdateEducationalStatusIntent(
      patientId: patientId,
      memberProfiles: profiles,
      programOccurrences: occurrences,
    ));
  }
}
