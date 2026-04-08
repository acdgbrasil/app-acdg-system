import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/register_patient_intent.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../domain/errors/social_care_errors.dart';
import '../../mappers/registry_mapper.dart';

/// Orchestrates the registration of a new patient.
///
/// Error mapping is split between layers:
/// - **HttpSocialCareClient**: maps HTTP responses to [SocialCareError]
///   using backend error codes from the contract.
/// - **This UseCase**: maps domain assembly errors (from [RegistryMapper])
///   and propagates repository errors as-is (already typed).
class RegisterPatientUseCase
    extends BaseUseCase<RegisterPatientIntent, PatientId> {
  RegisterPatientUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  static final _log = AcdgLogger.get('RegisterPatientUseCase');
  final PatientRepository _patientRepository;

  @override
  Future<Result<PatientId>> execute(RegisterPatientIntent intent) async {
    try {
      // 1. Domain Assembly via specialized Mapper
      final patientRes = RegistryMapper.toPatient(intent);

      if (patientRes case Failure(:final error)) {
        _log.warning('Domain assembly failed: $error');
        return Failure(_mapAssemblyError(error));
      }

      final patient = (patientRes as Success<Patient>).value;

      // 2. Persistence
      // Web path: errors are already SocialCareError from HttpSocialCareClient.
      // Desktop path: errors may still be raw AppError from OfflineFirstRepository.
      final result = await _patientRepository.registerPatient(patient);

      return result.mapFailure(
        (error) => switch (error) {
          SocialCareError() => error,
          AppError(code: 'PAT-409') ||
          AppError(code: 'REGP-001') => const DuplicatePatientError(),
          AppError(code: 'PAT-008') => const PrMemberRequiredError(),
          AppError(code: 'PAT-009') => const MultiplePrimaryReferencesError(),
          AppError() => InvalidDataError(error.message),
          _ => UnexpectedSocialCareError(error),
        },
      );
    } catch (e, st) {
      _log.severe('Unexpected error during patient registration', e, st);
      return Failure(UnexpectedSocialCareError(e));
    }
  }

  /// Maps domain assembly errors (RegistryMapper / VO creation) to
  /// [SocialCareError]. These are local validation failures, not
  /// backend responses.
  SocialCareError _mapAssemblyError(Object error) {
    if (error is AppError) {
      return switch (error.code) {
        'PAT-008' => const PrMemberRequiredError(),
        'PAT-009' => const MultiplePrimaryReferencesError(),
        _ => InvalidDataError(error.message),
      };
    }
    return UnexpectedSocialCareError(error);
  }
}
