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

final updateSocioEconomicUseCaseProvider = Provider<UpdateSocioEconomicUseCase>((ref) => UpdateSocioEconomicUseCase(patientRepository: ref.watch(patientRepositoryProvider)));
final socioEconomicViewModelOverride = socioEconomicViewModelProvider.overrideWith((ref, patientId) {
  final vm = SocioEconomicViewModel(patientId: patientId, getPatientUseCase: ref.watch(getPatientUseCaseProvider), updateSocioEconomicUseCase: ref.watch(updateSocioEconomicUseCaseProvider));
  ref.onDispose(() => vm.dispose()); return vm;
});

final updateEducationalStatusUseCaseProvider = Provider<UpdateEducationalStatusUseCase>((ref) => UpdateEducationalStatusUseCase(patientRepository: ref.watch(patientRepositoryProvider)));
final educationalStatusViewModelOverride = educationalStatusViewModelProvider.overrideWith((ref, patientId) {
  final vm = EducationalStatusViewModel(patientId: patientId, getPatientUseCase: ref.watch(getPatientUseCaseProvider), updateEducationalStatusUseCase: ref.watch(updateEducationalStatusUseCaseProvider), lookupRepository: ref.watch(lookupRepositoryProvider));
  ref.onDispose(() => vm.dispose()); return vm;
});

final updateWorkAndIncomeUseCaseProvider = Provider<UpdateWorkAndIncomeUseCase>((ref) => UpdateWorkAndIncomeUseCase(patientRepository: ref.watch(patientRepositoryProvider)));
final workAndIncomeViewModelOverride = workAndIncomeViewModelProvider.overrideWith((ref, patientId) {
  final vm = WorkAndIncomeViewModel(patientId: patientId, getPatientUseCase: ref.watch(getPatientUseCaseProvider), updateWorkAndIncomeUseCase: ref.watch(updateWorkAndIncomeUseCaseProvider), lookupRepository: ref.watch(lookupRepositoryProvider));
  ref.onDispose(() => vm.dispose()); return vm;
});

final reportViolationUseCaseProvider = Provider<ReportViolationUseCase>((ref) => ReportViolationUseCase(patientRepository: ref.watch(patientRepositoryProvider)));
final violationReportViewModelOverride = violationReportViewModelProvider.overrideWith((ref, patientId) {
  final vm = ViolationReportViewModel(patientId: patientId, getPatientUseCase: ref.watch(getPatientUseCaseProvider), reportViolationUseCase: ref.watch(reportViolationUseCaseProvider));
  ref.onDispose(() => vm.dispose()); return vm;
});

final socialIdentityViewModelOverride = socialIdentityViewModelProvider.overrideWith((ref, patientId) {
  final vm = SocialIdentityViewModel(patientId: patientId, getPatientUseCase: ref.watch(getPatientUseCaseProvider), updateSocialIdentityUseCase: ref.watch(updateSocialIdentityUseCaseProvider), lookupRepository: ref.watch(lookupRepositoryProvider));
  ref.onDispose(() => vm.dispose()); return vm;
});

final updateCommunitySupportUseCaseProvider =
    Provider<UpdateCommunitySupportUseCase>((ref) {
      return UpdateCommunitySupportUseCase(
        patientRepository: ref.watch(patientRepositoryProvider),
      );
    });

final communitySupportViewModelOverride = communitySupportViewModelProvider
    .overrideWith((ref, patientId) {
      final vm = CommunitySupportViewModel(
        patientId: patientId,
        getPatientUseCase: ref.watch(getPatientUseCaseProvider),
        updateCommunitySupportUseCase: ref.watch(
          updateCommunitySupportUseCaseProvider,
        ),
      );
      ref.onDispose(() => vm.dispose());
      return vm;
    });

final updateHealthStatusUseCaseProvider =
    Provider<UpdateHealthStatusUseCase>((ref) {
      return UpdateHealthStatusUseCase(
        patientRepository: ref.watch(patientRepositoryProvider),
      );
    });

/// Override for the [healthStatusViewModelProvider] stub in social_care.
final healthStatusViewModelOverride = healthStatusViewModelProvider
    .overrideWith((ref, patientId) {
      final vm = HealthStatusViewModel(
        patientId: patientId,
        getPatientUseCase: ref.watch(getPatientUseCaseProvider),
        updateHealthStatusUseCase: ref.watch(updateHealthStatusUseCaseProvider),
        lookupRepository: ref.watch(lookupRepositoryProvider),
      );
      ref.onDispose(() => vm.dispose());
      return vm;
    });

final updateHousingConditionUseCaseProvider =
    Provider<UpdateHousingConditionUseCase>((ref) {
      return UpdateHousingConditionUseCase(
        patientRepository: ref.watch(patientRepositoryProvider),
      );
    });

/// Override for the [housingConditionViewModelProvider] stub in social_care.
/// Wires the ViewModel with the shell's use case providers.
final housingConditionViewModelOverride = housingConditionViewModelProvider
    .overrideWith((ref, patientId) {
      final vm = HousingConditionViewModel(
        patientId: patientId,
        getPatientUseCase: ref.watch(getPatientUseCaseProvider),
        updateHousingConditionUseCase: ref.watch(
          updateHousingConditionUseCaseProvider,
        ),
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
