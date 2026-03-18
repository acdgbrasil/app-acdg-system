import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for session restore and token refresh flows of [OidcAuthService].
///
/// These tests require a mock/fake [OidcUserManager] to simulate
/// Zitadel responses without real network calls.
///
/// Scenarios to cover:
///
/// tryRestoreSession:
/// - Emits Authenticated when cached token exists in storage
/// - Emits Unauthenticated when no cached token
/// - Emits Unauthenticated when cached token is expired and refresh fails
///
/// refreshToken:
/// - Successful refresh updates currentToken and emits Authenticated
/// - Refresh returns null → emits Unauthenticated and clears state
/// - Network error → emits AuthError
/// - Token expiry detection using injectable now (isExpired/expiresWithin)
void main() {
  group('OidcAuthService — session', () {
    // TODO: Implement when OidcUserManager mock is available.
    //
    // Example test structure:
    //
    // group('tryRestoreSession', () {
    //   test('emits Authenticated when cached user exists', () async {
    //     mockManager.stubCurrentUser(fakeOidcUser);
    //     await service.tryRestoreSession();
    //     expect(service.currentStatus, isA<Authenticated>());
    //   });
    //
    //   test('emits Unauthenticated when no cached user', () async {
    //     mockManager.stubCurrentUser(null);
    //     await service.tryRestoreSession();
    //     expect(service.currentStatus, isA<Unauthenticated>());
    //   });
    // });
    //
    // group('refreshToken', () {
    //   test('updates token on success', () async {
    //     mockManager.stubRefreshSuccess(freshOidcUser);
    //     await service.refreshToken();
    //     expect(service.currentToken?.isExpired(), isFalse);
    //   });
    //
    //   test('clears session when refresh returns null', () async {
    //     mockManager.stubRefreshReturnsNull();
    //     await service.refreshToken();
    //     expect(service.currentStatus, isA<Unauthenticated>());
    //   });
    //
    //   test('emits AuthError on network failure', () async {
    //     mockManager.stubRefreshThrows(Exception('offline'));
    //     await service.refreshToken();
    //     expect(service.currentStatus, isA<AuthError>());
    //   });
    // });

    test('placeholder — awaiting OidcUserManager mock', () {
      expect(true, isTrue);
    });
  });
}
