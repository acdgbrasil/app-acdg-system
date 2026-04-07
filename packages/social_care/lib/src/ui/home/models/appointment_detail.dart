final class AppointmentDetail {
  final String id;
  final String date;
  final String professionalInChargeId;
  final String type;
  final String summary;
  final String actionPlan;

  const AppointmentDetail({
    required this.id,
    required this.date,
    required this.professionalInChargeId,
    required this.type,
    required this.summary,
    required this.actionPlan,
  });

  factory AppointmentDetail.fromJson(Map<String, dynamic> json) {
    return AppointmentDetail(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      professionalInChargeId: json['professionalInChargeId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      actionPlan: json['actionPlan'] as String? ?? '',
    );
  }
}
