import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/care_cache.dart';
import '../_shared/clock.dart';

// `Clock` is accepted by the constructor for forward compat with stale
// policy when CareContract gains a list endpoint. See REGRA #2 #4 in
// the ticket STATE.

/// Pattern 1 — cache-only read (CareContract has no list endpoint).
///
/// REGRA #2 follow-up: if backend exposes `GET /care/patients/{id}/
/// appointments`, this becomes a cache-first/remote-fallback shape;
/// for now we serve whatever the cache holds and return an empty list
/// on miss. See `protection/list_referrals_use_case.dart` for the same
/// pattern.
class ListAppointmentsUseCase {
  ListAppointmentsUseCase({
    required CareCache cache,
    required CareContract remote,
    required Clock clock,
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache;

  final CareCache _cache;

  Future<Result<List<AppointmentResponse>>> call(
    String patientId, {
    int? limit,
  }) async {
    final cachedResult = await _cache.listByPatient(patientId, limit: limit);
    switch (cachedResult) {
      case Success(:final value):
        return Success<List<AppointmentResponse>>(value);
      case Failure(:final error, :final stackTrace):
        return Failure<List<AppointmentResponse>>(
          error,
          stackTrace: stackTrace,
        );
    }
  }
}
