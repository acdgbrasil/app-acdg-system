import 'package:core/core.dart';
import 'package:shared/shared.dart';

/// Repository contract for Patient-related operations.
///
/// Abstracts how patient data is fetched and persisted,
/// allowing the UseCase layer to remain agnostic of infrastructure.
abstract class PatientRepository {
  /// Registers a new patient. Returns the generated [PatientId].
  Future<Result<PatientId>> registerPatient(Patient patient);

  /// Retrieves a patient by their unique [id].
  Future<Result<Patient>> getPatient(PatientId id);

  /// Retrieves a patient by their associated [personId].
  Future<Result<Patient>> getPatientByPersonId(PersonId personId);
}
