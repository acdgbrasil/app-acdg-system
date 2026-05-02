/// Bundles the 3 Care use cases (A18b-v2) — asymmetric build set:
///   * `ListAppointmentsUseCase`     — read, `careCache` + `careRemote`
///   * `RegisterAppointmentUseCase`  — write, `careCache` + outbox + engine
///   * `UpdateIntakeInfoUseCase`     — write, `patientsCache` + outbox +
///                                     engine (intake info lives on the
///                                     Patient aggregate, A18b-v2)
///
/// Care's [build] needs BOTH `careCache` and `patientsCache` — the
/// asymmetry is the point: the builder documents the dep set per
/// bounded context.
library;

import 'package:shared/shared.dart';

import '../../../cache/contracts/care_cache.dart';
import '../../../cache/contracts/patients_cache.dart';
import '../../../sync/engine/sync_engine.dart';
import '../../../sync/outbox/outbox_repository.dart';
import '../../../use_cases/_shared/clock.dart';
import '../../../use_cases/care/list_appointments_use_case.dart';
import '../../../use_cases/care/register_appointment_use_case.dart';
import '../../../use_cases/care/update_intake_info_use_case.dart';

/// Data class grouping the 3 Care use cases.
class CareUseCases {
  CareUseCases({
    required this.listAppointments,
    required this.registerAppointment,
    required this.updateIntakeInfo,
  });

  final ListAppointmentsUseCase listAppointments;
  final RegisterAppointmentUseCase registerAppointment;
  final UpdateIntakeInfoUseCase updateIntakeInfo;

  /// Constructs all 3 Care use cases from shared dependencies.
  static CareUseCases build({
    required CareCache careCache,
    required PatientsCache patientsCache,
    required CareContract remote,
    required OutboxRepository outbox,
    required SyncEngine engine,
    required Clock clock,
    required Duration staleAfter,
  }) {
    return CareUseCases(
      listAppointments: ListAppointmentsUseCase(
        cache: careCache,
        remote: remote,
        clock: clock,
        staleAfter: staleAfter,
      ),
      registerAppointment: RegisterAppointmentUseCase(
        careCache: careCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      updateIntakeInfo: UpdateIntakeInfoUseCase(
        patientsCache: patientsCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
    );
  }
}
