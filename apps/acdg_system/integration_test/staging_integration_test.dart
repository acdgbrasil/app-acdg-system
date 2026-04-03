import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:acdg_system/root.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/social_care_desktop.dart';
import 'package:dio/dio.dart';

String generateValidCpf() {
  final random = DateTime.now().millisecondsSinceEpoch.toString();
  final base = random
      .substring(random.length - 9)
      .split('')
      .map(int.parse)
      .toList();

  int sum1 = 0;
  for (int i = 0; i < 9; i++) {
    sum1 += base[i] * (10 - i);
  }
  int rem1 = sum1 % 11;
  int d1 = (rem1 < 2) ? 0 : 11 - rem1;
  base.add(d1);

  int sum2 = 0;
  for (int i = 0; i < 10; i++) {
    sum2 += base[i] * (11 - i);
  }
  int rem2 = sum2 % 11;
  int d2 = (rem2 < 2) ? 0 : 11 - rem2;
  base.add(d2);

  return base.join('');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Staging Integration Test', () {
    late String accessToken;
    late String userId;
    final hmlBaseUrl = 'https://social-care-hml.acdgbrasil.com.br';
    final log = AcdgLogger.get('StagingIntegrationTest');

    setUpAll(() async {
      log.info('Initializing Staging Integration Test...');

      HmlAuthHelper? authHelper;

      // 1. Try from Environment Variables
      final envHelper = HmlAuthHelper.fromEnv();
      if (envHelper.userId.isNotEmpty && envHelper.privateKey.isNotEmpty) {
        authHelper = envHelper;
      } else {
        // 2. Try from Local JSON file (Relative to workspace root or app root)
        final paths = [
          '../../json/svc-hml-tests.json', // From apps/acdg_system
          'json/svc-hml-tests.json', // From workspace root
          '../../../json/svc-hml-tests.json', // From deep nested test run
        ];

        log.info('Current directory: ${Directory.current.path}');

        for (final path in paths) {
          final file = File(path);
          if (file.existsSync()) {
            log.info('Loading credentials from ${file.absolute.path}...');
            authHelper = HmlAuthHelper.fromJson(file.readAsStringSync());
            break;
          }
        }
      }

      if (authHelper == null) {
        fail(
          'Credentials not found. Set environment variables or provide json/svc-hml-tests.json',
        );
      }

      userId = authHelper.userId;
      log.info('Authenticating with Zitadel Staging...');
      accessToken = await authHelper.getAccessToken();
      log.info('Authentication successful. Using Actor ID (userId): $userId');
    });

    testWidgets('Verify Staging API Connectivity (Health & Ready)', (
      tester,
    ) async {
      final dio = Dio();
      final healthResponse = await dio.get('$hmlBaseUrl/health');
      expect(healthResponse.statusCode, 200);

      final readyResponse = await dio.get('$hmlBaseUrl/ready');
      expect(readyResponse.statusCode, 200);
    });

    testWidgets('BFF Remote: Register and Get Patient in Staging', (
      tester,
    ) async {
      final bff = SocialCareBffRemote(
        baseUrl: hmlBaseUrl,
        authToken: accessToken,
        actorId: userId,
      );

      log.info('Fetching lookup table: dominio_parentesco...');
      final lookupResult = await bff.getLookupTable('dominio_parentesco');
      if (lookupResult.isFailure) {
        log.severe(
          'Lookup table fetch failed: ${(lookupResult as Failure).error}',
        );
      }
      expect(lookupResult.isSuccess, isTrue);

      final lookups = lookupResult.valueOrNull!;
      final prRelId = LookupId.create(lookups[0].id).valueOrNull!;

      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch
          .toString()
          .padLeft(12, '0')
          .substring(0, 12);

      final personIdRes = PersonId.create(
        '550e8400-e29b-41d4-a716-$uniqueSuffix',
      );
      if (personIdRes.isFailure)
        fail('PersonId creation failed: ${(personIdRes as Failure).error}');
      final personId = personIdRes.valueOrNull!;

      final patientIdRes = PatientId.create(
        '550e8400-e29b-41d4-a716-${uniqueSuffix.replaceAll('0', '1')}',
      );
      if (patientIdRes.isFailure)
        fail('PatientId creation failed: ${(patientIdRes as Failure).error}');
      final patientId = patientIdRes.valueOrNull!;

      final pDataResult = PersonalData.create(
        firstName: 'Integration',
        lastName: 'Test',
        motherName: 'Automation',
        nationality: 'Brazilian',
        sex: Sex.feminino,
        birthDate: TimeStamp.fromIso('1990-01-01T00:00:00.000Z').valueOrNull!,
      );
      if (pDataResult.isFailure)
        fail('PersonalData creation failed: ${(pDataResult as Failure).error}');
      final personalData = pDataResult.valueOrNull!;

      final patient = Patient.reconstitute(
        id: patientId,
        personId: personId,
        prRelationshipId: prRelId,
        version: 1,
        personalData: personalData,
      );

      log.info('Registering patient in staging...');
      final regResult = await bff.registerPatient(patient);
      if (regResult.isFailure) {
        log.severe('Registration failed: ${(regResult as Failure).error}');
      }
      expect(regResult.isSuccess, isTrue);

      log.info('Fetching patient back from staging...');
      final getResult = await bff.fetchPatient(patientId);
      expect(getResult.isSuccess, isTrue);
      expect(getResult.valueOrNull?.patientId, patientId.value);
      log.info('Integration test success: Patient registered and retrieved.');
    });

    testWidgets('Full Root Integration: Staging Connectivity', (tester) async {
      final realUser = AuthUser(
        id: userId,
        name: 'Social Care Integration Tests',
        roles: {AuthRole.socialWorker},
      );

      final fakeRepository = _RealTokenAuthRepository(accessToken, realUser);

      await tester.pumpWidget(Root(authRepository: fakeRepository));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo ao ACDG System'), findsOneWidget);
      expect(find.text('Social Care Integration Tests'), findsOneWidget);
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
      _status is Authenticated ? (_status as Authenticated).user : null;
  @override
  AuthToken? get currentToken => _status is Authenticated
      ? AuthToken(
          accessToken: token,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        )
      : null;
  @override
  Future<Result<void>> login() async => const Success(null);
  @override
  Future<Result<void>> logout() async => const Success(null);
  @override
  Future<void> init() async {}
  @override
  Future<Result<void>> tryRestoreSession() async {
    _status = Authenticated(user);
    _statusController.add(_status);
    notifyListeners();
    return const Success(null);
  }

  @override
  void dispose() {
    _statusController.close();
    super.dispose();
  }
}
