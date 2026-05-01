import 'package:core/core.dart';

/// A social care appointment attached to a patient.
class Appointment with Equatable {
  const Appointment({
    required this.appointmentId,
    required this.date,
    required this.professionalId,
    required this.type,
    required this.summary,
    required this.actionPlan,
  });

  final String appointmentId;
  final String date;
  final String professionalId;
  final String type;
  final String summary;
  final String actionPlan;

  Appointment copyWith({
    String? appointmentId,
    String? date,
    String? professionalId,
    String? type,
    String? summary,
    String? actionPlan,
  }) {
    return Appointment(
      appointmentId: appointmentId ?? this.appointmentId,
      date: date ?? this.date,
      professionalId: professionalId ?? this.professionalId,
      type: type ?? this.type,
      summary: summary ?? this.summary,
      actionPlan: actionPlan ?? this.actionPlan,
    );
  }

  @override
  List<Object?> get props => [
    appointmentId,
    date,
    professionalId,
    type,
    summary,
    actionPlan,
  ];
}
