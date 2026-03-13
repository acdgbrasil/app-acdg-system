import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the login flow of [OidcAuthService].
///
/// These tests require a mock/fake [OidcUserManager] to simulate
/// Zitadel responses without real network calls.
///
/// Scenarios to cover:
/// - login() emits AuthLoading immediately
/// - Successful login emits Authenticated with correct user/token
/// - User cancels login in browser → emits Unauthenticated
/// - Network error during login → emits AuthError with message
/// - login() clears stale user/token on failure
void main() {
  group('OidcAuthService — login', () {
    // TODO: Implement when OidcUserManager mock is available.
    //
    // Example test structure:
    //
    // late OidcAuthService service;
    // late MockOidcUserManager mockManager;
    //
    // setUp(() {
    //   mockManager = MockOidcUserManager();
    //   service = OidcAuthService.withManager(manager: mockManager);
    // });
    //
    // test('emits AuthLoading then Authenticated on success', () async {
    //   mockManager.stubLoginSuccess(fakeOidcUser);
    //   await service.login();
    //   expect(service.currentStatus, isA<Authenticated>());
    // });
    //
    // test('emits AuthLoading then Unauthenticated on cancel', () async {
    //   mockManager.stubLoginReturnsNull();
    //   await service.login();
    //   expect(service.currentStatus, isA<Unauthenticated>());
    //   expect(service.currentUser, isNull);
    //   expect(service.currentToken, isNull);
    // });
    //
    // test('emits AuthError on network failure', () async {
    //   mockManager.stubLoginThrows(Exception('network timeout'));
    //   await service.login();
    //   expect(service.currentStatus, isA<AuthError>());
    //   expect(service.currentUser, isNull);
    // });

    test('placeholder — awaiting OidcUserManager mock', () {
      // This test exists to keep the file in the test runner.
      // Replace with real tests when mocks are implemented.
      expect(true, isTrue);
    });
  });
}
