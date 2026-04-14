import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:people_admin/people_admin.dart';

// ── Service ──

final peopleAdminClientProvider = Provider<PeopleAdminClient>((ref) {
  return PeopleAdminClient(baseUrl: Env.bffBaseUrl);
});

// ── Repositories ──

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  return BffPeopleRepository(client: ref.watch(peopleAdminClientProvider));
});

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return BffRoleRepository(client: ref.watch(peopleAdminClientProvider));
});

// ── Use Cases ──

final searchPeopleUseCaseProvider = Provider<SearchPeopleUseCase>((ref) {
  return SearchPeopleUseCase(
    peopleRepository: ref.watch(peopleRepositoryProvider),
  );
});

final getPersonUseCaseProvider = Provider<GetPersonUseCase>((ref) {
  return GetPersonUseCase(
    peopleRepository: ref.watch(peopleRepositoryProvider),
  );
});

final togglePersonStatusUseCaseProvider =
    Provider<TogglePersonStatusUseCase>((ref) {
  return TogglePersonStatusUseCase(
    peopleRepository: ref.watch(peopleRepositoryProvider),
  );
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(
    peopleRepository: ref.watch(peopleRepositoryProvider),
  );
});

final registerWorkerUseCaseProvider = Provider<RegisterWorkerUseCase>((ref) {
  return RegisterWorkerUseCase(
    peopleRepository: ref.watch(peopleRepositoryProvider),
  );
});

final manageRolesUseCaseProvider = Provider<ManageRolesUseCase>((ref) {
  return ManageRolesUseCase(
    roleRepository: ref.watch(roleRepositoryProvider),
  );
});

// ── ViewModel Overrides ──

final peopleListViewModelOverride =
    peopleListViewModelProvider.overrideWith((ref) {
  final vm = PeopleListViewModel(
    searchPeopleUseCase: ref.watch(searchPeopleUseCaseProvider),
    registerWorkerUseCase: ref.watch(registerWorkerUseCaseProvider),
  );
  ref.onDispose(() => vm.dispose());
  return vm;
});

final personDetailViewModelOverride =
    personDetailViewModelProvider.overrideWith((ref) {
  final vm = PersonDetailViewModel(
    getPersonUseCase: ref.watch(getPersonUseCaseProvider),
    togglePersonStatusUseCase: ref.watch(togglePersonStatusUseCaseProvider),
    resetPasswordUseCase: ref.watch(resetPasswordUseCaseProvider),
    manageRolesUseCase: ref.watch(manageRolesUseCaseProvider),
  );
  ref.onDispose(() => vm.dispose());
  return vm;
});
