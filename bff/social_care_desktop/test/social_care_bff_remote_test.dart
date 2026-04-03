import 'package:test/test.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/social_care_desktop.dart';
import 'package:dio/dio.dart';

// Simple mock for Dio using noSuchMethod to avoid boilerplate
class MockDio implements Dio {
  Map<String, dynamic>? lastBody;
  String? lastPath;
  Map<String, dynamic>? lastResponseData;

  @override
  BaseOptions options = BaseOptions();

  @override
  Interceptors get interceptors => Interceptors();

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
    lastPath = path;
    lastBody = data as Map<String, dynamic>?;
    return Response(
      requestOptions: RequestOptions(path: path),
      data:
          (lastResponseData ??
                  {
                    'data': {'id': 'test-id'},
                  })
              as T,
      statusCode: 201,
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 204,
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    lastPath = path;
    lastBody = data as Map<String, dynamic>?;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 204,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    lastPath = path;
    if (lastResponseData != null) {
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: lastResponseData as T,
      );
    }
    if (path.contains('audit-trail')) {
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data:
            {
                  'data': [
                    {
                      'id': 'audit-1',
                      'aggregateId': 'patient-1',
                      'eventType': 'PatientCreated',
                      'payload': <String, dynamic>{},
                      'occurredAt': '2023-01-01T10:00:00.000Z',
                      'recordedAt': '2023-01-01T10:00:01.000Z',
                    },
                  ],
                  'meta': {'timestamp': '2023-01-01T10:00:02.000Z'},
                }
                as T,
      );
    }
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'data': {}} as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SocialCareBffRemote Regression Mapping Tests', () {
    late MockDio mockDio;
    late SocialCareBffRemote bff;
    final dummyPrRelId = LookupId.create(
      '00000000-0000-0000-0000-000000000000',
    ).valueOrNull!;

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
      final patientId = PatientId.create(
        '550e8400-e29b-41d4-a716-446655440000',
      ).valueOrNull!;
      final personId = PersonId.create(
        '550e8400-e29b-41d4-a716-446655440001',
      ).valueOrNull!;

      final p1 = Patient.reconstitute(
        id: patientId,
        version: 1,
        personId: personId,
        prRelationshipId: dummyPrRelId,
        personalData: PersonalData.create(
          firstName: 'A',
          lastName: 'B',
          motherName: 'C',
          nationality: 'D',
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
          firstName: 'A',
          lastName: 'B',
          motherName: 'C',
          nationality: 'D',
          sex: Sex.feminino,
          birthDate: TimeStamp.fromIso('1990-01-01T00:00:00.000Z').valueOrNull!,
        ).valueOrNull!,
      );

      await bff.registerPatient(p2);
      expect(mockDio.lastBody!['personalData']['sex'], equals('feminino'));
    });

    test(
      'Backend strict ISO8601: Should send full ISO string for all dates',
      () async {
        final patientId = PatientId.create(
          '550e8400-e29b-41d4-a716-446655440000',
        ).valueOrNull!;
        final personId = PersonId.create(
          '550e8400-e29b-41d4-a716-446655440001',
        ).valueOrNull!;

        final patient = Patient.reconstitute(
          id: patientId,
          version: 1,
          personId: personId,
          prRelationshipId: dummyPrRelId,
          personalData: PersonalData.create(
            firstName: 'A',
            lastName: 'B',
            motherName: 'C',
            nationality: 'D',
            sex: Sex.masculino,
            birthDate: TimeStamp.fromIso(
              '1990-01-01T00:00:00.000Z',
            ).valueOrNull!,
          ).valueOrNull!,
        );

        await bff.registerPatient(patient);
        final birthDate = mockDio.lastBody!['personalData']['birthDate'];

        expect(birthDate, contains('T'));
        expect(birthDate, contains('.000Z'));
        expect(birthDate.length, greaterThan(10));
      },
    );

    test('REGP-018 & ADR-005: Mapping mandatory fields (isShelter)', () async {
      final patientId = PatientId.create(
        '550e8400-e29b-41d4-a716-446655440000',
      ).valueOrNull!;
      final personId = PersonId.create(
        '550e8400-e29b-41d4-a716-446655440001',
      ).valueOrNull!;

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
      expect(
        mockDio.lastBody!['address']['residenceLocation'],
        equals('URBANO'),
      );
    });

    test(
      'PAT-BUG-FIX: Should map prRelationshipId from model, not hardcoded',
      () async {
        final patientId = PatientId.create(
          '550e8400-e29b-41d4-a716-446655440000',
        ).valueOrNull!;
        final personId = PersonId.create(
          '550e8400-e29b-41d4-a716-446655440001',
        ).valueOrNull!;
        final prRelId = LookupId.create(
          '550e8400-e29b-41d4-a716-446655440002',
        ).valueOrNull!;

        final patient = Patient.reconstitute(
          id: patientId,
          version: 1,
          personId: personId,
          prRelationshipId: prRelId,
        );

        await bff.registerPatient(patient);
        expect(
          mockDio.lastBody!['prRelationshipId'],
          equals('550e8400-e29b-41d4-a716-446655440002'),
        );
      },
    );

    test(
      'REGP-024-FIX: Should map family members and requiredDocuments correctly',
      () async {
        final patientId = PatientId.create(
          '550e8400-e29b-41d4-a716-446655440000',
        ).valueOrNull!;
        final personId = PersonId.create(
          '550e8400-e29b-41d4-a716-446655440001',
        ).valueOrNull!;
        final relId = LookupId.create(
          '00000000-0000-0000-0000-000000000000',
        ).valueOrNull!;

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
              birthDate: TimeStamp.fromIso(
                '1990-01-01T00:00:00.000Z',
              ).valueOrNull!,
            ).valueOrNull!,
          ],
        );

        await bff.registerPatient(patient);
        final member = (mockDio.lastBody!['familyMembers'] as List).first;
        expect(member['personId'], equals(personId.value));
        expect(member['isPrimaryCaregiver'], isTrue);
        expect(member['requiredDocuments'], containsAll(['CPF', 'RG']));
      },
    );

    test('Should map updateHousingCondition request correctly', () async {
      final patientId = PatientId.create(
        '550e8400-e29b-41d4-a716-446655440000',
      ).valueOrNull!;
      final condition = HousingCondition.create(
        type: ConditionType.owned,
        wallMaterial: WallMaterial.masonry,
        numberOfRooms: 4,
        numberOfBedrooms: 2,
        numberOfBathrooms: 1,
        waterSupply: WaterSupply.publicNetwork,
        hasPipedWater: true,
        electricityAccess: ElectricityAccess.meteredConnection,
        sewageDisposal: SewageDisposal.publicSewer,
        wasteCollection: WasteCollection.directCollection,
        accessibilityLevel: AccessibilityLevel.fullyAccessible,
        isInGeographicRiskArea: false,
        hasDifficultAccess: false,
        isInSocialConflictArea: false,
        hasDiagnosticObservations: false,
      ).valueOrNull!;

      await bff.updateHousingCondition(patientId, condition);

      expect(
        mockDio.lastPath,
        equals('/api/v1/patients/${patientId.value}/housing-condition'),
      );
      expect(mockDio.lastBody!['type'], equals('OWNED'));
      expect(mockDio.lastBody!['wallMaterial'], equals('MASONRY'));
    });

    test('Should map updateSocioEconomicSituation request correctly', () async {
      final patientId = PatientId.create(
        '550e8400-e29b-41d4-a716-446655440000',
      ).valueOrNull!;
      final memberId = PersonId.create(
        '550e8400-e29b-41d4-a716-446655440001',
      ).valueOrNull!;
      final benefit = SocialBenefit.create(
        benefitName: 'BPC',
        benefitTypeId: LookupId.create('550e8400-e29b-41d4-a716-446655440002').valueOrNull!,
        amount: 1412.0,
        beneficiaryId: memberId,
      ).valueOrNull!;
      final situation = SocioEconomicSituation.create(
        totalFamilyIncome: 2500.0,
        incomePerCapita: 625.0,
        receivesSocialBenefit: true,
        socialBenefits: SocialBenefitsCollection.create([benefit]).valueOrNull!,
        mainSourceOfIncome: 'Work',
        hasUnemployed: false,
      ).valueOrNull!;

      await bff.updateSocioEconomicSituation(patientId, situation);

      expect(
        mockDio.lastPath,
        equals('/api/v1/patients/${patientId.value}/socioeconomic-situation'),
      );
      expect(mockDio.lastBody!['totalFamilyIncome'], equals(2500.0));
    });

    test('Should map updateWorkAndIncome request correctly', () async {
      final patientId = PatientId.create(
        '550e8400-e29b-41d4-a716-446655440000',
      ).valueOrNull!;
      final memberId = PersonId.create(
        '550e8400-e29b-41d4-a716-446655440001',
      ).valueOrNull!;
      final occId = LookupId.create(
        '550e8400-e29b-41d4-a716-446655440002',
      ).valueOrNull!;

      final data = WorkAndIncome(
        familyId: patientId,
        individualIncomes: [
          WorkIncomeVO.create(
            memberId: memberId,
            occupationId: occId,
            hasWorkCard: true,
            monthlyAmount: 1200.0,
          ).valueOrNull!,
        ],
        socialBenefits: [],
        hasRetiredMembers: false,
      );

      await bff.updateWorkAndIncome(patientId, data);

      expect(
        mockDio.lastPath,
        equals('/api/v1/patients/${patientId.value}/work-and-income'),
      );
      expect(
        mockDio.lastBody!['individualIncomes'][0]['memberId'],
        equals(memberId.value),
      );
    });

    test('Should map registerAppointment request correctly', () async {
      final patientId = PatientId.create(
        '550e8400-e29b-41d4-a716-446655440000',
      ).valueOrNull!;
      final profId = ProfessionalId.create(
        '550e8400-e29b-41d4-a716-446655440001',
      ).valueOrNull!;

      final appointment = SocialCareAppointment.create(
        id: AppointmentId.create(
          '550e8400-e29b-41d4-a716-446655440002',
        ).valueOrNull!,
        date: TimeStamp.now,
        professionalInChargeId: profId,
        type: AppointmentType.homeVisit,
        summary: 'Test',
        actionPlan: 'Plan',
      ).valueOrNull!;

      await bff.registerAppointment(patientId, appointment);

      expect(
        mockDio.lastPath,
        equals('/api/v1/patients/${patientId.value}/appointments'),
      );
      expect(mockDio.lastBody!['type'], equals('HOME_VISIT'));
    });

    test(
      'Regression: Should parse a rich patient JSON with basic fields',
      () async {
        final patientId = PatientId.create(
          '550e8400-e29b-41d4-a716-446655440000',
        ).valueOrNull!;

        mockDio.lastResponseData = {
          'data': {
            'patientId': patientId.value,
            'version': 1,
            'personId': '550e8400-e29b-41d4-a716-446655440001',
            'prRelationshipId': '550e8400-e29b-41d4-a716-446655440002',
            'familyMembers': [],
          },
        };

        final result = await bff.fetchPatient(patientId);

        expect(result.isSuccess, isTrue);
        final patient = result.valueOrNull!;
        expect(patient.patientId, equals(patientId.value));
      },
    );

    test('Should map getAuditTrail response correctly', () async {
      final patientId = PatientId.create(
        '550e8400-e29b-41d4-a716-446655440000',
      ).valueOrNull!;
      mockDio.lastResponseData = null; // Use default mock audit trail

      final result = await bff.getAuditTrail(patientId);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.first.eventType, equals('PatientCreated'));
    });
  });
}
