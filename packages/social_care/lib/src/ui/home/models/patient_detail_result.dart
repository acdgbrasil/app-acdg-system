import 'ficha_status.dart';
import 'patient_detail.dart';

/// Bundles the patient detail and ficha status for a single getPatient call.
final class PatientDetailResult {
  final PatientDetail patientDetail;
  final List<FichaStatus> fichas;

  const PatientDetailResult({
    required this.patientDetail,
    required this.fichas,
  });
}
