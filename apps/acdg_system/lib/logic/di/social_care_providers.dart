import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_care/social_care.dart';

import 'infrastructure_providers.dart';

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService(bff: ref.watch(socialCareContractProvider));
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return BffPatientRepository(
    bff: ref.watch(socialCareContractProvider),
    patientService: ref.watch(patientServiceProvider),
  );
});

final lookupRepositoryProvider = Provider<LookupRepository>((ref) {
  return BffLookupRepository(bff: ref.watch(socialCareContractProvider));
});

final registerPatientUseCaseProvider = Provider<RegisterPatientUseCase>((ref) {
  return RegisterPatientUseCase(
    patientRepository: ref.watch(patientRepositoryProvider),
  );
});

final getPatientUseCaseProvider = Provider<GetPatientUseCase>((ref) {
  return GetPatientUseCase(
    patientRepository: ref.watch(patientRepositoryProvider),
  );
});

final listPatientsUseCaseProvider = Provider<ListPatientsUseCase>((ref) {
  return ListPatientsUseCase(
    patientRepository: ref.watch(patientRepositoryProvider),
  );
});

final addFamilyMemberUseCaseProvider = Provider<AddFamilyMemberUseCase>((ref) {
  return AddFamilyMemberUseCase(
    patientRepository: ref.watch(patientRepositoryProvider),
  );
});

final removeFamilyMemberUseCaseProvider = Provider<RemoveFamilyMemberUseCase>((
  ref,
) {
  return RemoveFamilyMemberUseCase(
    patientRepository: ref.watch(patientRepositoryProvider),
  );
});

final updatePrimaryCaregiverUseCaseProvider =
    Provider<UpdatePrimaryCaregiverUseCase>((ref) {
      return UpdatePrimaryCaregiverUseCase(
        patientRepository: ref.watch(patientRepositoryProvider),
      );
    });

final updateSocialIdentityUseCaseProvider =
    Provider<UpdateSocialIdentityUseCase>((ref) {
      return UpdateSocialIdentityUseCase(
        patientRepository: ref.watch(patientRepositoryProvider),
      );
    });

/// Override for the [patientRegistrationViewModelProvider] stub in social_care.
/// Wires the ViewModel with the shell's use case and repository providers.
final patientRegistrationViewModelOverride =
    patientRegistrationViewModelProvider.overrideWith((ref) {
      final vm = PatientRegistrationViewModel(
        useCase: ref.watch(registerPatientUseCaseProvider),
        lookupRepository: ref.watch(lookupRepositoryProvider),
      );
      ref.onDispose(() => vm.dispose());
      return vm;
    });

/// Override for the [familyCompositionViewModelProvider] stub in social_care.
/// Wires the ViewModel with the shell's use case providers.
final familyCompositionViewModelOverride = familyCompositionViewModelProvider
    .overrideWith((ref, patientId) {
      final contract = ref.watch(socialCareContractProvider);
      final cpfLookup = contract is HttpSocialCareClient
          ? contract.lookupPersonByCpf
          : null;

      final vm = FamilyCompositionViewModel(
        patientId: patientId,
        getPatientUseCase: ref.watch(getPatientUseCaseProvider),
        addFamilyMemberUseCase: ref.watch(addFamilyMemberUseCaseProvider),
        removeFamilyMemberUseCase: ref.watch(removeFamilyMemberUseCaseProvider),
        updatePrimaryCaregiverUseCase: ref.watch(
          updatePrimaryCaregiverUseCaseProvider,
        ),
        updateSocialIdentityUseCase: ref.watch(
          updateSocialIdentityUseCaseProvider,
        ),
        lookupRepository: ref.watch(lookupRepositoryProvider),
        cpfLookupFn: cpfLookup,
      );
      ref.onDispose(() => vm.dispose());
      return vm;
    });

final updateIntakeInfoUseCaseProvider = Provider<UpdateIntakeInfoUseCase>((
  ref,
) {
  return UpdateIntakeInfoUseCase(
    patientRepository: ref.watch(patientRepositoryProvider),
  );
});

/// Override for the [intakeInfoViewModelProvider] stub in social_care.
/// Wires the ViewModel with the shell's use case providers.
final intakeInfoViewModelOverride = intakeInfoViewModelProvider
    .overrideWith((ref, patientId) {
      final vm = IntakeInfoViewModel(
        patientId: patientId,
        getPatientUseCase: ref.watch(getPatientUseCaseProvider),
        updateIntakeInfoUseCase: ref.watch(updateIntakeInfoUseCaseProvider),
        lookupRepository: ref.watch(lookupRepositoryProvider),
      );
      ref.onDispose(() => vm.dispose());
      return vm;
    });

/// Override for the [homeViewModelProvider] stub in social_care.
/// Wires the ViewModel with the shell's use case providers.
final homeViewModelOverride = homeViewModelProvider.overrideWith((ref) {
  final vm = HomeViewModel(
    listPatientsUseCase: ref.watch(listPatientsUseCaseProvider),
    getPatientUseCase: ref.watch(getPatientUseCaseProvider),
  );
  ref.onDispose(() => vm.dispose());
  return vm;
});
