final class DiagnosisDetail {
  final String id;
  final String description;
  final String date;

  const DiagnosisDetail({
    required this.id,
    required this.description,
    required this.date,
  });

  factory DiagnosisDetail.fromJson(Map<String, dynamic> json) {
    return DiagnosisDetail(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }
}
