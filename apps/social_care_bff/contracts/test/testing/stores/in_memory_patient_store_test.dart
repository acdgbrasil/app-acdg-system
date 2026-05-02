import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Smoke tests for [InMemoryPatientStore] (A06b Wave 0 — RED).
///
/// Shape expected (Wave 1 implementer will create):
/// ```
/// class InMemoryPatientStore {
///   final Map<String, PatientResponse> patients = {};
///   final Map<String, PatientSummaryResponse> summaries = {};
///
///   void save(PatientResponse patient, PatientSummaryResponse summary);
///   PatientResponse? get(String id);
///   List<PatientSummaryResponse> listSummaries();
///   void clear();
/// }
/// ```
///
/// Fields are intentionally public — the store has no invariant that
/// requires hiding state. Tests inspect `store.patients` directly.
void main() {
  group('InMemoryPatientStore', () {
    PatientResponse buildPatient(String id, {String personId = 'person-1'}) =>
        PatientResponse(patientId: id, personId: personId);

    PatientSummaryResponse buildSummary(
      String id, {
      String personId = 'person-1',
      String? fullName,
    }) => PatientSummaryResponse(
      patientId: id,
      personId: personId,
      fullName: fullName,
    );

    test('starts empty', () {
      final store = InMemoryPatientStore();
      expect(store.patients, isEmpty);
      expect(store.summaries, isEmpty);
    });

    test('save then get returns the stored patient', () {
      final store = InMemoryPatientStore();
      final patient = buildPatient('p-1');
      final summary = buildSummary('p-1');

      store.save(patient, summary);

      expect(store.get('p-1'), same(patient));
    });

    test('save populates listSummaries', () {
      final store = InMemoryPatientStore();
      store.save(buildPatient('p-1'), buildSummary('p-1', fullName: 'Alice'));
      store.save(buildPatient('p-2'), buildSummary('p-2', fullName: 'Bob'));

      final list = store.listSummaries();

      expect(list, hasLength(2));
      expect(list.map((s) => s.patientId), containsAll(<String>['p-1', 'p-2']));
    });

    test('get returns null for missing id', () {
      final store = InMemoryPatientStore();
      expect(store.get('missing'), isNull);
    });

    test('save overwrites existing patient with same id', () {
      final store = InMemoryPatientStore();
      store.save(
        buildPatient('p-1', personId: 'person-old'),
        buildSummary('p-1'),
      );
      store.save(
        buildPatient('p-1', personId: 'person-new'),
        buildSummary('p-1'),
      );

      expect(store.get('p-1')?.personId, equals('person-new'));
      expect(store.patients, hasLength(1));
    });

    test('clear empties both patients and summaries', () {
      final store = InMemoryPatientStore();
      store.save(buildPatient('p-1'), buildSummary('p-1'));
      store.save(buildPatient('p-2'), buildSummary('p-2'));

      store.clear();

      expect(store.patients, isEmpty);
      expect(store.summaries, isEmpty);
    });
  });
}
