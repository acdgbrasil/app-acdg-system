import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/src/storage/local_social_care_repository.dart';
import 'package:social_care_desktop/src/remote/social_care_bff_remote.dart';
import 'package:social_care_desktop/src/storage/offline_first_repository.dart';
import 'package:social_care_desktop/src/sync/sync_engine.dart';
import 'package:network/network.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/foundation.dart';

class MockLocalRepo extends Mock implements LocalSocialCareRepository {}
class MockRemoteRepo extends Mock implements SocialCareBffRemote {}
class MockConnectivity extends Mock implements ConnectivityService {}
class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late OfflineFirstRepository repository;
  late MockLocalRepo local;
  late MockRemoteRepo remote;
  late MockConnectivity connectivity;
  late MockSyncEngine syncEngine;
  late ValueNotifier<bool> onlineNotifier;

  setUpAll(() {
    registerFallbackValue(Patient.reconstitute(
      id: PatientId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!,
      personId: PersonId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!,
      prRelationshipId: LookupId.create('550e8400-e29b-41d4-a716-446655440002').valueOrNull!,
      version: 1,
    ));
  });

  setUp(() {
    local = MockLocalRepo();
    remote = MockRemoteRepo();
    connectivity = MockConnectivity();
    syncEngine = MockSyncEngine();
    onlineNotifier = ValueNotifier<bool>(true);

    when(() => connectivity.isOnline).thenReturn(onlineNotifier);
    when(() => syncEngine.processQueue()).thenAnswer((_) async {});

    repository = OfflineFirstRepository(
      local: local,
      remote: remote,
      connectivity: connectivity,
      syncEngine: syncEngine,
    );
  });

  group('OfflineFirstRepository - Write Operations', () {
    test('registerPatient should trigger sync if online', () async {
      final patient = Patient.reconstitute(
        id: PatientId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!,
        personId: PersonId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!,
        prRelationshipId: LookupId.create('550e8400-e29b-41d4-a716-446655440002').valueOrNull!,
        version: 1,
      );

      when(() => local.registerPatient(any())).thenAnswer((_) async => Success(patient.id));

      final result = await repository.registerPatient(patient);

      expect(result.isSuccess, isTrue);
      verify(() => local.registerPatient(patient)).called(1);
      verify(() => syncEngine.processQueue()).called(1);
    });

    test('registerPatient should NOT trigger sync if offline', () async {
      onlineNotifier.value = false;
      final patient = Patient.reconstitute(
        id: PatientId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!,
        personId: PersonId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!,
        prRelationshipId: LookupId.create('550e8400-e29b-41d4-a716-446655440002').valueOrNull!,
        version: 1,
      );

      when(() => local.registerPatient(any())).thenAnswer((_) async => Success(patient.id));

      final result = await repository.registerPatient(patient);

      expect(result.isSuccess, isTrue);
      verify(() => local.registerPatient(patient)).called(1);
      verifyNever(() => syncEngine.processQueue());
    });
  });

  group('OfflineFirstRepository - Read Operations', () {
    final patientId = PatientId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!;
    final patient = Patient.reconstitute(
      id: patientId,
      personId: PersonId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!,
      prRelationshipId: LookupId.create('550e8400-e29b-41d4-a716-446655440002').valueOrNull!,
      version: 1,
    );

    test('getPatient should try remote and update cache if online', () async {
      onlineNotifier.value = true;
      when(() => remote.getPatient(patientId)).thenAnswer((_) async => Success(patient));
      when(() => local.updateCache(any())).thenAnswer((_) async {});

      final result = await repository.getPatient(patientId);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, patient);
      verify(() => remote.getPatient(patientId)).called(1);
    });

    test('getPatient should fallback to local if remote fails and online', () async {
      onlineNotifier.value = true;
      when(() => remote.getPatient(patientId)).thenAnswer((_) async => const Failure('Network error'));
      when(() => local.getPatient(patientId)).thenAnswer((_) async => Success(patient));

      final result = await repository.getPatient(patientId);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, patient);
      verify(() => remote.getPatient(patientId)).called(1);
      verify(() => local.getPatient(patientId)).called(1);
    });

    test('getPatient should go straight to local if offline', () async {
      onlineNotifier.value = false;
      when(() => local.getPatient(patientId)).thenAnswer((_) async => Success(patient));

      final result = await repository.getPatient(patientId);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, patient);
      verifyNever(() => remote.getPatient(patientId));
      verify(() => local.getPatient(patientId)).called(1);
    });
  });
}
