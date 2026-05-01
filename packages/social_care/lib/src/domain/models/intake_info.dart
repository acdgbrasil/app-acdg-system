import 'package:core/core.dart';

/// Intake information captured when a patient enters the service.
class IntakeInfo with Equatable {
  const IntakeInfo({
    required this.ingressTypeId,
    required this.serviceReason,
    this.originName,
    this.originContact,
    this.linkedSocialPrograms = const [],
  });

  final String ingressTypeId;
  final String serviceReason;
  final String? originName;
  final String? originContact;
  final List<ProgramLink> linkedSocialPrograms;

  IntakeInfo copyWith({
    String? ingressTypeId,
    String? serviceReason,
    String? originName,
    String? originContact,
    List<ProgramLink>? linkedSocialPrograms,
  }) {
    return IntakeInfo(
      ingressTypeId: ingressTypeId ?? this.ingressTypeId,
      serviceReason: serviceReason ?? this.serviceReason,
      originName: originName ?? this.originName,
      originContact: originContact ?? this.originContact,
      linkedSocialPrograms: linkedSocialPrograms ?? this.linkedSocialPrograms,
    );
  }

  @override
  List<Object?> get props => [
    ingressTypeId,
    serviceReason,
    originName,
    originContact,
    linkedSocialPrograms,
  ];
}

/// Link between a patient and a social program.
class ProgramLink with Equatable {
  const ProgramLink({required this.programId, this.observation});

  final String programId;
  final String? observation;

  ProgramLink copyWith({String? programId, String? observation}) {
    return ProgramLink(
      programId: programId ?? this.programId,
      observation: observation ?? this.observation,
    );
  }

  @override
  List<Object?> get props => [programId, observation];
}
