import 'package:core/core.dart';

/// Community support network assessment (ficha Rede de Apoio).
class CommunitySupport with Equatable {
  const CommunitySupport({
    required this.hasRelativeSupport,
    required this.hasNeighborSupport,
    required this.familyConflicts,
    required this.patientParticipatesInGroups,
    required this.familyParticipatesInGroups,
    required this.patientHasAccessToLeisure,
    required this.facesDiscrimination,
  });

  final bool hasRelativeSupport;
  final bool hasNeighborSupport;
  final String familyConflicts;
  final bool patientParticipatesInGroups;
  final bool familyParticipatesInGroups;
  final bool patientHasAccessToLeisure;
  final bool facesDiscrimination;

  CommunitySupport copyWith({
    bool? hasRelativeSupport,
    bool? hasNeighborSupport,
    String? familyConflicts,
    bool? patientParticipatesInGroups,
    bool? familyParticipatesInGroups,
    bool? patientHasAccessToLeisure,
    bool? facesDiscrimination,
  }) {
    return CommunitySupport(
      hasRelativeSupport: hasRelativeSupport ?? this.hasRelativeSupport,
      hasNeighborSupport: hasNeighborSupport ?? this.hasNeighborSupport,
      familyConflicts: familyConflicts ?? this.familyConflicts,
      patientParticipatesInGroups:
          patientParticipatesInGroups ?? this.patientParticipatesInGroups,
      familyParticipatesInGroups:
          familyParticipatesInGroups ?? this.familyParticipatesInGroups,
      patientHasAccessToLeisure:
          patientHasAccessToLeisure ?? this.patientHasAccessToLeisure,
      facesDiscrimination: facesDiscrimination ?? this.facesDiscrimination,
    );
  }

  @override
  List<Object?> get props => [
    hasRelativeSupport,
    hasNeighborSupport,
    familyConflicts,
    patientParticipatesInGroups,
    familyParticipatesInGroups,
    patientHasAccessToLeisure,
    facesDiscrimination,
  ];
}
