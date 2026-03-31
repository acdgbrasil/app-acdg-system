import 'package:isar/isar.dart';

part 'cached_patient.g.dart';

@collection
class CachedPatient {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String patientId;

  @Index()
  late String personId;

  late String firstName;
  late String lastName;

  @Index()
  late String cpf;

  late String fullRecordJson;

  late int version;

  late bool isDirty;

  late DateTime lastSyncAt;
}
