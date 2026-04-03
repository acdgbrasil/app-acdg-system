import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../use_cases/auth_use_cases.dart';
import '../../ui/view_models/auth_view_model.dart';
import 'dependency_manager.dart';

/// Bridges the [AppDependencyManager] into Riverpod by exposing the
/// already-initialized [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ref.watch(appDependencyManagerProvider).authRepository;
});

/// Provides a [LoginUseCase] wired to the current [AuthRepository].
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

/// Provides a [LogoutUseCase] wired to the current [AuthRepository].
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

/// Provides a [RestoreSessionUseCase] wired to the current [AuthRepository].
final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  return RestoreSessionUseCase(ref.watch(authRepositoryProvider));
});

/// Provides the [AuthViewModel] as a singleton managed by Riverpod.
final authViewModelProvider = Provider<AuthViewModel>((ref) {
  final vm = AuthViewModel(
    authRepository: ref.watch(authRepositoryProvider),
    loginUseCase: ref.watch(loginUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    restoreSessionUseCase: ref.watch(restoreSessionUseCaseProvider),
  );
  
  // Ensure the VM is disposed when the provider is destroyed
  ref.onDispose(() => vm.dispose());
  return vm;
});

/// A provider that ensures [AuthViewModel.init] is called exactly once.
/// Use this in the Splash or Root to await initialization.
final authInitializationProvider = FutureProvider<void>((ref) async {
  final vm = ref.watch(authViewModelProvider);
  await vm.init();
});

/// Provides the [AppRouter] wired with the Riverpod-managed [AuthViewModel].
final appRouterProvider = Provider<AppRouter>((ref) {
  final authVM = ref.watch(authViewModelProvider);
  return AppRouter(authViewModel: authVM);
});

/// Exposes the [AppDependencyManager] so Riverpod providers can read
/// dependencies that haven't been migrated yet.
///
/// Override this in the [ProviderScope] at the root with the real instance.
final appDependencyManagerProvider = Provider<AppDependencyManager>((ref) {
  throw UnimplementedError(
    'appDependencyManagerProvider must be overridden in ProviderScope',
  );
});
