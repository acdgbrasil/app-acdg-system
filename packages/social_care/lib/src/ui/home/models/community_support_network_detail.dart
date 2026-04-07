final class CommunitySupportNetworkDetail {
  final bool hasRelativeSupport;
  final bool hasNeighborSupport;
  final String familyConflicts;
  final bool patientParticipatesInGroups;
  final bool familyParticipatesInGroups;
  final bool patientHasAccessToLeisure;
  final bool facesDiscrimination;

  const CommunitySupportNetworkDetail({
    required this.hasRelativeSupport,
    required this.hasNeighborSupport,
    required this.familyConflicts,
    required this.patientParticipatesInGroups,
    required this.familyParticipatesInGroups,
    required this.patientHasAccessToLeisure,
    required this.facesDiscrimination,
  });

  factory CommunitySupportNetworkDetail.fromJson(Map<String, dynamic> json) {
    return CommunitySupportNetworkDetail(
      hasRelativeSupport: json['hasRelativeSupport'] as bool,
      hasNeighborSupport: json['hasNeighborSupport'] as bool,
      familyConflicts: json['familyConflicts'] as String,
      patientParticipatesInGroups: json['patientParticipatesInGroups'] as bool,
      familyParticipatesInGroups: json['familyParticipatesInGroups'] as bool,
      patientHasAccessToLeisure: json['patientHasAccessToLeisure'] as bool,
      facesDiscrimination: json['facesDiscrimination'] as bool,
    );
  }
}
