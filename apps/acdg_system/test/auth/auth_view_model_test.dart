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

  group('AuthViewModel (Layered)', () {
    test('initial status is AuthLoading', () {
      expect(viewModel.status, isA<AuthLoading>());
    });

    test('init calls restoreSessionUseCase', () async {
      await viewModel.init();
      expect(viewModel.restoreSession.completed, isTrue);
    });

    test('login calls loginUseCase and updates status', () async {
      await viewModel.login.execute();
      expect(viewModel.status, isA<Authenticated>());
    });

    test('logout calls logoutUseCase and clears status', () async {
      await viewModel.login.execute();
      await viewModel.logout.execute();
      expect(viewModel.status, isA<Unauthenticated>());
    });
  });
}
