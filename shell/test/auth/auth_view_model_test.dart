import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_raros/auth/auth_view_model.dart';
import 'fake_auth_service.dart';

void main() {
  late FakeAuthService fakeService;
  late AuthViewModel viewModel;

  setUp(() {
    fakeService = FakeAuthService();
    viewModel = AuthViewModel(authService: fakeService);
  });

  tearDown(() {
    viewModel.dispose();
    fakeService.dispose();
  });

  group('AuthViewModel', () {
    group('init', () {
      test('starts with AuthLoading status', () {
        expect(viewModel.status.value, isA<AuthLoading>());
      });

      test('emits Unauthenticated when no existing session', () async {
        await viewModel.init();

        expect(viewModel.status.value, isA<Unauthenticated>());
        expect(viewModel.user.value, isNull);
        expect(viewModel.busy.value, isFalse);
      });

      test('restores session when one exists', () async {
        fakeService.hasExistingSession = true;

        await viewModel.init();

        expect(viewModel.status.value, isA<Authenticated>());
        expect(viewModel.user.value, isNotNull);
        expect(viewModel.user.value!.id, 'test-user-123');
        expect(viewModel.busy.value, isFalse);
      });
    });

    group('login', () {
      test('transitions to Authenticated on success', () async {
        await viewModel.init();

        await viewModel.login();

        expect(viewModel.status.value, isA<Authenticated>());
        final user = viewModel.user.value!;
        expect(user.name, 'Test User');
        expect(user.email, 'test@acdg.com.br');
        expect(user.roles, {AuthRole.socialWorker});
      });

      test('transitions to AuthError on failure', () async {
        await viewModel.init();
        fakeService.loginShouldFail = true;
        fakeService.errorMessage = 'Network timeout';

        await viewModel.login();

        expect(viewModel.status.value, isA<AuthError>());
        expect(
          (viewModel.status.value as AuthError).message,
          'Network timeout',
        );
        expect(viewModel.user.value, isNull);
      });

      test('sets busy during login', () async {
        await viewModel.init();
        final busyStates = <bool>[];
        viewModel.busy.addListener(() => busyStates.add(viewModel.busy.value));

        await viewModel.login();

        expect(busyStates, contains(true));
        expect(viewModel.busy.value, isFalse);
      });

      test('ignores concurrent login calls', () async {
        await viewModel.init();

        // Start login and immediately try another
        final first = viewModel.login();
        final second = viewModel.login(); // should be ignored (busy)

        await Future.wait([first, second]);

        expect(viewModel.status.value, isA<Authenticated>());
      });
    });

    group('logout', () {
      test('transitions to Unauthenticated', () async {
        fakeService.hasExistingSession = true;
        await viewModel.init();
        expect(viewModel.status.value, isA<Authenticated>());

        await viewModel.logout();

        expect(viewModel.status.value, isA<Unauthenticated>());
        expect(viewModel.user.value, isNull);
      });

      test('sets busy during logout', () async {
        fakeService.hasExistingSession = true;
        await viewModel.init();
        final busyStates = <bool>[];
        viewModel.busy.addListener(() => busyStates.add(viewModel.busy.value));

        await viewModel.logout();

        expect(busyStates, contains(true));
        expect(viewModel.busy.value, isFalse);
      });
    });

    group('tryRestoreSession', () {
      test('can be retried manually after init', () async {
        await viewModel.init();
        expect(viewModel.status.value, isA<Unauthenticated>());

        // Simulate session becoming available (e.g., cookie was set)
        fakeService.hasExistingSession = true;
        await viewModel.tryRestoreSession();

        expect(viewModel.status.value, isA<Authenticated>());
      });
    });

    group('notifyListeners', () {
      test('notifies on status change for GoRouter refresh', () async {
        var notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        await viewModel.init();

        expect(notifyCount, greaterThan(0));
      });

      test('does not notify after dispose', () async {
        // Create a separate instance to avoid double-dispose in tearDown
        final service = FakeAuthService();
        final vm = AuthViewModel(authService: service);
        await vm.init();

        var notifiedAfterDispose = false;
        vm.addListener(() => notifiedAfterDispose = true);
        vm.dispose();

        expect(vm.disposed, isTrue);

        // Emit on the stream — should not reach the disposed VM
        service.dispose();
        expect(notifiedAfterDispose, isFalse);
      });
    });
  });
}
