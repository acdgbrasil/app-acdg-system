import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/patient_repository.dart';

/// Command input for patient registration.
///
/// Encapsulates all data required to register a new patient,
/// keeping the UseCase interface clean and extensible.
class RegisterPatientCommand {
  const RegisterPatientCommand({
    required this.patientId,
    required this.personId,
    required this.prRelationshipId,
    required this.personalData,
    required this.diagnoses,
    this.familyMembers = const [],
    this.civilDocuments,
    this.address,
  });

  final PatientId patientId;
  final PersonId personId;
  final LookupId prRelationshipId;
  final PersonalData personalData;
  final List<Diagnosis> diagnoses;
  final List<FamilyMember> familyMembers;
  final CivilDocuments? civilDocuments;
  final Address? address;
}

/// Orchestrates the registration of a new patient.
///
/// Validates domain invariants via [Patient.create], then delegates
/// persistence to the [PatientRepository].
class RegisterPatientUseCase extends BaseUseCase<RegisterPatientCommand, PatientId> {
  RegisterPatientUseCase({required PatientRepository patientRepository})
      : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<PatientId>> execute(RegisterPatientCommand command) async {
    // 1. Build the domain aggregate (validates invariants)
    final patientResult = Patient.create(
      id: command.patientId,
      personId: command.personId,
      prRelationshipId: command.prRelationshipId,
      personalData: command.personalData,
      civilDocuments: command.civilDocuments,
      address: command.address,
      diagnoses: command.diagnoses,
      familyMembers: command.familyMembers,
    );

    // 2. If domain validation fails, propagate the error
    if (patientResult.isFailure) {
      return Failure((patientResult as Failure).error);
    }

    final patient = patientResult.valueOrNull!;

    // 3. Persist via repository
    return _patientRepository.registerPatient(patient);
  }
}
