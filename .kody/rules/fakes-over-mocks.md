---
title: "Use Fakes for testing, never magic mocks"
scope: "file"
path: ["**/test/**/*.dart", "**/testing/**/*.dart"]
severity_min: "medium"
languages: ["dart"]
buckets: ["style-conventions"]
enabled: true
---

## Instructions

Per ADR-013, this project uses hand-written Fakes in `testing/` directories, never magic mocking libraries (mockito, mocktail).

Flag:
- Import of `package:mockito` or `package:mocktail`
- Use of `@GenerateMocks`, `Mock`, `when()`, `verify()` from mocking libraries
- Inline anonymous mock implementations

Allowed:
- Fake classes in `testing/` directories
- Manual test doubles that implement abstract repository/service interfaces

## Examples

### Bad example
```dart
import 'package:mocktail/mocktail.dart';

class MockPatientRepository extends Mock implements PatientRepository {}

test('loads patients', () {
  when(() => mock.fetchAll()).thenAnswer((_) async => []);
});
```

### Good example
```dart
import 'package:social_care/testing/fake_patient_repository.dart';

test('loads patients', () {
  final repo = FakePatientRepository(patients: [testPatient]);
  final useCase = ListPatientsUseCase(repository: repo);
  // ...
});
```
