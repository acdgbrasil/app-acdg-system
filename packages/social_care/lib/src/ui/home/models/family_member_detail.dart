final class FamilyMemberDetail {
  const FamilyMemberDetail._fromJson(this._json);
  final Map<String, dynamic> _json;

  factory FamilyMemberDetail.fromJson(Map<String, dynamic> json) {
    return FamilyMemberDetail._fromJson(json);
  }

  String get id => _json['id'] as String? ?? '';
}
