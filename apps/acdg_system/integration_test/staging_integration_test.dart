import 'dart:async';
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
  final base = random.substring(random.length - 9).split('').map(int.parse).toList();
  
  int sum1 = 0;
  for (int i = 0; i < 9; i++) sum1 += base[i] * (10 - i);
  int rem1 = sum1 % 11;
  int d1 = (rem1 < 2) ? 0 : 11 - rem1;
  base.add(d1);

  int sum2 = 0;
  for (int i = 0; i < 10; i++) sum2 += base[i] * (11 - i);
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

    setUpAll(() async {
      print('Initializing Staging Integration Test...');
      
      final authHelper = HmlAuthHelper.fromEnv();
      if (authHelper.userId.isEmpty || authHelper.privateKey.isEmpty) {
        fail('Environment variables for service account not found.');
      }
      
      userId = authHelper.userId;
      print('Authenticating with Zitadel Staging...');
      accessToken = await authHelper.getAccessToken();
      print('Authentication successful. Using Actor ID (userId): $userId');
    });

    testWidgets('Verify Staging API Connectivity (Health & Ready)', (tester) async {
      final dio = Dio();
      final healthResponse = await dio.get('$hmlBaseUrl/health');
      expect(healthResponse.statusCode, 200);
      
      final readyResponse = await dio.get('$hmlBaseUrl/ready');
      expect(readyResponse.statusCode, 200);
    });

    testWidgets('BFF Remote: Register and Get Patient in Staging', (tester) async {
      final bff = SocialCareBffRemote(
        baseUrl: hmlBaseUrl,
        authToken: accessToken,
        actorId: userId, // Correct Actor ID (Machine User)
      );

      print('Fetching lookup table: dominio_parentesco...');
      final lookupResult = await bff.getLookupTable('dominio_parentesco');
      if (lookupResult.isFailure) {
        print('Lookup table fetch failed: ${(lookupResult as Failure).error}');
      }
      expect(lookupResult.isSuccess, isTrue);
      final prRelId = LookupId.create(lookupResult.valueOrNull!.first.id).valueOrNull!;
      print('Using relationship ID: ${prRelId.value} (${lookupResult.valueOrNull!.first.descricao})');

      // 1. Prepare a Patient model with valid VOs
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12);
      
      final personIdRes = PersonId.create('550e8400-e29b-41d4-a716-$uniqueSuffix');
      if (personIdRes.isFailure) fail('PersonId creation failed: ${(personIdRes as Failure).error}');
      final personId = personIdRes.valueOrNull!;

      final patientIdRes = PatientId.create('550e8400-e29b-41d4-a716-${uniqueSuffix.replaceAll('0', '1')}');
      if (patientIdRes.isFailure) fail('PatientId creation failed: ${(patientIdRes as Failure).error}');
      final patientId = patientIdRes.valueOrNull!;
      
      final pDataResult = PersonalData.create(
        firstName: 'Integration',
        lastName: 'Test',
        motherName: 'Automation',
        nationality: 'Brazilian',
        sex: Sex.feminino,
        birthDate: TimeStamp.fromIso('1990-01-01T00:00:00.000Z').valueOrNull!,
      );
      if (pDataResult.isFailure) fail('PersonalData creation failed: ${(pDataResult as Failure).error}');
      final personalData = pDataResult.valueOrNull!;

      final icdResult = IcdCode.create('B20');
      if (icdResult.isFailure) fail('IcdCode creation failed: ${(icdResult as Failure).error}');
      
      final diagResult = Diagnosis.create(
        id: icdResult.valueOrNull!,
        date: TimeStamp.now,
        description: 'Initial diagnosis from integration test',
      );
      if (diagResult.isFailure) fail('Diagnosis creation failed: ${(diagResult as Failure).error}');
      final diagnoses = [diagResult.valueOrNull!];

      final cepRes = Cep.create('01001000');
      if (cepRes.isFailure) fail('Cep creation failed: ${(cepRes as Failure).error}');

      final addrResult = Address.create(
        cep: cepRes.valueOrNull!,
        state: 'SP',
        city: 'São Paulo',
        street: 'Praça da Sé',
        neighborhood: 'Sé',
        number: '1',
        residenceLocation: ResidenceLocation.urbano,
        isShelter: false,
      );
      if (addrResult.isFailure) fail('Address creation failed: ${(addrResult as Failure).error}');

      final cpfRes = Cpf.create(generateValidCpf());
      if (cpfRes.isFailure) fail('Cpf creation failed: ${(cpfRes as Failure).error}');

      final civilDocsRes = CivilDocuments.create(
        cpf: cpfRes.valueOrNull!,
      );
      if (civilDocsRes.isFailure) fail('CivilDocuments creation failed: ${(civilDocsRes as Failure).error}');

      final familyMemberRes = FamilyMember.create(
        personId: personId,
        relationshipId: prRelId,
        residesWithPatient: true,
        requiredDocuments: [RequiredDocument.cpf],
        birthDate: personalData.birthDate,
      );
      if (familyMemberRes.isFailure) fail('FamilyMember creation failed: ${(familyMemberRes as Failure).error}');

      final patientResult = Patient.create(
        id: patientId,
        personId: personId,
        personalData: personalData,
        civilDocuments: civilDocsRes.valueOrNull!,
        address: addrResult.valueOrNull!,
        diagnoses: diagnoses,
        prRelationshipId: prRelId,
        familyMembers: [familyMemberRes.valueOrNull!],
      );
      
      if (patientResult.isFailure) {
        final error = (patientResult as Failure).error;
        fail('Patient creation failed: $error');
      }
      final patient = patientResult.valueOrNull!;

      // 2. Perform Registration
      print('Registering patient in Staging...');
      final regResult = await bff.registerPatient(patient);
      
      if (regResult.isFailure) {
        final error = (regResult as Failure).error;
        print('Registration failure: $error');
      }

      expect(regResult.isSuccess, isTrue);
      
      final newId = regResult.valueOrNull!;
      print('Registration successful. ID: ${newId.value}');

      // 3. Fetch the patient back
      print('Fetching patient back...');
      final getResult = await bff.getPatient(newId);
      
      if (getResult.isFailure) {
        final error = (getResult as Failure).error;
        print('Get patient failure: $error');
      }

      expect(getResult.isSuccess, isTrue, reason: 'Failed to fetch patient after registration');
      expect(getResult.valueOrNull!.id, newId);
      
      print('BFF Integration Success: Patient persisted and retrieved correctly.');
    });

    testWidgets('App starts and restores session using staging token', (tester) async {
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

class _RealTokenAuthRepository extends ChangeNotifier implements AuthRepository {
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
  AuthUser? get currentUser => _status is Authenticated ? (this._status as Authenticated).user : null;
  @override
  Future<Result<void>> login() async => const Success(null);
  @override
  Future<Result<void>> logout() async => const Success(null);
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
