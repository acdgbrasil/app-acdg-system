/// RED-phase tests for `CareUseCases` builder (D02 W0.5).
///
/// `CareUseCases` groups the 3 Care use cases:
///   * `ListAppointmentsUseCase`     — read, `careCache` + `careRemote`
///   * `RegisterAppointmentUseCase`  — write, `careCache` + outbox + engine
///   * `UpdateIntakeInfoUseCase`     — write, `patientsCache` + outbox +
///                                     engine (intake info lives on the
///                                     Patient aggregate, A18b-v2)
///
/// So Care's `build()` needs BOTH `careCache` and `patientsCache` —
/// asymmetric with Registry/Assessment. That asymmetry is the point of
/// extracting the builder: it documents the dep set per bounded context.
///
/// ── Surface under test ───────────────────────────────────────────────
///   * `class CareUseCases`
///       - 3 final fields: `listAppointments`, `registerAppointment`,
///         `updateIntakeInfo`
///       - `static CareUseCases build({...})` factory
///
/// IMPORTANT (RED phase): builder file does not exist yet. Intended RED signal.
library;

// ignore_for_file: unnecessary_type_check

import 'package:test/test.dart';

import 'package:social_care_desktop/src/use_cases/care/list_appointments_use_case.dart';
import 'package:social_care_desktop/src/use_cases/care/register_appointment_use_case.dart';
import 'package:social_care_desktop/src/use_cases/care/update_intake_info_use_case.dart';

// ── Builder under test (RED — file does not exist yet) ───────────────
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/facade/composition/builders/care_use_cases.dart';

import '_builders_test_helpers.dart';

void main() {
  group('CareUseCases', () {
    late BuilderDeps deps;

    setUp(() {
      deps = BuilderDeps.fresh();
      addTearDown(deps.close);
    });

    test(
      'build() returns instance with all 3 fields populated and non-null',
      () {
        final useCases = CareUseCases.build(
          careCache: deps.careCache,
          patientsCache: deps.patientsCache,
          remote: deps.careRemote,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );

        expect(useCases, isNotNull);
        expect(useCases.listAppointments, isNotNull);
        expect(useCases.registerAppointment, isNotNull);
        expect(useCases.updateIntakeInfo, isNotNull);
      },
    );

    test('each field is the expected concrete UseCase type', () {
      final useCases = CareUseCases.build(
        careCache: deps.careCache,
        patientsCache: deps.patientsCache,
        remote: deps.careRemote,
        outbox: deps.outbox,
        engine: deps.engine,
        clock: deps.clock,
        staleAfter: deps.staleAfter,
      );

      expect(useCases.listAppointments, isA<ListAppointmentsUseCase>());
      expect(useCases.registerAppointment, isA<RegisterAppointmentUseCase>());
      expect(useCases.updateIntakeInfo, isA<UpdateIntakeInfoUseCase>());
    });

    test(
      'build() called twice with same deps produces independent instances of correct type',
      () {
        final a = CareUseCases.build(
          careCache: deps.careCache,
          patientsCache: deps.patientsCache,
          remote: deps.careRemote,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );
        final b = CareUseCases.build(
          careCache: deps.careCache,
          patientsCache: deps.patientsCache,
          remote: deps.careRemote,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );

        expect(identical(a, b), isFalse);
        expect(identical(a.listAppointments, b.listAppointments), isFalse);
        expect(
          identical(a.registerAppointment, b.registerAppointment),
          isFalse,
        );
        expect(identical(a.updateIntakeInfo, b.updateIntakeInfo), isFalse);

        expect(
          a.listAppointments.runtimeType,
          equals(b.listAppointments.runtimeType),
        );
        expect(
          a.registerAppointment.runtimeType,
          equals(b.registerAppointment.runtimeType),
        );
        expect(
          a.updateIntakeInfo.runtimeType,
          equals(b.updateIntakeInfo.runtimeType),
        );
      },
    );
  });
}
