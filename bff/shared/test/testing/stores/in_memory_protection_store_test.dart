import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Smoke tests for [InMemoryProtectionStore] (A06b Wave 0 — RED).
///
/// Shape expected (Wave 1 implementer will create):
/// ```
/// class InMemoryProtectionStore {
///   final List<ViolationReportResponse> violations = [];
///   final List<ReferralResponse> referrals = [];
///   final Map<String, PlacementHistoryResponse> placementByPatient = {};
///
///   void reportViolation(ViolationReportResponse violation);
///   void createReferral(ReferralResponse referral);
///   void setPlacement(String patientId, PlacementHistoryResponse placement);
///   List<ViolationReportResponse> listViolations();
///   void clear();
/// }
/// ```
void main() {
  group('InMemoryProtectionStore', () {
    ViolationReportResponse buildViolation(
      String id, {
      String victimId = 'victim-1',
      String violationType = 'neglect',
    }) => ViolationReportResponse(
      id: id,
      reportDate: '2026-04-16',
      victimId: victimId,
      violationType: violationType,
      descriptionOfFact: 'description',
      actionsTaken: 'actions',
    );

    ReferralResponse buildReferral(
      String id, {
      String referredPersonId = 'person-1',
      String destinationService = 'dest',
      String status = 'pending',
    }) => ReferralResponse(
      id: id,
      date: '2026-04-16',
      referredPersonId: referredPersonId,
      destinationService: destinationService,
      reason: 'reason',
      status: status,
    );

    PlacementHistoryResponse buildPlacement({bool adultInPrison = false}) =>
        PlacementHistoryResponse(adultInPrison: adultInPrison);

    test('starts empty', () {
      final store = InMemoryProtectionStore();
      expect(store.violations, isEmpty);
      expect(store.referrals, isEmpty);
      expect(store.placementByPatient, isEmpty);
    });

    test('reportViolation appends to violations list', () {
      final store = InMemoryProtectionStore();
      store.reportViolation(buildViolation('v-1'));
      store.reportViolation(buildViolation('v-2'));

      expect(store.violations, hasLength(2));
      expect(
        store.violations.map((v) => v.id),
        containsAll(<String>['v-1', 'v-2']),
      );
    });

    test('listViolations reflects reported items', () {
      final store = InMemoryProtectionStore();
      store.reportViolation(buildViolation('v-1'));

      final list = store.listViolations();

      expect(list, hasLength(1));
      expect(list.first.id, equals('v-1'));
    });

    test('createReferral appends to referrals list', () {
      final store = InMemoryProtectionStore();
      store.createReferral(buildReferral('r-1'));
      store.createReferral(buildReferral('r-2'));

      expect(store.referrals, hasLength(2));
      expect(
        store.referrals.map((r) => r.id),
        containsAll(<String>['r-1', 'r-2']),
      );
    });

    test('setPlacement stores placement per patient', () {
      final store = InMemoryProtectionStore();
      store.setPlacement('pat-1', buildPlacement(adultInPrison: true));
      store.setPlacement('pat-2', buildPlacement(adultInPrison: false));

      expect(store.placementByPatient, hasLength(2));
      expect(store.placementByPatient['pat-1']?.adultInPrison, isTrue);
      expect(store.placementByPatient['pat-2']?.adultInPrison, isFalse);
    });

    test('setPlacement overwrites placement for same patient', () {
      final store = InMemoryProtectionStore();
      store.setPlacement('pat-1', buildPlacement(adultInPrison: false));
      store.setPlacement('pat-1', buildPlacement(adultInPrison: true));

      expect(store.placementByPatient, hasLength(1));
      expect(store.placementByPatient['pat-1']?.adultInPrison, isTrue);
    });

    test('clear empties violations, referrals and placements', () {
      final store = InMemoryProtectionStore();
      store.reportViolation(buildViolation('v-1'));
      store.createReferral(buildReferral('r-1'));
      store.setPlacement('pat-1', buildPlacement());

      store.clear();

      expect(store.violations, isEmpty);
      expect(store.referrals, isEmpty);
      expect(store.placementByPatient, isEmpty);
    });
  });
}
