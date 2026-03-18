import 'package:core/core.dart';
import 'package:shared/shared.dart';

import 'patient_repository.dart';

/// [PatientRepository] implementation backed by the Social Care BFF.
///
/// Delegates all operations to [SocialCareContract], which already
/// handles offline-first coordination (OfflineFirstRepository) or
/// direct remote calls depending on the platform.
class BffPatientRepository implements PatientRepository {
  BffPatientRepository({required SocialCareContract bff}) : _bff = bff;

  final SocialCareContract _bff;

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) {
    return _bff.registerPatient(patient);
  }

  @override
  Future<Result<Patient>> getPatient(PatientId id) {
    return _bff.getPatient(id);
  }

  @override
  Future<Result<Patient>> getPatientByPersonId(PersonId personId) {
    return _bff.getPatientByPersonId(personId);
  }
}
