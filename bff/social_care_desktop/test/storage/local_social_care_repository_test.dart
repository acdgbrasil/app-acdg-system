import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:persistence/persistence.dart';
import 'package:social_care_desktop/src/storage/local_social_care_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncQueueService extends Mock implements SyncQueueService {}

class TestIsarService extends Mock implements IsarService {
  final Isar _isar;
  TestIsarService(this._isar);
  @override
  Isar get db => _isar;
}

void main() {
  late LocalSocialCareRepository repository;
  late Isar isar;
  late MockSyncQueueService mockQueue;
  late TestIsarService testIsarService;

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

    final dir = await Directory.systemTemp.createTemp('isar_test');
    try {
      await Isar.initializeIsarCore(download: true);
    } catch (_) {}

    isar = await Isar.open(
      IsarSchemas.all,
      directory: dir.path,
      inspector: false,
    );
  });

  tearDownAll(() async {
    await isar.close();
  });

  setUp(() async {
    mockQueue = MockSyncQueueService();
    testIsarService = TestIsarService(isar);
    await isar.writeTxn(() => isar.clear());

    repository = LocalSocialCareRepository(
      isarService: testIsarService,
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

  group('LocalSocialCareRepository Tests', () {
    test('registerPatient should save to Isar and enqueue action', () async {
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

      final cached = await isar.cachedPatients
          .filter()
          .patientIdEqualTo(testPatientId.value)
          .findFirst();
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
      'getPatient should retrieve from local cache using Pattern Matching',
      () async {
        final now = DateTime.now();
        final cached = CachedPatient()
          ..patientId = testPatientId.value
          ..personId = testPersonId.value
          ..firstName = 'João'
          ..lastName = 'Silva'
          ..cpf = '123'
          ..version = 1
          ..isDirty = false
          ..lastSyncAt = now
          ..fullRecordJson = jsonEncode({
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

        await isar.writeTxn(() => isar.cachedPatients.put(cached));

        final result = await repository.getPatient(testPatientId);

        final patient = switch (result) {
          Success(:final value) => value,
          Failure(:final error) => fail('Should be success, got: $error'),
        };
        expect(patient.id, testPatientId);
      },
    );

    test(
      'updateHousingCondition should update cache, increment version and enqueue',
      () async {
        final cached = CachedPatient()
          ..patientId = testPatientId.value
          ..personId = testPersonId.value
          ..firstName = 'João'
          ..lastName = 'Silva'
          ..cpf = '123'
          ..version = 1
          ..isDirty = false
          ..lastSyncAt = DateTime.now()
          ..fullRecordJson = jsonEncode({
            'patientId': testPatientId.value,
            'personId': testPersonId.value,
            'version': 1,
            'prRelationshipId': testPrRelationshipId.value,
          });

        await isar.writeTxn(() => isar.cachedPatients.put(cached));

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

        final updated = await isar.cachedPatients
            .filter()
            .patientIdEqualTo(testPatientId.value)
            .findFirst();
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
      final lookup = CachedLookup()
        ..tableName = 'dominio_parentesco'
        ..itemsJson = jsonEncode([
          {
            'id': '550e8400-e29b-41d4-a716-446655440003',
            'codigo': 'P',
            'descricao': 'Pai',
          },
        ])
        ..lastFetchedAt = DateTime.now();

      await isar.writeTxn(() => isar.cachedLookups.put(lookup));

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
