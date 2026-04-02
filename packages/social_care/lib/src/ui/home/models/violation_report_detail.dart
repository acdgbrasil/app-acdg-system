final class ViolationReportDetail {
  const ViolationReportDetail._fromJson(this._json);
  final Map<String, dynamic> _json;

  factory ViolationReportDetail.fromJson(Map<String, dynamic> json) {
    return ViolationReportDetail._fromJson(json);
  }

  /// Raw JSON access — provides untyped access to all fields.
  /// Typed getters should be added as the UI consumes specific fields.
  Map<String, dynamic> get json => _json;
}
