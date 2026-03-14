import 'package:test/test.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/social_care_desktop.dart';
import 'package:dio/dio.dart';

// Simple mock for Dio using noSuchMethod to avoid boilerplate
class MockDio implements Dio {
  Map<String, dynamic>? lastBody;
  
  @override
  BaseOptions options = BaseOptions();

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    lastBody = data as Map<String, dynamic>?;
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {'data': {'id': 'test-id'}} as T,
      statusCode: 201,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SocialCareBffRemote Regression Mapping Tests', () {
    late MockDio mockDio;
    late SocialCareBffRemote bff;
    final dummyPrRelId = LookupId.create('00000000-0000-0000-0000-000000000000').valueOrNull!;

    setUp(() {
      mockDio = MockDio();
      bff = SocialCareBffRemote(
        baseUrl: 'http://localhost',
        authToken: 'token',
        actorId: 'actor',
        dio: mockDio,
      );
    });

    test('REGP-013: Should map Sex to lowercase Portuguese strings', () async {
      final patientId = PatientId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!;
      final personId = PersonId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!;
      
      final p1 = Patient.reconstitute(
        id: patientId,
        version: 1,
        personId: personId,
        prRelationshipId: dummyPrRelId,
        personalData: PersonalData.create(
          firstName: 'A', lastName: 'B', motherName: 'C', nationality: 'D',
          sex: Sex.masculino,
          birthDate: TimeStamp.fromIso('1990-01-01T00:00:00.000Z').valueOrNull!,
        ).valueOrNull!,
      );

      await bff.registerPatient(p1);
      expect(mockDio.lastBody!['personalData']['sex'], equals('masculino'));

      final p2 = Patient.reconstitute(
        id: patientId,
        version: 1,
        personId: personId,
        prRelationshipId: dummyPrRelId,
        personalData: PersonalData.create(
          firstName: 'A', lastName: 'B', motherName: 'C', nationality: 'D',
          sex: Sex.feminino,
          birthDate: TimeStamp.fromIso('1990-01-01T00:00:00.000Z').valueOrNull!,
        ).valueOrNull!,
      );

      await bff.registerPatient(p2);
      expect(mockDio.lastBody!['personalData']['sex'], equals('feminino'));
    });

    test('Backend strict ISO8601: Should send full ISO string for all dates', () async {
      final patientId = PatientId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!;
      final personId = PersonId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!;
      
      final patient = Patient.reconstitute(
        id: patientId,
        version: 1,
        personId: personId,
        prRelationshipId: dummyPrRelId,
        personalData: PersonalData.create(
          firstName: 'A', lastName: 'B', motherName: 'C', nationality: 'D', sex: Sex.masculino,
          birthDate: TimeStamp.fromIso('1990-01-01T00:00:00.000Z').valueOrNull!,
        ).valueOrNull!,
      );

      await bff.registerPatient(patient);
      final birthDate = mockDio.lastBody!['personalData']['birthDate'];
      
      // Expected: 1990-01-01T00:00:00.000Z
      expect(birthDate, contains('T'));
      expect(birthDate, contains('.000Z'));
      expect(birthDate.length, greaterThan(10));
    });

    test('REGP-018 & ADR-005: Mapping mandatory fields (isShelter)', () async {
       final patientId = PatientId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!;
       final personId = PersonId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!;

       final patient = Patient.reconstitute(
        id: patientId,
        version: 1,
        personId: personId,
        prRelationshipId: dummyPrRelId,
        address: Address.create(
          state: 'SP',
          city: 'São Paulo',
          residenceLocation: ResidenceLocation.urbano,
          isShelter: true,
        ).valueOrNull!,
      );

      await bff.registerPatient(patient);
      expect(mockDio.lastBody!['address']['isShelter'], isTrue);
      expect(mockDio.lastBody!['address']['residenceLocation'], equals('URBANO'));
    });

    test('REGP-018: Should map civil documents correctly if present', () async {
       final patientId = PatientId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!;
       final personId = PersonId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!;

       final patient = Patient.reconstitute(
        id: patientId,
        version: 1,
        personId: personId,
        prRelationshipId: dummyPrRelId,
        civilDocuments: CivilDocuments.create(
          cpf: Cpf.create('12345678909').valueOrNull, // dummy valid-ish
        ).valueOrNull!,
      );

      await bff.registerPatient(patient);
      expect(mockDio.lastBody!['civilDocuments']['cpf'], isNotNull);
    });

    test('PAT-BUG-FIX: Should map prRelationshipId from model, not hardcoded', () async {
       final patientId = PatientId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!;
       final personId = PersonId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!;
       final prRelId = LookupId.create('550e8400-e29b-41d4-a716-446655440002').valueOrNull!;

       final patient = Patient.reconstitute(
        id: patientId,
        version: 1,
        personId: personId,
        prRelationshipId: prRelId,
      );

      await bff.registerPatient(patient);
      expect(mockDio.lastBody!['prRelationshipId'], equals('550e8400-e29b-41d4-a716-446655440002'));
    });

    test('REGP-024-FIX: Should map family members and requiredDocuments correctly', () async {
       final patientId = PatientId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!;
       final personId = PersonId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!;
       final relId = LookupId.create('00000000-0000-0000-0000-000000000000').valueOrNull!;

       final patient = Patient.reconstitute(
        id: patientId,
        version: 1,
        personId: personId,
        prRelationshipId: relId,
        familyMembers: [
          FamilyMember.create(
            personId: personId,
            relationshipId: relId,
            residesWithPatient: true,
            isPrimaryCaregiver: true,
            requiredDocuments: [RequiredDocument.cpf, RequiredDocument.rg],
            birthDate: TimeStamp.fromIso('1990-01-01T00:00:00.000Z').valueOrNull!,
          ).valueOrNull!,
        ],
      );

      await bff.registerPatient(patient);
      final member = (mockDio.lastBody!['familyMembers'] as List).first;
      expect(member['personId'], equals(personId.value));
      expect(member['isPrimaryCaregiver'], isTrue);
      expect(member['requiredDocuments'], containsAll(['CPF', 'RG']));
      expect(member['requiredDocuments'], isA<List<String>>());
    });
  });
}
