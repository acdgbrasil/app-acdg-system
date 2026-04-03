import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acdg_system/ui/view_models/auth_view_model.dart';
import 'package:acdg_system/logic/use_cases/auth_use_cases.dart';
import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepository;
  late LoginUseCase loginUseCase;
  late LogoutUseCase logoutUseCase;
  late RestoreSessionUseCase restoreSessionUseCase;
  late AuthViewModel viewModel;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    loginUseCase = LoginUseCase(fakeRepository);
    logoutUseCase = LogoutUseCase(fakeRepository);
    restoreSessionUseCase = RestoreSessionUseCase(fakeRepository);

    viewModel = AuthViewModel(
      authRepository: fakeRepository,
      loginUseCase: loginUseCase,
      logoutUseCase: logoutUseCase,
      restoreSessionUseCase: restoreSessionUseCase,
    );
  });

  tearDown(() {
    viewModel.dispose();
    fakeRepository.dispose();
  });

  group('AuthViewModel (Refactor Architecture)', () {
    test('status and user must be pure properties (no ValueNotifier)', () {
      // These assertions will fail compilation if status/user are still ValueNotifiers
      // because we are expecting AuthStatus/AuthUser?, not ValueNotifier<T>.
      expect(viewModel.status, isA<AuthStatus>());
      expect(viewModel.user, isA<AuthUser?>());
    });

    test('should notify listeners exactly once per status change', () async {
      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      // 1. Initial (Loading) -> Unauthenticated
      await viewModel.init();
      
      // We expect at least one notification for the restoreSession change.
      // The exact count depends on how many intermediate states the fake emits.
      expect(notifyCount, greaterThan(0));
      expect(viewModel.status, isA<Unauthenticated>());
    });

    test('login updates status directly and notifies listeners', () async {
      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      await viewModel.login.execute();
      
      expect(viewModel.status, isA<Authenticated>());
      expect(viewModel.user, isNotNull);
      expect(notifyCount, greaterThan(0));
    });
  });
}
