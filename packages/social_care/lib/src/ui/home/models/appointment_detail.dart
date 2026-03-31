final class AppointmentDetail {
  const AppointmentDetail._fromJson(this._json);
  final Map<String, dynamic> _json;

  factory AppointmentDetail.fromJson(Map<String, dynamic> json) {
    return AppointmentDetail._fromJson(json);
  }
}
