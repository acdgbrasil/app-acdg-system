import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Desktop-only Read Model for the Care aggregate — appointments scoped
/// to a patient. Each row is keyed by `(patientId, appointmentId)`.
///
/// No FTS5 in this MVP — appointments are looked up by patient and not
/// free-text searchable. Add a future ticket if search-by-summary
/// becomes a UX requirement.
abstract interface class CareCache {
  Future<Result<AppointmentResponse?>> findById(
    String patientId,
    String appointmentId,
  );

  Future<Result<List<AppointmentResponse>>> listByPatient(
    String patientId, {
    int? limit,
  });

  Future<Result<void>> upsert(
    String patientId,
    AppointmentResponse dto, {
    required int version,
  });

  Future<Result<void>> delete(String patientId, String appointmentId);

  Future<Result<void>> clear();
}
