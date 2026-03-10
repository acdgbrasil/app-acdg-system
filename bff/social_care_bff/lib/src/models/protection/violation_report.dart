/// A rights violation report.
final class ViolationReport {
  const ViolationReport({
    required this.id,
    required this.victimId,
    required this.violationType,
    required this.descriptionOfFact,
    this.reportDate,
    this.incidentDate,
    this.actionsTaken,
  });

  final String id;
  final String victimId;
  final String violationType;
  final String descriptionOfFact;
  final DateTime? reportDate;
  final DateTime? incidentDate;
  final String? actionsTaken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ViolationReport && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ViolationReport(id: $id)';
}
