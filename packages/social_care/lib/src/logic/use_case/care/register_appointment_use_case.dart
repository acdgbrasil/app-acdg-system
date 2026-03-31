import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/intervention_intents.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../mappers/intervention_mapper.dart';

/// UseCase to register a social care appointment.
class RegisterAppointmentUseCase
    extends BaseUseCase<RegisterAppointmentIntent, AppointmentId> {
  RegisterAppointmentUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<AppointmentId>> execute(
    RegisterAppointmentIntent intent,
  ) async {
    final domainRes = InterventionMapper.toAppointment(intent);
    if (domainRes case Failure(:final error)) return Failure(error);

    return _patientRepository.registerAppointment(
      intent.patientId,
      (domainRes as Success<SocialCareAppointment>).value,
    );
  }
}
