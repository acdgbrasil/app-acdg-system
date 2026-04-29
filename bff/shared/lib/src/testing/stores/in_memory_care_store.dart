import '../../contract/dto/responses/care/appointment_response.dart';
import '../../contract/dto/responses/care/ingress_info_response.dart';

/// In-memory collaborator that stores appointments grouped by `patientId`
/// plus a single intake info per patient.
///
/// Both maps are keyed by `patientId` — this is the grouping the care
/// contract exposes (see `FakeCareBff.registerAppointment`).
class InMemoryCareStore {
  InMemoryCareStore();

  /// Appointments keyed by `patientId` (list preserves insertion order).
  final Map<String, List<AppointmentResponse>> appointments = {};

  /// Latest intake info per `patientId`.
  final Map<String, IngressInfoResponse> intakes = {};

  /// Appends an appointment to the patient's list.
  void addAppointment(String patientId, AppointmentResponse appointment) {
    appointments
        .putIfAbsent(patientId, () => <AppointmentResponse>[])
        .add(appointment);
  }

  /// Replaces the intake info for the patient.
  void setIntake(String patientId, IngressInfoResponse intake) {
    intakes[patientId] = intake;
  }

  /// Snapshot of appointments for a patient. Empty list if unknown.
  List<AppointmentResponse> listAppointments(String patientId) =>
      List<AppointmentResponse>.from(
        appointments[patientId] ?? const <AppointmentResponse>[],
      );

  /// Returns the intake for a patient, or `null`.
  ///
  /// Same reference as was stored.
  IngressInfoResponse? getIntake(String patientId) => intakes[patientId];

  /// Resets the store between tests.
  void clear() {
    appointments.clear();
    intakes.clear();
  }
}
