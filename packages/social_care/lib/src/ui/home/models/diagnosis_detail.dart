final class DiagnosisDetail {
  const DiagnosisDetail._fromJson(this._json);
  final Map<String, dynamic> _json;

  factory DiagnosisDetail.fromJson(Map<String, dynamic> json) {
    return DiagnosisDetail._fromJson(json);
  }

  String get description => _json['description'] as String? ?? '';
}
