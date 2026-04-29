import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Smoke tests for [InMemoryCareStore] (A06b Wave 0 — RED).
///
/// Shape expected (Wave 1 implementer will create):
/// ```
/// class InMemoryCareStore {
///   final Map<String, List<AppointmentResponse>> appointments = {};
///   final Map<String, IngressInfoResponse> intakes = {};
///
///   void addAppointment(String patientId, AppointmentResponse appointment);
///   void setIntake(String patientId, IngressInfoResponse intake);
///   List<AppointmentResponse> listAppointments(String patientId);
///   IngressInfoResponse? getIntake(String patientId);
///   void clear();
/// }
/// ```
void main() {
  group('InMemoryCareStore', () {
    AppointmentResponse buildAppointment(
      String id, {
      String date = '2026-04-16',
      String professionalId = 'prof-1',
      String type = 'intake',
      String summary = 'summary',
      String actionPlan = 'plan',
    }) => AppointmentResponse(
      id: id,
      date: date,
      professionalId: professionalId,
      type: type,
      summary: summary,
      actionPlan: actionPlan,
    );

    IngressInfoResponse buildIntake({
      String ingressTypeId = 'ingress-1',
      String serviceReason = 'reason',
    }) => IngressInfoResponse(
      ingressTypeId: ingressTypeId,
      serviceReason: serviceReason,
    );

    test('starts empty', () {
      final store = InMemoryCareStore();
      expect(store.appointments, isEmpty);
      expect(store.intakes, isEmpty);
    });

    test('addAppointment groups appointments by patientId', () {
      final store = InMemoryCareStore();
      store.addAppointment('pat-1', buildAppointment('a-1'));
      store.addAppointment('pat-1', buildAppointment('a-2'));
      store.addAppointment('pat-2', buildAppointment('a-3'));

      expect(store.listAppointments('pat-1'), hasLength(2));
      expect(store.listAppointments('pat-2'), hasLength(1));
    });

    test('listAppointments returns empty list for unknown patient', () {
      final store = InMemoryCareStore();
      expect(store.listAppointments('missing'), isEmpty);
    });

    test('setIntake then getIntake returns the intake', () {
      final store = InMemoryCareStore();
      final intake = buildIntake(ingressTypeId: 'new-ingress');

      store.setIntake('pat-1', intake);

      expect(store.getIntake('pat-1'), same(intake));
    });

    test('getIntake returns null for unknown patient', () {
      final store = InMemoryCareStore();
      expect(store.getIntake('missing'), isNull);
    });

    test('setIntake overwrites previous intake for same patient', () {
      final store = InMemoryCareStore();
      store.setIntake('pat-1', buildIntake(ingressTypeId: 'old'));
      store.setIntake('pat-1', buildIntake(ingressTypeId: 'new'));

      expect(store.getIntake('pat-1')?.ingressTypeId, equals('new'));
    });

    test('clear empties appointments and intakes', () {
      final store = InMemoryCareStore();
      store.addAppointment('pat-1', buildAppointment('a-1'));
      store.setIntake('pat-1', buildIntake());

      store.clear();

      expect(store.appointments, isEmpty);
      expect(store.intakes, isEmpty);
    });
  });
}
