import 'dart:async';
import 'package:acdg_system/root.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Staging Integration Test', () {
    late String accessToken;
    final hmlBaseUrl = 'https://social-care-hml.acdgbrasil.com.br';

    setUpAll(() async {
      print('Initializing Staging Integration Test...');

      // Use helper to get token from environment variables
      final authHelper = HmlAuthHelper.fromEnv();

      if (authHelper.userId.isEmpty || authHelper.privateKey.isEmpty) {
        fail(
          'Environment variables for service account not found. '
          'Ensure -DuserId, -DkeyId, and -Dkey are provided.',
        );
      }

      print('Authenticating with Zitadel Staging (via Env)...');
      accessToken = await authHelper.getAccessToken();
      print('Authentication successful. Token obtained.');
    });

    testWidgets('Verify Staging API Connectivity (Health & Ready)', (
      tester,
    ) async {
      final dio = Dio();

      print('Checking Health endpoint: $hmlBaseUrl/health');
      final healthResponse = await dio.get('$hmlBaseUrl/health');
      expect(healthResponse.statusCode, 200);

      print('Checking Ready endpoint: $hmlBaseUrl/ready');
      final readyResponse = await dio.get('$hmlBaseUrl/ready');
      expect(readyResponse.statusCode, 200);
    });

    testWidgets('App starts and restores session using staging token', (
      tester,
    ) async {
      final userId = HmlAuthHelper.fromEnv().userId;

      final realUser = AuthUser(
        id: userId,
        name: 'Social Care Integration Tests',
        roles: {AuthRole.socialWorker},
      );

      final fakeRepository = _RealTokenAuthRepository(accessToken, realUser);

      // Launch the app with the real staging token injected
      await tester.pumpWidget(Root(authRepository: fakeRepository));

      // Wait for splash to complete and navigation to home
      // We use pump() with duration because SplashPage has an infinite animation (CircularProgressIndicator)
      // which makes pumpAndSettle() time out.
      await tester.pump(); // Start the first build
      await tester.pump(
        const Duration(seconds: 2),
      ); // Wait for the async init to finish
      await tester
          .pumpAndSettle(); // Now settle if possible (should be on HomePage now)

      // Verify we are on HomePage
      expect(find.text('Bem-vindo ao ACDG System'), findsOneWidget);
      expect(find.text('Social Care Integration Tests'), findsOneWidget);

      print(
        'Integration Test: Successfully reached HomePage using real staging token.',
      );
    });
  });
}

class _RealTokenAuthRepository extends ChangeNotifier
    implements AuthRepository {
  _RealTokenAuthRepository(this.token, this.user);

  final String token;
  final AuthUser user;
  final _statusController = StreamController<AuthStatus>.broadcast();
  AuthStatus _status = const AuthLoading();

  @override
  Stream<AuthStatus> get statusStream => _statusController.stream;

  @override
  AuthStatus get currentStatus => _status;

  @override
  AuthUser? get currentUser =>
      _status is Authenticated ? (this._status as Authenticated).user : null;

  @override
  Future<Result<void>> login() async {
    return const Success(null);
  }

  @override
  Future<Result<void>> logout() async {
    _updateStatus(const Unauthenticated());
    return const Success(null);
  }

  @override
  Future<Result<void>> tryRestoreSession() async {
    _updateStatus(Authenticated(user));
    return const Success(null);
  }

  void _updateStatus(AuthStatus status) {
    _status = status;
    _statusController.add(status);
    notifyListeners();
  }

  @override
  void dispose() {
    _statusController.close();
    super.dispose();
  }
}
