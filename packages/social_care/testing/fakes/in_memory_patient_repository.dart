import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';

/// In-memory [PatientRepository] for testing.
///
/// Stores patients in a simple map, providing predictable behavior
/// without requiring any infrastructure dependency.
class InMemoryPatientRepository implements PatientRepository {
  final Map<String, Patient> _store = {};

  /// All patients currently stored.
  List<Patient> get patients => _store.values.toList();

  /// Clears all stored patients.
  void clear() => _store.clear();

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) async {
    _store[patient.id.value] = patient;
    return Success(patient.id);
  }

  @override
  Future<Result<Patient>> getPatient(PatientId id) async {
    final patient = _store[id.value];
    if (patient != null) return Success(patient);
    return Failure(
      AppError(
        code: 'PAT-404',
        message: 'Patient not found: ${id.value}',
        module: 'social-care/test',
        kind: 'notFound',
        http: 404,
        observability: const Observability(
          category: ErrorCategory.domainRuleViolation,
          severity: ErrorSeverity.warning,
        ),
      ),
    );
  }

  @override
  Future<Result<Patient>> getPatientByPersonId(PersonId personId) async {
    try {
      final patient = _store.values.firstWhere(
        (p) => p.personId == personId,
      );
      return Success(patient);
    } catch (_) {
      return Failure(
        AppError(
          code: 'PAT-404',
          message: 'Patient not found for person: ${personId.value}',
          module: 'social-care/test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.domainRuleViolation,
            severity: ErrorSeverity.warning,
          ),
        ),
      );
    }
  }
}
