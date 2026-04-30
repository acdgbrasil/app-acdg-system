import 'package:drift/drift.dart';

import '../_shared/cache_database.dart';
import '../_shared/tables/care_table.dart';
import '../_shared/tables/care_table.drift.dart';
import 'care_dao.drift.dart';

@DriftAccessor(tables: [Appointments])
class CareDao extends DatabaseAccessor<CacheDatabase> with $CareDaoMixin {
  CareDao(super.db);

  Future<Appointment?> findById(String patientId, String appointmentId) {
    return (select(appointments)..where(
          (a) => a.patientId.equals(patientId) & a.id.equals(appointmentId),
        ))
        .getSingleOrNull();
  }

  Future<List<Appointment>> listByPatient(String patientId, {int? limit}) {
    final q = select(appointments)..where((a) => a.patientId.equals(patientId));
    if (limit != null) {
      q.limit(limit);
    }
    return q.get();
  }

  Future<void> upsert({
    required String patientId,
    required String id,
    required String payload,
    required DateTime cachedAt,
    required int version,
  }) {
    return into(appointments).insert(
      AppointmentsCompanion.insert(
        patientId: patientId,
        id: id,
        payload: payload,
        cachedAt: cachedAt,
        version: version,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteById(String patientId, String appointmentId) async {
    await (delete(appointments)..where(
          (a) => a.patientId.equals(patientId) & a.id.equals(appointmentId),
        ))
        .go();
  }

  Future<void> clearAll() => delete(appointments).go();
}
