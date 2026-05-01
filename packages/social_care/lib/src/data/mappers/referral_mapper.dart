import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../commands/intervention_intents.dart';

/// Maps [CreateReferralIntent] to the [Referral] domain aggregate.
/// Dedicated mapper for the Create Referral endpoint.
abstract final class ReferralMapper {
  /// Fallback UUID used when the client did not supply a professional id.
  /// The referral repository/BFF is expected to replace it with the actor
  /// identity before persisting.
  static const String _anonymousProfessionalUuid =
      '00000000-0000-0000-0000-000000000000';

  /// Maps [CreateReferralIntent] to [Referral].
  static Result<Referral> toReferral(CreateReferralIntent intent) {
    final ReferralId id;
    switch (ReferralId.create(UuidUtil.generateV4())) {
      case Success(:final value):
        id = value;
      case Failure(:final error):
        return Failure(error);
    }

    final PersonId referredPersonId;
    switch (PersonId.create(intent.referredPersonId)) {
      case Success(:final value):
        referredPersonId = value;
      case Failure(:final error):
        return Failure(error);
    }

    final ProfessionalId requestingProfessionalId;
    final rawProfessionalId = intent.professionalId.isNotEmpty
        ? intent.professionalId
        : _anonymousProfessionalUuid;
    switch (ProfessionalId.create(rawProfessionalId)) {
      case Success(:final value):
        requestingProfessionalId = value;
      case Failure(:final error):
        return Failure(error);
    }

    final TimeStamp date;
    switch (TimeStamp.fromDate(intent.date ?? DateTime.now())) {
      case Success(:final value):
        date = value;
      case Failure(:final error):
        return Failure(error);
    }

    return Referral.create(
      id: id,
      date: date,
      requestingProfessionalId: requestingProfessionalId,
      referredPersonId: referredPersonId,
      destinationService: intent.destinationService,
      reason: intent.reason,
    );
  }
}
