import '../../contract/dto/responses/registry/patient_response.dart';
import '../../contract/dto/responses/registry/patient_summary_response.dart';

/// In-memory collaborator that stores [PatientResponse] aggregates and their
/// list-view projection [PatientSummaryResponse].
///
/// Follows `handbook/architecture/ENCAPSULATION_POLICY.md` — fields are
/// intentionally public so tests can inspect `store.patients` directly.
/// The class still exposes methods that keep the two maps in sync (an
/// invariant: every `save` writes to both).
class InMemoryPatientStore {
  InMemoryPatientStore();

  /// Full aggregates keyed by `patientId`.
  final Map<String, PatientResponse> patients = {};

  /// List-view projections keyed by `patientId`.
  final Map<String, PatientSummaryResponse> summaries = {};

  /// Writes both the patient aggregate and its summary atomically.
  void save(PatientResponse patient, PatientSummaryResponse summary) {
    patients[patient.patientId] = patient;
    summaries[patient.patientId] = summary;
  }

  /// Returns the stored patient by id, or `null` if not found.
  ///
  /// Returns the same reference that was stored — callers can rely on
  /// `identical(store.save(p), store.get(p.patientId))`.
  PatientResponse? get(String id) => patients[id];

  /// Snapshot of every summary currently stored.
  List<PatientSummaryResponse> listSummaries() => summaries.values.toList();

  /// Resets the store between tests.
  void clear() {
    patients.clear();
    summaries.clear();
  }
}
