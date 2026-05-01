import 'package:core/core.dart';

/// Self-declared social identity of a patient.
///
/// [typeId] references a lookup table managed by the BFF. [otherDescription]
/// is populated only when the chosen type requires a free-text explanation.
class SocialIdentity with Equatable {
  const SocialIdentity({required this.typeId, this.otherDescription});

  final String typeId;
  final String? otherDescription;

  SocialIdentity copyWith({String? typeId, String? otherDescription}) {
    return SocialIdentity(
      typeId: typeId ?? this.typeId,
      otherDescription: otherDescription ?? this.otherDescription,
    );
  }

  @override
  List<Object?> get props => [typeId, otherDescription];
}
