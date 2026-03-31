import 'package:core/core.dart';
import 'package:shared/shared.dart';

/// Intent to update social identity.
final class UpdateSocialIdentityIntent with Equatable {
  const UpdateSocialIdentityIntent({
    required this.patientId,
    required this.identity,
  });

  final PatientId patientId;
  final SocialIdentity identity;

  @override
  List<Object?> get props => [patientId, identity];
}
