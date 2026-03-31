import 'package:core/core.dart';
import 'package:shared/shared.dart';

/// Pure wrapper for patient-related BFF calls.
///
/// No logic — just forwards calls and returns raw results.
class PatientService {
  PatientService({required SocialCareContract bff}) : _bff = bff;

  final SocialCareContract _bff;

  Future<Result<List<Map<String, dynamic>>>> listPatients() {
    return _bff.listPatients();
  }

  Future<Result<Patient>> getPatient(PatientId id) {
    return _bff.getPatient(id);
  }
}
