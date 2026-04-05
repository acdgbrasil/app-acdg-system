import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:core/core_offline.dart';
import 'package:shared/shared.dart';
import 'package:persistence/persistence.dart';
import 'package:social_care_desktop/src/storage/local_social_care_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/native.dart';

class MockSyncQueueService extends Mock implements SyncQueueService {}

void main() {
  late LocalSocialCareRepository repository;
  late AcdgDatabase db;
  late MockSyncQueueService mockQueue;
  late DriftDatabaseService dbService;

  // Helper para falhar o teste se o Result for erro
  T ensureSuccess<T>(Result<T> result) => switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw Exception('Test setup failed: $error'),
  };

  late final PatientId testPatientId;
  late final PersonId testPersonId;
  late final LookupId testPrRelationshipId;

  setUpAll(() async {
    testPatientId = ensureSuccess(
      PatientId.create('550e8400-e29b-41d4-a716-446655440000'),
    );
    testPersonId = ensureSuccess(
      PersonId.create('550e8400-e29b-41d4-a716-446655440001'),
    );
    testPrRelationshipId = ensureSuccess(
      LookupId.create('550e8400-e29b-41d4-a716-446655440002'),
    );
  });

  setUp(() async {
    db = AcdgDatabase(NativeDatabase.memory());
    dbService = DriftDatabaseService()..initWith(db);
    mockQueue = MockSyncQueueService();

    repository = LocalSocialCareRepository(
      dbService: dbService,
      queueService: mockQueue,
    );

    when(
      () => mockQueue.enqueue(
        patientId: any(named: 'patientId'),
        actionType: any(named: 'actionType'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() async {
    await db.close();
  });

  group('LocalSocialCareRepository Tests', () {
    test('registerPatient should save to Drift and enqueue action', () async {
      final personalData = ensureSuccess(
        PersonalData.create(
          firstName: 'João',
          lastName: 'Silva',
          motherName: 'Maria Silva',
          nationality: 'Brasileira',
          sex: Sex.masculino,
          birthDate: TimeStamp.now,
        ),
      );

      final patient = Patient.reconstitute(
        id: testPatientId,
        personId: testPersonId,
        prRelationshipId: testPrRelationshipId,
        version: 1,
        personalData: personalData,
      );

      final result = await repository.registerPatient(patient);

      expect(result.isSuccess, isTrue);

      final cached = await (db.select(db.cachedPatients)
            ..where((t) => t.patientId.equals(testPatientId.value)))
          .getSingleOrNull();
      
      expect(cached, isNotNull);
      expect(cached!.personId, testPersonId.value);
      expect(cached.isDirty, isTrue);

      verify(
        () => mockQueue.enqueue(
          patientId: testPatientId.value,
          actionType: 'REGISTER_PATIENT',
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test(
      'fetchPatient should retrieve from local cache using Pattern Matching',
      () async {
        final now = DateTime.now();
        final fullRecordJson = jsonEncode({
          'patientId': testPatientId.value,
          'personId': testPersonId.value,
          'version': 1,
          'prRelationshipId': testPrRelationshipId.value,
          'personalData': {
            'firstName': 'João',
            'lastName': 'Silva',
            'motherName': 'Maria',
            'nationality': 'BR',
            'sex': 'masculino',
            'birthDate': DateTime.now().toIso8601String(),
          },
        });

        await db.into(db.cachedPatients).insert(
          CachedPatientsCompanion.insert(
            patientId: testPatientId.value,
            personId: testPersonId.value,
            firstName: const Value('João'),
            lastName: const Value('Silva'),
            cpf: const Value('123'),
            fullRecordJson: fullRecordJson,
            version: const Value(1),
            isDirty: const Value(false),
            lastSyncAt: now,
          ),
        );

        final result = await repository.fetchPatient(testPatientId);

        final patientDto = switch (result) {
          Success(:final value) => value,
          Failure(:final error) => fail('Should be success, got: $error'),
        };
        expect(patientDto.patientId, testPatientId.value);
      },
    );

    test(
      'updateHousingCondition should update cache, increment version and enqueue',
      () async {
        final now = DateTime.now();
        await db.into(db.cachedPatients).insert(
          CachedPatientsCompanion.insert(
            patientId: testPatientId.value,
            personId: testPersonId.value,
            firstName: const Value('João'),
            lastName: const Value('Silva'),
            fullRecordJson: jsonEncode({
              'patientId': testPatientId.value,
              'personId': testPersonId.value,
              'version': 1,
              'prRelationshipId': testPrRelationshipId.value,
            }),
            version: const Value(1),
            isDirty: const Value(false),
            lastSyncAt: now,
          ),
        );

        final condition = ensureSuccess(
          HousingCondition.create(
            type: ConditionType.owned,
            wallMaterial: WallMaterial.masonry,
            numberOfRooms: 3,
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
          ),
        );

        final result = await repository.updateHousingCondition(
          testPatientId,
          condition,
        );

        expect(result.isSuccess, isTrue);

        final updated = await (db.select(db.cachedPatients)
              ..where((t) => t.patientId.equals(testPatientId.value)))
            .getSingleOrNull();
        
        expect(updated!.version, 2);
        expect(updated.isDirty, isTrue);

        verify(
          () => mockQueue.enqueue(
            patientId: testPatientId.value,
            actionType: 'UPDATE_HOUSING',
            payload: any(named: 'payload'),
          ),
        ).called(1);
      },
    );

    test('getLookupTable should return items from CachedLookup', () async {
      final itemsJson = jsonEncode([
        {
          'id': '550e8400-e29b-41d4-a716-446655440003',
          'codigo': 'P',
          'descricao': 'Pai',
        },
      ]);

      await db.into(db.cachedLookups).insert(
        CachedLookupsCompanion.insert(
          lookupName: 'dominio_parentesco',
          itemsJson: itemsJson,
          lastFetchedAt: DateTime.now(),
        ),
      );

      final result = await repository.getLookupTable('dominio_parentesco');

      final items = switch (result) {
        Success(:final value) => value,
        Failure(:final error) => fail('Should be success, got: $error'),
      };
      expect(items, hasLength(1));
      expect(items.first.descricao, 'Pai');
    });
  });
}
