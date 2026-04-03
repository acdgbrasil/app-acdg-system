import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/src/sync/sync_engine.dart';
import 'package:network/network.dart';
import 'package:persistence/persistence.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/foundation.dart';

class MockSyncQueue extends Mock implements SyncQueueService {}

class MockConnectivity extends Mock implements ConnectivityService {}

class MockRemoteBff extends Mock implements SocialCareContract {}

void main() {
  late SyncEngine engine;
  late MockSyncQueue queue;
  late MockConnectivity connectivity;
  late MockRemoteBff remote;
  late ValueNotifier<bool> onlineNotifier;

  final testPatientId = PatientId.create(
    '550e8400-e29b-41d4-a716-446655440000',
  ).valueOrNull!;

  setUpAll(() {
    registerFallbackValue(SyncAction(
      id: 0,
      actionId: '',
      patientId: '',
      actionType: '',
      payloadJson: '',
      timestamp: DateTime.now(),
      status: 'PENDING',
      retryCount: 0,
    ));
    registerFallbackValue(testPatientId);

    registerFallbackValue(
      HousingCondition.create(
        type: ConditionType.owned,
        wallMaterial: WallMaterial.masonry,
        numberOfRooms: 1,
        numberOfBedrooms: 1,
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
      ).valueOrNull!,
    );

    registerFallbackValue(
      EducationalStatus(
        familyId: testPatientId,
        memberProfiles: [],
        programOccurrences: [],
      ),
    );
  });

  setUp(() {
    queue = MockSyncQueue();
    connectivity = MockConnectivity();
    remote = MockRemoteBff();
    onlineNotifier = ValueNotifier<bool>(true);

    when(() => connectivity.isOnline).thenReturn(onlineNotifier);
    when(() => queue.getAllActions()).thenAnswer((_) async => []);

    engine = SyncEngine(
      queueService: queue,
      connectivityService: connectivity,
      remoteBff: remote,
    );
  });

  group('SyncEngine Tests', () {
    test('processQueue should process and remove successful actions', () async {
      final condition = HousingCondition.create(
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
      ).valueOrNull!;

      final action1 = SyncAction(
        id: 1,
        actionId: 'A1',
        patientId: testPatientId.value,
        actionType: 'UPDATE_HOUSING',
        payloadJson: jsonEncode(
          PatientTranslator.housingConditionToJson(condition),
        ),
        timestamp: DateTime.now(),
        status: 'PENDING',
        retryCount: 0,
      );

      when(() => queue.getPendingActions()).thenAnswer((_) async => [action1]);
      when(
        () => queue.updateStatus(any(), any(), error: any(named: 'error')),
      ).thenAnswer((_) async {});
      when(() => queue.removeAction(any())).thenAnswer((_) async {});
      when(
        () => remote.updateHousingCondition(any(), any()),
      ).thenAnswer((_) async => const Success(null));

      await engine.processQueue();

      verify(() => queue.updateStatus(1, 'IN_PROGRESS')).called(1);
      verify(
        () => remote.updateHousingCondition(testPatientId, condition),
      ).called(1);
      verify(() => queue.removeAction(1)).called(1);
    });

    test('processQueue should stop on network error', () async {
      final action1 = SyncAction(
        id: 1,
        actionId: 'A1',
        patientId: testPatientId.value,
        actionType: 'UPDATE_HOUSING',
        payloadJson: jsonEncode(
          PatientTranslator.housingConditionToJson(
            HousingCondition.create(
              type: ConditionType.owned,
              wallMaterial: WallMaterial.masonry,
              numberOfRooms: 1,
              numberOfBedrooms: 1,
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
            ).valueOrNull!,
          ),
        ),
        timestamp: DateTime.now(),
        status: 'PENDING',
        retryCount: 0,
      );
      final action2 = SyncAction(
        id: 2,
        actionId: 'A2',
        patientId: testPatientId.value,
        actionType: 'UPDATE_UNKNOWN',
        payloadJson: '{}',
        timestamp: DateTime.now(),
        status: 'PENDING',
        retryCount: 0,
      );

      when(
        () => queue.getPendingActions(),
      ).thenAnswer((_) async => [action1, action2]);
      when(
        () => queue.updateStatus(any(), any(), error: any(named: 'error')),
      ).thenAnswer((_) async {});
      when(() => queue.markFailed(any(), any())).thenAnswer((_) async {});
      when(() => remote.updateHousingCondition(any(), any())).thenAnswer(
        (_) async => const Failure('SocketException: Connection failed'),
      );

      await engine.processQueue();

      verify(() => queue.markFailed(1, any())).called(1);
      verifyNever(() => queue.updateStatus(2, 'IN_PROGRESS'));
    });

    test('processQueue should mark CONFLICT and continue on 409', () async {
      final action1 = SyncAction(
        id: 1,
        actionId: 'A1',
        patientId: testPatientId.value,
        actionType: 'UPDATE_HOUSING',
        payloadJson: jsonEncode(
          PatientTranslator.housingConditionToJson(
            HousingCondition.create(
              type: ConditionType.owned,
              wallMaterial: WallMaterial.masonry,
              numberOfRooms: 1,
              numberOfBedrooms: 1,
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
            ).valueOrNull!,
          ),
        ),
        timestamp: DateTime.now(),
        status: 'PENDING',
        retryCount: 0,
      );
      final action2 = SyncAction(
        id: 2,
        actionId: 'A2',
        patientId: testPatientId.value,
        actionType: 'UPDATE_EDUCATION',
        payloadJson: jsonEncode(
          PatientTranslator.educationalStatusToJson(
            EducationalStatus(
              familyId: testPatientId,
              memberProfiles: [],
              programOccurrences: [],
            ),
          ),
        ),
        timestamp: DateTime.now(),
        status: 'PENDING',
        retryCount: 0,
      );

      when(
        () => queue.getPendingActions(),
      ).thenAnswer((_) async => [action1, action2]);
      when(
        () => queue.updateStatus(any(), any(), error: any(named: 'error')),
      ).thenAnswer((_) async {});
      when(() => queue.markConflict(any(), any())).thenAnswer((_) async {});
      when(() => queue.removeAction(any())).thenAnswer((_) async {});

      when(
        () => remote.updateHousingCondition(any(), any()),
      ).thenAnswer((_) async => const Failure('HTTP 409 Conflict'));
      when(
        () => remote.updateEducationalStatus(any(), any()),
      ).thenAnswer((_) async => const Success(null));

      await engine.processQueue();

      verify(() => queue.markConflict(1, any())).called(1);
      verify(() => queue.updateStatus(2, 'IN_PROGRESS')).called(1);
      verify(() => queue.removeAction(2)).called(1);
    });
  });
}
