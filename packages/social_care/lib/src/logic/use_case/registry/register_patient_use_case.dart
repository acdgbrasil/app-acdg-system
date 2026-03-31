import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/register_patient_intent.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../domain/errors/social_care_errors.dart';
import '../../mappers/registry_mapper.dart';

/// Orchestrates the registration of a new patient.
class RegisterPatientUseCase
    extends BaseUseCase<RegisterPatientIntent, PatientId> {
  RegisterPatientUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<PatientId>> execute(RegisterPatientIntent intent) async {
    try {
      // 1. Domain Assembly via specialized Mapper
      final patientRes = RegistryMapper.toPatient(intent);

      if (patientRes case Failure(:final error)) {
        return Failure(_mapDomainError(error));
      }

      final patient = (patientRes as Success<Patient>).value;

      // 2. Persistence
      final result = await _patientRepository.registerPatient(patient);

      return result.mapFailure(
        (error) => switch (error) {
          AppError(code: 'PAT-409') => const DuplicatePatientError(),
          _ => _mapDomainError(error),
        },
      );
    } catch (e) {
      return Failure(UnexpectedSocialCareError(e));
    }
  }

  SocialCareError _mapDomainError(Object error) {
    if (error is AppError) {
      return switch (error.code) {
        'VAL-001' => InvalidDataError(error.message),
        'PAT-409' => const DuplicatePatientError(),
        'PAT-003' => InvalidDataError(error.message),
        'PAT-008' => const PrMemberRequiredError(),
        'PAT-009' => const MultiplePrimaryReferencesError(),
        _ => NetworkSocialCareError(error.toString()),
      };
    }
    return UnexpectedSocialCareError(error);
  }
}
