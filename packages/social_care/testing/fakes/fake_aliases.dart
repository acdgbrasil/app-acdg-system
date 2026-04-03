import 'in_memory_lookup_repository.dart';
import 'in_memory_patient_repository.dart';

/// Convenience alias so tests can refer to [FakePatientRepository].
typedef FakePatientRepository = InMemoryPatientRepository;

/// Convenience alias so tests can refer to [FakeLookupRepository].
typedef FakeLookupRepository = InMemoryLookupRepository;
